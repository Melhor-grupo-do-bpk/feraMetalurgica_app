import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tipo de teclado e filtro de um [CampoTexto].
enum TipoCampo {
  /// Texto livre.
  texto,

  /// Número com até duas casas (dinheiro, medida): teclado com vírgula ou
  /// ponto (D-35); a leitura é do `Dinheiro`/`MedidaCm`.
  decimal,

  /// Inteiro (quantidades): só dígitos.
  inteiro,
}

/// Campo de texto dos formulários do produto e da peça, com rótulo,
/// ajuda e erro (até 3 linhas, para caber a 360 dp).
class CampoTexto extends StatelessWidget {
  /// Cria o campo. [chave] vira a `ValueKey` do `TextField`.
  const CampoTexto({
    required this.chave,
    required this.controller,
    required this.rotulo,
    required this.onChanged,
    this.tipo = TipoCampo.texto,
    this.dica,
    this.ajuda,
    this.erro,
    this.prefixo,
    this.sufixo,
    this.habilitado = true,
    this.maxLinhas = 1,
    super.key,
  });

  /// Chave do `TextField`, para os testes.
  final String chave;

  /// Texto do campo.
  final TextEditingController controller;

  /// Rótulo.
  final String rotulo;

  /// Chamado a cada alteração digitada.
  final ValueChanged<String> onChanged;

  /// Teclado e filtro.
  final TipoCampo tipo;

  /// Exemplo dentro do campo vazio.
  final String? dica;

  /// Texto de ajuda abaixo do campo.
  final String? ajuda;

  /// Erro abaixo do campo (substitui a ajuda).
  final String? erro;

  /// Texto antes do valor (ex: "R$ ").
  final String? prefixo;

  /// Texto depois do valor (ex: "/m²").
  final String? sufixo;

  /// Se aceita edição.
  final bool habilitado;

  /// Linhas máximas (observações).
  final int maxLinhas;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: TextField(
      key: ValueKey(chave),
      controller: controller,
      enabled: habilitado,
      minLines: 1,
      maxLines: maxLinhas,
      keyboardType: switch (tipo) {
        TipoCampo.texto =>
          maxLinhas > 1 ? TextInputType.multiline : TextInputType.text,
        TipoCampo.decimal => const TextInputType.numberWithOptions(
          decimal: true,
        ),
        TipoCampo.inteiro => TextInputType.number,
      },
      inputFormatters: tipo == TipoCampo.inteiro
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: rotulo,
        hintText: dica,
        helperText: ajuda,
        helperMaxLines: 3,
        errorText: erro,
        errorMaxLines: 3,
        prefixText: prefixo,
        suffixText: sufixo,
      ),
      onChanged: onChanged,
    ),
  );
}
