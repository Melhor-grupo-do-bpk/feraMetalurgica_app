import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/currency_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de valor em reais: prefixo "R$" e valor alinhado à direita,
/// formatado em pt-BR enquanto o usuário digita (máscara de centavos:
/// digitar `245000` exibe `2.450,00`).
class CurrencyField extends StatefulWidget {
  /// Cria o campo com valor inicial [valorInicial].
  const CurrencyField({this.valorInicial = 0, this.onChanged, super.key});

  /// Valor exibido ao montar o campo.
  final double valorInicial;

  /// Chamado com o novo valor (em reais) a cada alteração.
  final ValueChanged<double>? onChanged;

  @override
  State<CurrencyField> createState() => _CurrencyFieldState();
}

class _CurrencyFieldState extends State<CurrencyField> {
  late final TextEditingController _controller = TextEditingController(
    text: formatarNumeroMoeda(widget.valorInicial),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.textMuted)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xxs),
              child: Text(
                r'R$',
                style: AppTextStyles.title.copyWith(
                  fontWeight: FontWeight.w400,
                  color: colors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.right,
                textAlignVertical: TextAlignVertical.center,
                keyboardType: TextInputType.number,
                style: AppTextStyles.amount.copyWith(color: colors.textPrimary),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CentavosInputFormatter(),
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  // Área de toque mínima de 48 dp (RNF-06).
                  constraints: BoxConstraints(minHeight: 48),
                ),
                onChanged: (texto) => widget.onChanged?.call(
                  _CentavosInputFormatter.parse(texto),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Converte a sequência de dígitos digitada em valor formatado pt-BR,
/// tratando os dois últimos dígitos como centavos.
class _CentavosInputFormatter extends TextInputFormatter {
  static double parse(String texto) {
    final digitos = texto.replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return 0;
    return int.parse(digitos) / 100;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = formatarNumeroMoeda(parse(newValue.text));
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
