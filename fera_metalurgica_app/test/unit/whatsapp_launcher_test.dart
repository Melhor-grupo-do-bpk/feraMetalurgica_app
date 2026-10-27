import 'package:fera_metalurgica_app/features/orcamentos/data/whatsapp/whatsapp_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('montarLinkWhatsApp', () {
    test('usa 55 + os dígitos do número e codifica a mensagem (D-15)', () {
      final link = montarLinkWhatsApp('(11) 98765-4321', 'Olá, Nº 1!\nR\$ 2');

      expect(
        link.toString(),
        'https://wa.me/5511987654321?text=Ol%C3%A1%2C%20N%C2%BA%201!%0AR%24%202',
      );
      expect(link!.queryParameters['text'], 'Olá, Nº 1!\nR\$ 2');
    });

    test('aceita telefone fixo com DDD (10 dígitos)', () {
      expect(montarLinkWhatsApp('(11) 3333-4444', 'oi')?.path, '/551133334444');
    });

    test('é nulo com menos de 10 dígitos', () {
      expect(montarLinkWhatsApp('98765-432', 'oi'), isNull);
      expect(montarLinkWhatsApp('', 'oi'), isNull);
    });
  });

  group('WhatsappLauncher.abrirWhatsApp', () {
    test('abre o link e repassa o resultado', () async {
      final abertos = <Uri>[];
      final launcher = WhatsappLauncher((uri) async {
        abertos.add(uri);
        return true;
      });

      expect(await launcher.abrirWhatsApp('(99) 99999-9999', 'oi'), isTrue);
      expect(abertos.single.toString(), 'https://wa.me/5599999999999?text=oi');
    });

    test('número inválido não tenta abrir e retorna false', () async {
      var chamadas = 0;
      final launcher = WhatsappLauncher((_) async {
        chamadas++;
        return true;
      });

      expect(await launcher.abrirWhatsApp('123', 'oi'), isFalse);
      expect(chamadas, 0);
    });

    test('retorna false se o WhatsApp não abrir', () async {
      final launcher = WhatsappLauncher((_) async => false);

      expect(await launcher.abrirWhatsApp('(99) 99999-9999', 'oi'), isFalse);
    });

    test('retorna false se a plataforma lançar erro', () async {
      final launcher = WhatsappLauncher(
        (_) async => throw PlatformException(code: 'erro'),
      );

      expect(await launcher.abrirWhatsApp('(99) 99999-9999', 'oi'), isFalse);
    });
  });
}
