import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'relogio_provider.g.dart';

/// Data e hora atuais. Telas e controllers leem daqui em vez de chamar
/// `DateTime.now()`, para que os testes fixem o "agora"
/// (`agoraProvider.overrideWithValue(DateTime(2023, 10, 9, 8))`,
/// `03-padroes.md` §5).
///
/// Para gravar um instante (ex: `criadoEm`), use `ref.read` no momento da
/// ação; para "hoje" numa tela, `ref.watch` e descarte a hora.
@riverpod
DateTime agora(Ref ref) => DateTime.now();
