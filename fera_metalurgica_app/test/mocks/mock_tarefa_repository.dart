import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:mocktail/mocktail.dart';

/// Mock de [TarefaRepository] para testes que dependem da feature
/// `cronograma` sem tocar o banco.
class MockTarefaRepository extends Mock implements TarefaRepository {}
