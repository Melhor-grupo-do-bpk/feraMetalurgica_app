import 'package:fera_metalurgica_app/features/orcamentos/data/whatsapp/whatsapp_launcher.dart';
import 'package:mocktail/mocktail.dart';

/// Mock de [WhatsappLauncher] para testes que tocam "Enviar WhatsApp" sem
/// abrir o app de verdade (`whatsappLauncherProvider.overrideWithValue`).
class MockWhatsappLauncher extends Mock implements WhatsappLauncher {}
