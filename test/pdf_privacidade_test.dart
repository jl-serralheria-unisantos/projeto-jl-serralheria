import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart'
    show MethodCall, MethodChannel, StandardMethodCodec;
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_jl_serralheria/data/models/cliente_model.dart';
import 'package:projeto_jl_serralheria/data/models/orcamento_model.dart';
import 'package:projeto_jl_serralheria/features/pdf/services/pdf_service.dart';

const _clienteInterno = 'INTERNOCLIENTE927';
const _itemInterno = 'INTERNOITEM639';
const _orcamentoInterno = 'INTERNOORCAMENTO417';
const _notaPublica = 'Prazo de instalação confirmado com o cliente.';
const _detalhe = 'Especificação aprovada — aço galvanizado, ½ polegada e €';

Orcamento _historico([String? observacao, String? geral]) =>
    Orcamento.fromMap('hist', {
      'cliente_id': 'cliente-teste',
      'data_criacao': DateTime(2026, 3, 10),
      'desconto': 0.01,
      'valor_total': '0.12',
      'observacoes': ?geral,
      'itens': [
        {
          'tipo': 'produto',
          'descricao': 'Peça histórica',
          'quantidade': 0.125,
          'unidade': 'm',
          'valor_unitario': 1,
          'observacoes': observacao,
        },
      ],
    });

Cliente _cliente([String? observacao]) => Cliente(
  nome: 'João Gonçalves — Açucena',
  telefone: '0000-0000',
  observacoes: observacao,
);

// O identificador no trailer do PDF contém o instante de geração.
String _conteudo(Uint8List bytes) => latin1
    .decode(bytes)
    .replaceFirst(
      RegExp(r'/ID\s*\[\s*<[\da-fA-F]+>\s*<[\da-fA-F]+>\s*\]'),
      '/ID []',
    );

Future<void> _exportar(String nome, Uint8List bytes) async {
  final destino = Platform.environment['PDF_QA_DIR'];
  if (destino == null) return;
  await Directory(destino).create(recursive: true);
  await File('$destino/$nome.pdf').writeAsBytes(bytes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pdf = PdfService();

  test(
    'impressão e compartilhamento recebem o mesmo conteúdo protegido',
    () async {
      const canal = MethodChannel('net.nfet.printing');
      const codec = StandardMethodCodec();
      final mensagens =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      Uint8List? impresso;
      Uint8List? compartilhado;
      mensagens.setMockMethodCallHandler(canal, (chamada) async {
        final args = chamada.arguments as Map;
        expect(args['name'], 'orcamento-HIST.pdf');
        if (chamada.method == 'printPdf') {
          await mensagens.handlePlatformMessage(
            canal.name,
            codec.encodeMethodCall(MethodCall('onLayout', args)),
            (resposta) =>
                impresso = codec.decodeEnvelope(resposta!) as Uint8List,
          );
          await mensagens.handlePlatformMessage(
            canal.name,
            codec.encodeMethodCall(
              MethodCall('onCompleted', {
                'job': args['job'],
                'completed': true,
              }),
            ),
            (_) {},
          );
        } else {
          expect(chamada.method, 'sharePdf');
          compartilhado = args['doc'] as Uint8List;
        }
        return 1;
      });
      addTearDown(() => mensagens.setMockMethodCallHandler(canal, null));
      final orcamento = _historico(
        _itemInterno,
        _orcamentoInterno,
      ).copyWith(observacoesParaCliente: _notaPublica);
      final cliente = _cliente(_clienteInterno);
      await pdf.visualizarOrcamento(orcamento: orcamento, cliente: cliente);
      await pdf.compartilharOrcamento(orcamento: orcamento, cliente: cliente);
      final esperado = _conteudo(
        await pdf.gerarOrcamento(
          orcamento: _historico().copyWith(
            observacoesParaCliente: _notaPublica,
          ),
          cliente: _cliente(),
        ),
      );
      expect(_conteudo(impresso!), esperado);
      expect(_conteudo(compartilhado!), esperado);
    },
  );

  test('observações internas não alteram o conteúdo binário do PDF', () async {
    final historico = _historico(_itemInterno, _orcamentoInterno);
    final mapaAntes = historico.toFirestore(preservarTotalOriginal: true);
    final protegido = await pdf.gerarOrcamento(
      orcamento: historico,
      cliente: _cliente(_clienteInterno),
    );
    final semObservacoes = await pdf.gerarOrcamento(
      orcamento: _historico(),
      cliente: _cliente(),
    );
    expect(_conteudo(protegido), _conteudo(semObservacoes));
    expect(historico.toFirestore(preservarTotalOriginal: true), mapaAntes);
    expect(historico.itens.single.toMap()['observacoes'], _itemInterno);
    expect(
      historico.itens.single.toMap(),
      isNot(contains('detalhes_para_cliente')),
    );
    expect(mapaAntes['valor_total'], '0.12');
    expect(mapaAntes['observacoes'], _orcamentoInterno);
    expect(mapaAntes, isNot(contains('observacoes_para_cliente')));
    await _exportar('historico-privado', protegido);
  });

  test('endereço de 150 linhas pagina sem impedir emissão histórica', () async {
    final cliente = Cliente(
      nome: 'Cliente Sintético',
      telefone: '0000-0000',
      endereco: List.generate(
        150,
        (i) => 'Linha de endereço ${i + 1}',
      ).join('\n'),
    );
    final orcamento = Orcamento.fromMap('sem-itens', {
      'valor_total': 8.25,
      'data_criacao': DateTime(2026, 3, 10),
      'observacoes': _orcamentoInterno,
    });
    final bytes = await pdf.gerarOrcamento(
      orcamento: orcamento,
      cliente: cliente,
    );
    expect(
      RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(bytes)).length,
      greaterThan(2),
    );
    await _exportar('endereco-longo', bytes);
  });

  test(
    'detalhe público persiste e PDF pagina textos longos e 90 itens',
    () async {
      const descricao = 'Descrição comprida — corte, fixação e acabamento.';
      final itens = List.generate(
        90,
        (i) => ItemOrcamentoEmbutido(
          tipo: 'produto',
          descricao: i == 0
              ? List.filled(125, descricao).join(' ')
              : 'Peça ${i + 1}',
          quantidade: 0.125,
          unidade: 'm²',
          valorUnitario: 1,
          observacoes: _itemInterno,
          detalhesParaCliente: i == 0
              ? '$_detalhe. ${List.filled(120, descricao).join(' ')} FIMDETALHE'
              : null,
        ),
      );
      final original = Orcamento(
        clienteId: 'cliente-teste',
        dataCriacao: DateTime(2026, 3, 10),
        desconto: 0.2,
        valorTotal: 11.5,
        observacoes: _orcamentoInterno,
        observacoesParaCliente: _notaPublica,
        itens: itens,
      );
      final orcamento = Orcamento.fromMap('novo', original.toFirestore());
      expect(
        orcamento.itens.first.detalhesParaCliente,
        itens.first.detalhesParaCliente,
      );
      expect(orcamento.subtotal, 11.7);
      expect(orcamento.observacoesParaCliente, _notaPublica);
      final bytes = await pdf.gerarOrcamento(
        orcamento: orcamento,
        cliente: _cliente(_clienteInterno),
      );
      final conteudo = latin1.decode(bytes);
      expect(
        RegExp(r'/Type\s*/Page\b').allMatches(conteudo).length,
        greaterThan(1),
      );
      expect(conteudo, contains('/ToUnicode'));
      await _exportar('orcamento-longo', bytes);
    },
  );
}
