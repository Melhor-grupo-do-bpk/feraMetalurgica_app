import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/whatsapp/whatsapp_launcher.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/mensagem_whatsapp.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../mocks/container_de_teste.dart';
import '../../../mocks/dados_exemplo.dart';
import '../../../mocks/mock_whatsapp_launcher.dart';
import '../../core/pump_themed.dart';

/// "Enviar WhatsApp" nos detalhes (RF-34, D-15, D-29), com o launcher
/// mockado.
void main() {
  late Database banco;
  late MockWhatsappLauncher launcher;

  setUp(() async {
    banco = await bancoComOrcamentos(orcamentosExemplo);
    launcher = MockWhatsappLauncher();
  });

  Future<void> abrirDetalhes(WidgetTester tester, String id) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpThemed(
      tester,
      ProviderScope(
        overrides: [
          bancoDeDadosProvider.overrideWithValue(banco),
          agoraProvider.overrideWithValue(agoraDosExemplos),
          whatsappLauncherProvider.overrideWithValue(launcher),
        ],
        child: OrcamentoDetalhesPage(orcamentoId: id),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Orcamento> salvo(String id) async =>
      (await SqliteOrcamentoRepository(banco).buscarPorId(id))!;

  void launcherResponde({required bool abriu}) => when(
    () => launcher.abrirWhatsApp(any(), any()),
  ).thenAnswer((_) async => abriu);

  testWidgets('abre a conversa do cliente com o resumo e passa a "Enviado"', (
    tester,
  ) async {
    launcherResponde(abriu: true);
    await abrirDetalhes(tester, 'orcamento-c');

    await tester.tap(find.text('Enviar WhatsApp'));
    await tester.pumpAndSettle();

    verify(
      () => launcher.abrirWhatsApp(
        '(11) 99999-8888',
        montarMensagemWhatsApp(orcamentoExemploC),
      ),
    ).called(1);
    final orcamento = await salvo('orcamento-c');
    expect(orcamento.status, StatusOrcamento.enviado);
    expect(orcamento.enviadoEm, agoraDosExemplos);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('reenviar um já enviado abre, mas não muda o envio', (
    tester,
  ) async {
    launcherResponde(abriu: true);
    await abrirDetalhes(tester, 'orcamento-e');

    await tester.tap(find.text('Enviar WhatsApp'));
    await tester.pumpAndSettle();

    verify(() => launcher.abrirWhatsApp(any(), any())).called(1);
    expect(await salvo('orcamento-e'), orcamentoExemploEnviado);
  });

  testWidgets('se não abrir, mostra o SnackBar e mantém o status', (
    tester,
  ) async {
    launcherResponde(abriu: false);
    await abrirDetalhes(tester, 'orcamento-c');

    await tester.tap(find.text('Enviar WhatsApp'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Não foi possível abrir o WhatsApp. Confira o número do cliente.',
      ),
      findsOneWidget,
    );
    expect(await salvo('orcamento-c'), orcamentoExemploC);
  });
}
