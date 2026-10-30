import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:mocktail/mocktail.dart';

/// Mock de [OrcamentoRepository] para testes que simulam falhas de leitura
/// ou gravação; nos demais, use um banco em memória (`bancoComOrcamentos`).
class MockOrcamentoRepository extends Mock implements OrcamentoRepository {}
