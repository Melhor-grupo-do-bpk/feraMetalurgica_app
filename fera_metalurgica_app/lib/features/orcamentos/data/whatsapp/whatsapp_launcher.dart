import 'dart:io';

import 'package:fera_metalurgica_app/core/utils/validators.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/pdf/orcamento_pdf_builder.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/mensagem_whatsapp.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'whatsapp_launcher.g.dart';

/// Gera o PDF de um orçamento.
typedef GerarPdf = Future<Uint8List> Function(Orcamento orcamento);

/// Abre a conversa com [numero] com o PDF anexado e diz se conseguiu.
typedef AbrirConversa =
    Future<bool> Function({
      required String numero,
      required Uint8List pdf,
      required String nomeArquivo,
      required String mensagem,
    });

/// Abre o compartilhamento do sistema com o PDF e diz se conseguiu.
typedef CompartilharPdf =
    Future<bool> Function({
      required Uint8List pdf,
      required String nomeArquivo,
      required String mensagem,
    });

/// Número internacional do WhatsApp (`55<dígitos>`, D-15), ou `null` se
/// [celular] tiver menos de 10 dígitos (sem DDD).
String? numeroWhatsApp(String celular) {
  final digitos = somenteDigitos(celular);
  return digitos.length < 10 ? null : '55$digitos';
}

/// Envia o PDF do orçamento pelo WhatsApp (D-43).
class WhatsappLauncher {
  /// Cria o launcher. As funções só são trocadas nos testes.
  const WhatsappLauncher({
    this._gerarPdf = gerarOrcamentoPdf,
    this._abrirConversa = _abrirConversaNoAndroid,
    this._compartilhar = _compartilharNoSistema,
  });

  final GerarPdf _gerarPdf;
  final AbrirConversa _abrirConversa;
  final CompartilharPdf _compartilhar;

  /// Abre a conversa do cliente com o PDF de [orcamento] anexado. Se não
  /// der (número inválido, iPhone ou WhatsApp que recuse), abre o
  /// compartilhamento do sistema com o PDF.
  ///
  /// Retorna `false` se nenhum dos dois abrir.
  Future<bool> enviarOrcamento(Orcamento orcamento) async {
    try {
      final pdf = await _gerarPdf(orcamento);
      final nomeArquivo = 'orcamento-${orcamento.codigo}.pdf';
      final mensagem = montarMensagemWhatsApp(orcamento);
      final numero = numeroWhatsApp(orcamento.cliente.celular);
      if (numero != null &&
          await _tentarConversa(numero, pdf, nomeArquivo, mensagem)) {
        return true;
      }
      return await _compartilhar(
        pdf: pdf,
        nomeArquivo: nomeArquivo,
        mensagem: mensagem,
      );
    } on Exception catch (erro) {
      debugPrint('Falha ao enviar o PDF: $erro');
      return false;
    }
  }

  Future<bool> _tentarConversa(
    String numero,
    Uint8List pdf,
    String nomeArquivo,
    String mensagem,
  ) async {
    try {
      return await _abrirConversa(
        numero: numero,
        pdf: pdf,
        nomeArquivo: nomeArquivo,
        mensagem: mensagem,
      );
    } on Exception catch (erro) {
      debugPrint('Falha ao abrir a conversa do WhatsApp: $erro');
      return false;
    }
  }

  static const MethodChannel _canal = MethodChannel('fera/whatsapp');

  // O link `wa.me` não aceita anexo: quem abre a conversa com o arquivo é o
  // `MainActivity`. A pasta é a declarada em `caminhos_arquivos.xml`.
  static Future<bool> _abrirConversaNoAndroid({
    required String numero,
    required Uint8List pdf,
    required String nomeArquivo,
    required String mensagem,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    final temporaria = await getTemporaryDirectory();
    final pasta = await Directory(
      '${temporaria.path}/orcamentos',
    ).create(recursive: true);
    final arquivo = await File(
      '${pasta.path}/$nomeArquivo',
    ).writeAsBytes(pdf, flush: true);
    final abriu = await _canal.invokeMethod<bool>('abrirConversaComArquivo', {
      'caminho': arquivo.path,
      'numero': numero,
      'mensagem': mensagem,
    });
    return abriu ?? false;
  }

  static Future<bool> _compartilharNoSistema({
    required Uint8List pdf,
    required String nomeArquivo,
    required String mensagem,
  }) => Printing.sharePdf(bytes: pdf, filename: nomeArquivo, body: mensagem);
}

/// Provider do [WhatsappLauncher]; os testes o trocam por um mock.
@riverpod
WhatsappLauncher whatsappLauncher(Ref ref) => const WhatsappLauncher();
