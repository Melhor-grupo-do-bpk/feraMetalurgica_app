import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';

/// "Agora" usado pelos testes que comparam com as datas da tela do Figma
/// (9 de outubro de 2023, 8h).
final DateTime agoraDosExemplos = DateTime(2023, 10, 9, 8);

/// As tarefas de exemplo (`tarefasExemplo`) geradas em [agoraDosExemplos].
final List<Tarefa> tarefasExemplo = cronogramaSeed(agoraDosExemplos);
