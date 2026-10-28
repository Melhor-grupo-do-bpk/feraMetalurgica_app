import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/core/utils/id_generator.dart';
import 'package:fera_metalurgica_app/core/utils/validators.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/form_campo.dart';
import 'package:fera_metalurgica_app/features/cronograma/domain/tarefa.dart';
import 'package:fera_metalurgica_app/features/cronograma/domain/tipo_tarefa.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma_controller.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma_ui.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Campos da tarefa (RF-86): título\*, data\*, hora\*, tipo\*, descrição e
/// orçamento vinculado. Sem [inicial], cria uma tarefa nova com os campos
/// vazios; com ele, edita e oferece "Excluir".
class TarefaForm extends ConsumerStatefulWidget {
  /// Cria o formulário.
  const TarefaForm({this.inicial, super.key});

  /// Tarefa em edição, ou `null` para uma tarefa nova.
  final Tarefa? inicial;

  @override
  ConsumerState<TarefaForm> createState() => _TarefaFormState();
}

class _TarefaFormState extends ConsumerState<TarefaForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _descricao;
  late final TextEditingController _dataTexto;
  late final TextEditingController _horaTexto;
  DateTime? _data;
  TimeOfDay? _hora;
  TipoTarefa? _tipo;
  String? _orcamentoId;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final inicial = widget.inicial;
    _titulo = TextEditingController(text: inicial?.titulo);
    _descricao = TextEditingController(text: inicial?.descricao);
    _data = inicial?.data;
    _hora = inicial == null ? null : TimeOfDay.fromDateTime(inicial.data);
    _dataTexto = TextEditingController(
      text: inicial == null ? null : formatarData(inicial.data),
    );
    _horaTexto = TextEditingController(
      text: inicial == null ? null : formatarHora(inicial.data),
    );
    _tipo = inicial?.tipo;
    _orcamentoId = inicial?.orcamentoId;
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _dataTexto.dispose();
    _horaTexto.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final agora = ref.read(agoraProvider);
    final data = await showDatePicker(
      context: context,
      initialDate: _data ?? agora,
      firstDate: DateTime(agora.year - 5),
      lastDate: DateTime(agora.year + 5, 12, 31),
    );
    if (data == null) return;
    setState(() {
      _data = data;
      _dataTexto.text = formatarData(data);
    });
  }

  Future<void> _escolherHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _hora ?? TimeOfDay.fromDateTime(ref.read(agoraProvider)),
    );
    if (hora == null) return;
    setState(() {
      _hora = hora;
      _horaTexto.text = formatarHora(
        DateTime(2000, 1, 1, hora.hour, hora.minute),
      );
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final data = _data!;
    final hora = _hora!;
    final descricao = _descricao.text.trim();
    final tarefa = Tarefa(
      id: widget.inicial?.id ?? gerarId(),
      titulo: _titulo.text.trim(),
      data: DateTime(data.year, data.month, data.day, hora.hour, hora.minute),
      tipo: _tipo!,
      concluida: widget.inicial?.concluida ?? false,
      descricao: descricao.isEmpty ? null : descricao,
      orcamentoId: _orcamentoId,
    );

    setState(() => _salvando = true);
    try {
      await ref.read(tarefasProvider.notifier).salvar(tarefa);
      if (mounted) context.pop();
    } on Object {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a tarefa.')),
      );
    }
  }

  Future<void> _excluir() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir tarefa?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _salvando = true);
    try {
      await ref.read(tarefasProvider.notifier).excluir(widget.inicial!.id);
      if (mounted) context.pop();
    } on Object {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a tarefa.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final edicao = widget.inicial != null;
    final orcamentos = ref.watch(orcamentosProvider).value ?? const [];
    final idsOrcamentos = {for (final o in orcamentos) o.id};

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            edicao ? 'Editar tarefa' : 'Nova tarefa',
            style: AppTextStyles.headline.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          FormCampo(
            rotulo: 'Título',
            obrigatorio: true,
            child: TextFormField(
              key: const ValueKey('tarefa-titulo'),
              controller: _titulo,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: validarObrigatorio,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A data ("10/10/2026") é mais larga que a hora ("14:00").
              Expanded(
                flex: 3,
                child: FormCampo(
                  rotulo: 'Data',
                  obrigatorio: true,
                  child: TextFormField(
                    key: const ValueKey('tarefa-data'),
                    controller: _dataTexto,
                    readOnly: true,
                    onTap: _escolherData,
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    validator: validarObrigatorio,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: FormCampo(
                  rotulo: 'Hora',
                  obrigatorio: true,
                  child: TextFormField(
                    key: const ValueKey('tarefa-hora'),
                    controller: _horaTexto,
                    readOnly: true,
                    onTap: _escolherHora,
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.schedule),
                    ),
                    validator: validarObrigatorio,
                  ),
                ),
              ),
            ],
          ),
          FormCampo(
            rotulo: 'Tipo',
            obrigatorio: true,
            child: DropdownButtonFormField<TipoTarefa>(
              key: const ValueKey('tarefa-tipo'),
              initialValue: _tipo,
              items: [
                for (final tipo in TipoTarefa.values)
                  DropdownMenuItem(value: tipo, child: Text(tipo.label)),
              ],
              onChanged: (tipo) => setState(() => _tipo = tipo),
              validator: (tipo) => tipo == null ? 'Campo obrigatório' : null,
            ),
          ),
          FormCampo(
            rotulo: 'Descrição',
            child: TextFormField(
              key: const ValueKey('tarefa-descricao'),
              controller: _descricao,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 4,
            ),
          ),
          FormCampo(
            rotulo: 'Orçamento vinculado',
            child: DropdownButtonFormField<String?>(
              key: const ValueKey('tarefa-orcamento'),
              initialValue: _orcamentoId,
              isExpanded: true,
              items: [
                const DropdownMenuItem(child: Text('Nenhum')),
                for (final o in orcamentos)
                  DropdownMenuItem(
                    value: o.id,
                    child: Text(
                      '${o.numeroFormatado} - ${o.cliente.nome}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                // Vínculo com um orçamento que não existe mais (ou que ainda
                // não carregou): mantém o valor em vez de perdê-lo.
                if (_orcamentoId != null &&
                    !idsOrcamentos.contains(_orcamentoId))
                  DropdownMenuItem(
                    value: _orcamentoId,
                    child: Text('#$_orcamentoId'),
                  ),
              ],
              onChanged: (id) => setState(() => _orcamentoId = id),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Salvar tarefa',
            icon: Icons.check,
            large: true,
            onPressed: _salvando ? null : _salvar,
          ),
          if (edicao) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: _salvando ? null : _excluir,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Excluir tarefa'),
              style: TextButton.styleFrom(foregroundColor: colors.error),
            ),
          ],
        ],
      ),
    );
  }
}
