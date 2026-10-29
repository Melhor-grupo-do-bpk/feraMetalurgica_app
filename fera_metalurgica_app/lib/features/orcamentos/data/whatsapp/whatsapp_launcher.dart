import 'package:fera_metalurgica_app/core/utils/validators.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'whatsapp_launcher.g.dart';

/// Função que abre [uri] fora do app e diz se conseguiu.
typedef AbrirUri = Future<bool> Function(Uri uri);

/// Link `https://wa.me/55<dígitos>?text=<mensagem>` (D-15), ou `null` se
/// [numero] tiver menos de 10 dígitos (sem DDD).
Uri? montarLinkWhatsApp(String numero, String mensagem) {
  final digitos = somenteDigitos(numero);
  if (digitos.length < 10) return null;
  // `encodeComponent` gera `%20`; o `queryParameters` do `Uri` usaria `+`.
  return Uri.parse(
    'https://wa.me/55$digitos?text=${Uri.encodeComponent(mensagem)}',
  );
}

/// Abre conversas do WhatsApp com `url_launcher` (D-15).
class WhatsappLauncher {
  /// Cria o launcher. A função que abre o link só é trocada nos testes.
  const WhatsappLauncher([this._abrirUri = _abrirNoApp]);

  final AbrirUri _abrirUri;

  /// Abre a conversa com [numero] já com [mensagem] digitada.
  ///
  /// Retorna `false` se o número for inválido ou o WhatsApp não abrir.
  Future<bool> abrirWhatsApp(String numero, String mensagem) async {
    final link = montarLinkWhatsApp(numero, mensagem);
    if (link == null) return false;
    try {
      return await _abrirUri(link);
    } on Exception catch (erro) {
      debugPrint('Falha ao abrir o WhatsApp: $erro');
      return false;
    }
  }

  static Future<bool> _abrirNoApp(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Provider do [WhatsappLauncher]; os testes o trocam por um mock.
@riverpod
WhatsappLauncher whatsappLauncher(Ref ref) => const WhatsappLauncher();
