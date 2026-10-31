import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/form_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de valor em reais, lido de texto pt-BR por `Dinheiro.tryParse`
/// (D-26, D-35; nunca `double`). [onChanged] recebe o valor lido, ou
/// `null` com o campo vazio. Texto inválido não chama [onChanged]: o campo
/// mostra o erro, e o `Form` em volta não valida.
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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))],
        textAlign: TextAlign.right,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          prefixText: r'R$ ',
          prefixStyle: AppTextStyles.body.copyWith(
            color: context.colors.textSecondary,
          ),
          hintText: '0,00',
          errorText: widget.errorText,
        ),
        validator: (texto) {
          final valor = texto?.trim() ?? '';
          if (valor.isEmpty || Dinheiro.tryParse(valor) != null) return null;
          return 'Valor inválido: use até 2 casas (ex: 1.234,56)';
        },
        onChanged: (texto) {
          if (texto.trim().isEmpty) return widget.onChanged(null);
          final valor = Dinheiro.tryParse(texto);
          if (valor != null) widget.onChanged(valor);
        },
      ),
    );
  }
}
