import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:mocktail/mocktail.dart';

/// Mock de [LocalizacaoRepository] para testes sem GPS
/// (`localizacaoRepositoryProvider.overrideWithValue`).
class MockLocalizacaoRepository extends Mock implements LocalizacaoRepository {}
