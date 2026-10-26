import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// Gera um identificador único (UUID v4) para entidades sem numeração
/// própria: cliente, item de orçamento, tarefa (D-09). Orçamentos usam
/// `proximoIdOrcamento`.
String gerarId() => _uuid.v4();
