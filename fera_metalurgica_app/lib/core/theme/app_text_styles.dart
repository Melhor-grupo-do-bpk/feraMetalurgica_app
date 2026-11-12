import 'package:flutter/material.dart';

/// Estilos de texto do app, extraídos dos tamanhos/pesos usados no Figma.
///
/// Os estilos não definem cor: a cor vem do tema (ou do widget, via
/// `copyWith(color: context.colors.xxx)`).
///
/// O Figma usa a fonte Inter (alguns textos aparecem como "Liberation Sans",
/// que é fallback de fonte ausente no arquivo). A fonte ainda não está
/// empacotada no app, então a fonte padrão da plataforma é usada.
abstract final class AppTextStyles {
  /// Título de página do wizard ("Novo Orçamento") — 32/40 semibold.
  static const TextStyle display = TextStyle(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.32,
  );

  /// Número dos indicadores do dashboard — 32/40 bold.
  static const TextStyle statValue = TextStyle(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.32,
  );

  /// Título de seção ("Orçamentos Recentes", "Hoje") — 24/32 bold.
  static const TextStyle headline = TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
  );

  /// Valor monetário de destaque e campo de moeda — 24/32 semibold.
  static const TextStyle amount = TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w600,
  );

  /// Título de card ("João da Silva" na lista) — 18/28 medium.
  static const TextStyle title = TextStyle(
    fontSize: 18,
    height: 28 / 18,
    fontWeight: FontWeight.w500,
  );

  /// Texto corrido e valores de formulário — 16/24 regular.
  static const TextStyle body = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );

  /// Texto corrido em destaque (título de tarefa) — 16/24 bold.
  static const TextStyle bodyStrong = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w700,
  );

  /// Rótulo da barra de navegação, como na tab bar do iOS — 10/12 medium.
  static const TextStyle tabLabel = TextStyle(
    fontSize: 10,
    height: 12 / 10,
    fontWeight: FontWeight.w500,
  );

  /// Rótulos, chips e abas — 14/20 regular, tracking 0.7.
  static const TextStyle label = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.7,
  );

  /// Rótulo de botão/chip — 14/20 medium, tracking 0.7.
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.7,
  );

  /// Cabeçalho de seção em caixa alta ("FILTROS DE TAREFAS") — 14/20 bold.
  static const TextStyle labelStrong = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.7,
  );

  /// Legendas, datas e badges — 12/16 regular.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );

  /// Tag em caixa alta ("ORÇAMENTO", "PRODUÇÃO") — 12/16 bold.
  static const TextStyle tag = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  );

  /// Botão principal grande ("Criar orçamento") — 16/24 bold.
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w700,
  );

  /// Wordmark "ERA." da top bar — 24/32 black, tracking -1.2.
  static const TextStyle logo = TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.2,
  );
}
