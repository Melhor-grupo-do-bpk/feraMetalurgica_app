import 'package:fera_metalurgica_app/features/orcamentos/data/whatsapp/whatsapp_launcher.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/mensagem_whatsapp.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/dados_exemplo.dart';

void main() {
  final pdf = Uint8List.fromList([1, 2, 3]);

  group('numeroWhatsApp', () {
    test('usa 55 + os dígitos do número (D-15)', () {
      expect(numeroWhatsApp('(11) 98765-4321'), '5511987654321');
    });

    test('aceita telefone fixo com DDD (10 dígitos)', () {
      expect(numeroWhatsApp('(11) 3333-4444'), '551133334444');
    });

    test('é nulo com menos de 10 dígitos', () {
      expect(numeroWhatsApp('98765-432'), isNull);
      expect(numeroWhatsApp(''), isNull);
    });
  });

  group('WhatsappLauncher.enviarOrcamento', () {
    late List<String> numeros;
    late int compartilhados;

    setUp(() {
      numeros = [];
      compartilhados = 0;
    });

    WhatsappLauncher launcher({
      required Future<bool> Function() conversa,
      bool compartilhou = true,
      GerarPdf? gerarPdf,
    }) => WhatsappLauncher(
      gerarPdf: gerarPdf ?? (_) async => pdf,
      abrirConversa:
          ({
            required numero,
            required pdf,
            required nomeArquivo,
            required mensagem,
          }) {
            numeros.add(numero);
            return conversa();
          },
      compartilhar:
          ({required pdf, required nomeArquivo, required mensagem}) async {
            compartilhados++;
            return compartilhou;
          },
    );

    test('abre a conversa do cliente e não compartilha', () async {
      final enviar = launcher(conversa: () async => true);

      expect(await enviar.enviarOrcamento(orcamentoExemploC), isTrue);
      expect(numeros, ['5511999998888']);
      expect(compartilhados, 0);
    });

    test('passa o PDF, o nome do arquivo e a mensagem', () async {
      late String nome;
      late String texto;
      late Uint8List bytes;
      final enviar = WhatsappLauncher(
        gerarPdf: (_) async => pdf,
        abrirConversa:
            ({
              required numero,
              required pdf,
              required nomeArquivo,
              required mensagem,
            }) async {
              bytes = pdf;
              nome = nomeArquivo;
              texto = mensagem;
              return true;
            },
      );

      await enviar.enviarOrcamento(orcamentoExemploC);

      expect(bytes, pdf);
      expect(nome, 'orcamento-${orcamentoExemploC.codigo}.pdf');
      expect(texto, montarMensagemWhatsApp(orcamentoExemploC));
    });

    test('se a conversa não abrir, compartilha', () async {
      final enviar = launcher(conversa: () async => false);

      expect(await enviar.enviarOrcamento(orcamentoExemploC), isTrue);
      expect(compartilhados, 1);
    });

    test('se a conversa der erro, compartilha', () async {
      final enviar = launcher(
        conversa: () async => throw PlatformException(code: 'erro'),
      );

      expect(await enviar.enviarOrcamento(orcamentoExemploC), isTrue);
      expect(compartilhados, 1);
    });

    test('número inválido vai direto para o compartilhamento', () async {
      final semNumero = orcamentoExemploC.copyWith(
        cliente: orcamentoExemploC.cliente.copyWith(celular: '123'),
      );
      final enviar = launcher(conversa: () async => true);

      expect(await enviar.enviarOrcamento(semNumero), isTrue);
      expect(numeros, isEmpty);
      expect(compartilhados, 1);
    });

    test('retorna false se nada abrir', () async {
      final enviar = launcher(conversa: () async => false, compartilhou: false);

      expect(await enviar.enviarOrcamento(orcamentoExemploC), isFalse);
    });

    test('retorna false se o PDF não for gerado', () async {
      final enviar = launcher(
        conversa: () async => true,
        gerarPdf: (_) async => throw Exception('falhou'),
      );

      expect(await enviar.enviarOrcamento(orcamentoExemploC), isFalse);
      expect(numeros, isEmpty);
    });
  });
}
