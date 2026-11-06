import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:mocktail/mocktail.dart';

/// Mock de [CepRepository] para testes sem internet
/// (`cepRepositoryProvider.overrideWithValue`).
class MockCepRepository extends Mock implements CepRepository {}
