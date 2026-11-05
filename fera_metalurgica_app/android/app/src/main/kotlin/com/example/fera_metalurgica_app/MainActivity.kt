package com.example.fera_metalurgica_app

import android.content.ActivityNotFoundException
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fera/whatsapp")
            .setMethodCallHandler { call, result ->
                if (call.method == "abrirConversaComArquivo") {
                    result.success(
                        abrirConversaComArquivo(
                            call.argument<String>("caminho")!!,
                            call.argument<String>("numero")!!,
                            call.argument<String>("mensagem")!!,
                        ),
                    )
                } else {
                    result.notImplemented()
                }
            }
    }

    // O extra "jid" abre a conversa do número direto, em vez da lista de
    // contatos. Não é uma API oficial do WhatsApp: se ele falhar, o lado Dart
    // cai no compartilhamento do sistema (D-43).
    private fun abrirConversaComArquivo(
        caminho: String,
        numero: String,
        mensagem: String,
    ): Boolean {
        val arquivo = FileProvider.getUriForFile(this, "$packageName.arquivos", File(caminho))
        for (pacote in listOf("com.whatsapp", "com.whatsapp.w4b")) {
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "application/pdf"
                setPackage(pacote)
                putExtra(Intent.EXTRA_STREAM, arquivo)
                putExtra(Intent.EXTRA_TEXT, mensagem)
                putExtra("jid", "$numero@s.whatsapp.net")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            try {
                startActivity(intent)
                return true
            } catch (_: ActivityNotFoundException) {
                // Sem este WhatsApp no aparelho: tenta o próximo.
            }
        }
        return false
    }
}
