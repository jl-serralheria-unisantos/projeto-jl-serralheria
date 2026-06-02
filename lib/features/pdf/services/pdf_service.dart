import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/cliente_model.dart';
import '../../../data/models/orcamento_model.dart';
import '../../../shared/formatters.dart';

class PdfService {
  const PdfService();

  Future<Uint8List> gerarOrcamento({
    required Orcamento orcamento,
    required Cliente? cliente,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _cabecalho(orcamento),
          pw.SizedBox(height: 20),
          _dadosCliente(cliente),
          pw.SizedBox(height: 18),
          _itens(orcamento),
          pw.SizedBox(height: 16),
          _totais(orcamento),
          pw.SizedBox(height: 18),
          _detalhesFinais(orcamento),
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
    final bytes = await gerarOrcamento(
      orcamento: orcamento,
      cliente: cliente,
    );

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
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Orçamento',
              style: const pw.TextStyle(fontSize: 12),
            ),
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

  pw.Widget _dadosCliente(Cliente? cliente) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Dados do cliente',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _linhaTexto('Nome', cliente?.nome ?? 'Cliente removido'),
          if (cliente != null) ...[
            _linhaTexto('Telefone', cliente.telefone),
            if (_temTexto(cliente.endereco))
              _linhaTexto('Endereço', cliente.endereco!),
            if (_temTexto(cliente.observacoes))
              _linhaTexto('Observações do cliente', cliente.observacoes!),
          ],
        ],
      ),
    );
  }

  pw.Widget _itens(Orcamento orcamento) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FlexColumnWidth(1.1),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(0.8),
        3: const pw.FlexColumnWidth(0.8),
        4: const pw.FlexColumnWidth(1.3),
        5: const pw.FlexColumnWidth(1.3),
      },
      headers: const [
        'Tipo',
        'Descrição',
        'Qtd.',
        'Unid.',
        'Valor unit.',
        'Subtotal',
      ],
      data: orcamento.itens.map((item) {
        return [
          _tipoItem(item.tipo),
          item.descricao,
          decimalText(item.quantidade),
          item.unidade,
          formatMoney(item.valorUnitario),
          formatMoney(item.subtotal),
        ];
      }).toList(),
    );
  }

  pw.Widget _totais(Orcamento orcamento) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 220,
        child: pw.Column(
          children: [
            _linhaTotal('Subtotal', formatMoney(orcamento.subtotal)),
            _linhaTotal('Desconto', formatMoney(orcamento.desconto)),
            pw.Divider(color: PdfColors.grey500),
            _linhaTotal(
              'Total',
              formatMoney(orcamento.valorFinal),
              destacado: true,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _detalhesFinais(Orcamento orcamento) {
    final validade = orcamento.dataCriacao.add(
      Duration(days: orcamento.validadeDias),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _linhaTexto('Validade', formatDate(validade)),
        pw.SizedBox(height: 12),
        pw.Text(
          'Observações',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          orcamento.observacoes.isEmpty
              ? 'Sem observações.'
              : orcamento.observacoes,
        ),
      ],
    );
  }

  pw.Widget _linhaTexto(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
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

  pw.Widget _linhaTotal(
    String label,
    String value, {
    bool destacado = false,
  }) {
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
