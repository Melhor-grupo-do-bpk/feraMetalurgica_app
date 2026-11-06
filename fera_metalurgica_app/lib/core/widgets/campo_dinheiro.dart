import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/input_formatters.dart';
import 'package:fera_metalurgica_app/core/widgets/form_campo.dart';
import 'package:flutter/material.dart';

/// Campo de valor em reais, com a máscara do [DinheiroInputFormatter] (D-43;
/// nunca `double`, D-26). [onChanged] recebe o valor lido, ou `null` com o
/// campo vazio.
class CampoDinheiro extends StatefulWidget {
  /// Cria o campo.
  const CampoDinheiro({
    required this.rotulo,
    required this.onChanged,
    this.valorInicial,
    this.errorText,
    super.key,
  });

  /// Rótulo acima do campo.
  final String rotulo;

  /// Valor exibido ao montar o campo; `null` deixa o campo vazio.
  final Dinheiro? valorInicial;

  /// Chamado com o valor lido, ou `null` com o campo vazio.
  final ValueChanged<Dinheiro?> onChanged;

  /// Erro de regra vindo de fora (ex: do controller).
  final String? errorText;

  @override
  State<CampoDinheiro> createState() => _CampoDinheiroState();
}

class _CampoDinheiroState extends State<CampoDinheiro> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.valorInicial?.formatadoSemSimbolo ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormCampo(
      rotulo: widget.rotulo,
      child: TextFormField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: const [DinheiroInputFormatter()],
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          prefixText: r'R$ ',
          prefixStyle: AppTextStyles.body.copyWith(
            color: context.colors.textSecondary,
          ),
          hintText: '0,00',
          errorText: widget.errorText,
        ),
        onChanged: (texto) => widget.onChanged(Dinheiro.tryParse(texto)),
      ),
    );
  }
}
