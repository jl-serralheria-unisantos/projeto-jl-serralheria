import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/cliente_model.dart';
import '../../../data/models/orcamento_model.dart';
import '../../../shared/formatters.dart';

class PdfOrcamentoException extends StateError {
  PdfOrcamentoException(super.message);
}

class PdfService {
  const PdfService();

  Future<Uint8List> gerarOrcamento({
    required Orcamento orcamento,
    required Cliente? cliente,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    if (orcamento.totalRegistradoCentavos == null ||
        (orcamento.itens.isNotEmpty && orcamento.requerRevisao)) {
      throw PdfOrcamentoException(
        'Os valores históricos precisam de revisão. Confira e salve o orçamento antes de gerar o PDF.',
      );
    }
    final fontes = await _fontes;
    final document = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.ttf(fontes.$1),
        bold: pw.Font.ttf(fontes.$2),
      ),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9),
          ),
        ),
        build: (context) => [
          _cabecalho(orcamento),
          pw.SizedBox(height: 20),
          ..._dadosCliente(cliente),
          pw.SizedBox(height: 18),
          ..._itens(orcamento),
          pw.SizedBox(height: 16),
          _totais(orcamento),
          pw.SizedBox(height: 18),
          ..._detalhesFinais(orcamento),
        ],
      ),
    );

    return document.save();
  }

  Future<void> visualizarOrcamento({
    required Orcamento orcamento,
    required Cliente? cliente,
  }) async {
    await Printing.layoutPdf(
      name: _nomeArquivo(orcamento),
      onLayout: (format) => gerarOrcamento(
        orcamento: orcamento,
        cliente: cliente,
        format: format,
      ),
    );
  }

  Future<void> compartilharOrcamento({
    required Orcamento orcamento,
    required Cliente? cliente,
  }) async {
    final bytes = await gerarOrcamento(orcamento: orcamento, cliente: cliente);

    await Printing.sharePdf(
      bytes: bytes,
      filename: _nomeArquivo(orcamento),
      subject: 'Orçamento ${_referenciaCurta(orcamento.id)}',
    );
  }

  pw.Widget _cabecalho(Orcamento orcamento) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'JL Serralheria',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Orçamento', style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _linhaTexto('Data', formatDate(orcamento.dataCriacao)),
            pw.SizedBox(height: 4),
            _linhaTexto('Referência', _referenciaCurta(orcamento.id)),
          ],
        ),
      ],
    );
  }

  Iterable<pw.Widget> _dadosCliente(Cliente? cliente) sync* {
    yield pw.Text(
      'Dados do cliente',
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
    );
    yield pw.SizedBox(height: 8);
    yield _linhaTexto(
      'Nome',
      cliente?.nome ?? 'Cliente removido',
      paginavel: true,
    );
    if (cliente != null) {
      yield _linhaTexto('Telefone', cliente.telefone, paginavel: true);
      if (_temTexto(cliente.endereco)) {
        yield _linhaTexto('Endereço', cliente.endereco!, paginavel: true);
      }
    }
  }

  // Os bytes são reutilizados por documentos com subconjuntos independentes.
  static final _fontes = (
    rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
  ).wait;

  Iterable<pw.Widget> _itens(Orcamento orcamento) sync* {
    final linhas = linhasDosItens(orcamento);
    for (final (indice, linha) in linhas.indexed) {
      final detalhes = orcamento.itens[indice].detalhesParaCliente?.trim();
      yield pw.NewPage(freeSpace: 72);
      yield pw.Divider(color: PdfColors.grey300);
      yield pw.Text(
        '${indice + 1}. ${linha[0]}',
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      );
      yield pw.Text(linha[1], overflow: pw.TextOverflow.span);
      if (detalhes != null && detalhes.isNotEmpty) {
        yield pw.Text(
          'Detalhes: $detalhes',
          overflow: pw.TextOverflow.span,
          style: const pw.TextStyle(fontSize: 10),
        );
      }
      yield pw.Text(
        '${linha[2]} ${linha[3]}  ×  ${linha[4]}     |     Subtotal: ${linha[5]}',
        overflow: pw.TextOverflow.span,
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
      );
      yield pw.SizedBox(height: 5);
    }
  }

  static List<List<String>> linhasDosItens(Orcamento orcamento) =>
      orcamento.itens.map((item) {
        return [
          _tipoItem(item.tipo),
          item.descricao,
          quantidadeText(item.quantidade),
          item.unidade,
          formatMoney(item.valorUnitario),
          formatMoney(item.subtotal),
        ];
      }).toList();

  pw.Widget _totais(Orcamento orcamento) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 220,
        child: pw.Column(
          children: [
            if (orcamento.itens.isNotEmpty) ...[
              _linhaTotal('Subtotal', formatMoney(orcamento.subtotal)),
              _linhaTotal('Desconto', formatMoney(orcamento.desconto)),
            ] else
              pw.Text('Registro histórico sem itens detalhados'),
            pw.Divider(color: PdfColors.grey500),
            _linhaTotal(
              'Total',
              formatarCentavos(orcamento.totalRegistradoCentavos!),
              destacado: true,
            ),
          ],
        ),
      ),
    );
  }

  Iterable<pw.Widget> _detalhesFinais(Orcamento orcamento) sync* {
    final validade = orcamento.dataCriacao.add(
      Duration(days: orcamento.validadeDias),
    );

    yield pw.NewPage(freeSpace: 64);
    yield _linhaTexto('Validade', formatDate(validade));
    final observacoes = orcamento.observacoesParaCliente.trim();
    if (observacoes.isEmpty) return;
    yield pw.SizedBox(height: 12);
    yield pw.Text(
      'Observações para o cliente',
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
    );
    yield pw.SizedBox(height: 4);
    yield pw.Text(observacoes, overflow: pw.TextOverflow.span);
  }

  pw.Widget _linhaTexto(String label, String value, {bool paginavel = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        overflow: paginavel ? pw.TextOverflow.span : pw.TextOverflow.visible,
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  pw.Widget _linhaTotal(String label, String value, {bool destacado = false}) {
    final style = pw.TextStyle(
      fontSize: destacado ? 14 : 11,
      fontWeight: destacado ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  static String _nomeArquivo(Orcamento orcamento) {
    return 'orcamento-${_referenciaCurta(orcamento.id)}.pdf';
  }

  static String _referenciaCurta(String? id) {
    if (id == null || id.trim().isEmpty) return 'SEM-ID';
    final normalizado = id.trim().replaceAll(RegExp('[^a-zA-Z0-9]'), '');
    if (normalizado.isEmpty) return 'SEM-ID';
    final limite = normalizado.length < 8 ? normalizado.length : 8;
    return normalizado.substring(0, limite).toUpperCase();
  }

  static String _tipoItem(String tipo) {
    return switch (tipo) {
      'produto' => 'Produto',
      'servico' => 'Serviço',
      _ => 'Manual',
    };
  }

  static bool _temTexto(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
