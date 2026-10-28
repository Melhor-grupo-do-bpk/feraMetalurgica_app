import 'package:flutter/material.dart';

/// Tokens de cor do app, extraídos do Figma (frames claro e escuro).
///
/// Este é o ÚNICO arquivo do projeto onde valores `Color(0x...)` podem
/// aparecer. Widgets leem as cores via `context.colors` (ver
/// [AppColorsContext]), que já devolve a variante do tema ativo.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Cria um conjunto de tokens de cor.
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceVariant,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.onPrimary,
    required this.brand,
    required this.onBrand,
    required this.brandStrong,
    required this.accent,
    required this.darkSurface,
    required this.onDarkSurface,
    required this.navActive,
    required this.onNavActive,
    required this.navInactive,
    required this.progressTrack,
    required this.timelineLine,
    required this.neutralContainer,
    required this.onNeutralContainer,
    required this.neutralDot,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.whatsapp,
    required this.onWhatsapp,
    required this.error,
  });

  /// Fundo das telas e da top bar (claro: #FDF8F8).
  final Color background;

  /// Fundo de cards (claro: branco).
  final Color surface;

  /// Fundo de campos de busca e cards concluídos (claro: #F7F3F2).
  final Color surfaceMuted;

  /// Fundo de contadores/tags discretas (claro: #F1EDEC).
  final Color surfaceVariant;

  /// Borda padrão de cards e da navegação (claro: #C4C7C7).
  final Color border;

  /// Borda/divisor suave (claro: #E5E2E1).
  final Color borderSubtle;

  /// Texto principal.
  final Color textPrimary;

  /// Texto secundário (rótulos, legendas).
  final Color textSecondary;

  /// Texto terciário (datas, placeholders).
  final Color textMuted;

  /// "Marron claro" — única variável cadastrada no Figma (#BA5E1B),
  /// escurecida para #B75B1A para o texto branco passar de 4,5:1 (D-25).
  final Color primary;

  /// Conteúdo sobre [primary].
  final Color onPrimary;

  /// "Marron Escuro" (#61310E): progresso, chip selecionado, ponto do logo.
  final Color brand;

  /// Conteúdo sobre [brand] (ex: texto do chip selecionado).
  final Color onBrand;

  /// "Marron" (#8D4715): títulos de resumo.
  final Color brandStrong;

  /// Laranja de destaque (#C25316): FAB, tarefas de produção.
  final Color accent;

  /// Fundo do botão escuro e do dia selecionado no calendário.
  final Color darkSurface;

  /// Conteúdo sobre [darkSurface].
  final Color onDarkSurface;

  /// Fundo da aba ativa da navegação inferior (#D56D22).
  final Color navActive;

  /// Ícone/rótulo da aba ativa. O Figma usa branco, com contraste de 3,5:1
  /// sobre [navActive]; o quase preto passa de 5:1 (D-25).
  final Color onNavActive;

  /// Ícone/rótulo das abas inativas (#575F67).
  final Color navInactive;

  /// Segmento não concluído do progresso do wizard (#DDD9D8).
  final Color progressTrack;

  /// Linha vertical da timeline do cronograma (#E9ECEF).
  final Color timelineLine;

  /// Chip neutro (ex: "Rascunho") e botão "Gerar PDF".
  final Color neutralContainer;

  /// Texto sobre [neutralContainer].
  final Color onNeutralContainer;

  /// Ponto indicador do chip neutro.
  final Color neutralDot;

  /// Badge informativo (ex: "Em análise", em todas as telas).
  final Color infoContainer;

  /// Texto sobre [infoContainer].
  final Color onInfoContainer;

  /// Badge de sucesso (ex: "Aprovado").
  final Color successContainer;

  /// Texto sobre [successContainer].
  final Color onSuccessContainer;

  /// Badge de erro (ex: "Recusado").
  final Color dangerContainer;

  /// Texto sobre [dangerContainer].
  final Color onDangerContainer;

  /// Fundo translúcido de tags de destaque (ex: "PRODUÇÃO").
  final Color accentContainer;

  /// Texto sobre [accentContainer]. O Figma usa [accent], com contraste
  /// abaixo de 4,5:1 sobre o fundo translúcido (D-25).
  final Color onAccentContainer;

  /// Botão "Enviar WhatsApp" dos detalhes (verde do WhatsApp, #25D366).
  final Color whatsapp;

  /// Conteúdo sobre [whatsapp]. O Figma usa branco, mas o contraste com o
  /// verde fica em 2:1; o quase preto do WhatsApp (#0B141A) passa de 9:1.
  final Color onWhatsapp;

  /// Cor de erro/campo obrigatório (#BA1A1A).
  final Color error;

  /// Tokens do tema claro (valores lidos dos frames claros do Figma).
  static const AppColors light = AppColors(
    background: Color(0xFFFDF8F8),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF7F3F2),
    surfaceVariant: Color(0xFFF1EDEC),
    border: Color(0xFFC4C7C7),
    borderSubtle: Color(0xFFE5E2E1),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF444748),
    textMuted: Color(0xFF747878),
    primary: Color(0xFFB75B1A),
    onPrimary: Color(0xFFFFFFFF),
    brand: Color(0xFF61310E),
    onBrand: Color(0xFFFFFFFF),
    brandStrong: Color(0xFF8D4715),
    accent: Color(0xFFC25316),
    darkSurface: Color(0xFF000000),
    onDarkSurface: Color(0xFFFFFFFF),
    navActive: Color(0xFFD56D22),
    onNavActive: Color(0xFF141312),
    navInactive: Color(0xFF575F67),
    progressTrack: Color(0xFFDDD9D8),
    timelineLine: Color(0xFFE9ECEF),
    neutralContainer: Color(0xFFE5E2E1),
    onNeutralContainer: Color(0xFF444748),
    neutralDot: Color(0xFF747878),
    infoContainer: Color(0xFFD8E1EA),
    onInfoContainer: Color(0xFF5B646B),
    successContainer: Color(0xFFE6F4EA),
    onSuccessContainer: Color(0xFF137333),
    // Não aparece no Figma: derivado do vermelho de erro do Figma (#BA1A1A).
    dangerContainer: Color(0xFFFFDAD6),
    onDangerContainer: Color(0xFFBA1A1A),
    accentContainer: Color(0x1AC25316),
    onAccentContainer: Color(0xFFA64514),
    whatsapp: Color(0xFF25D366),
    onWhatsapp: Color(0xFF0B141A),
    error: Color(0xFFBA1A1A),
  );

  /// Tokens do tema escuro.
  ///
  /// Lidos do frame "Dashboard Home — Dark": background, surface, border,
  /// textos, primary, brand (ponto do logo), chip neutro e navegação. Os
  /// demais (marcados com "derivado") não puderam ser lidos dos frames
  /// escuros e foram derivados da paleta escura — revisar com o design.
  static const AppColors dark = AppColors(
    background: Color(0xFF141312),
    surface: Color(0xFF1E1B19),
    surfaceMuted: Color(0xFF252220), // derivado
    surfaceVariant: Color(0xFF2E2A26),
    border: Color(0xFF3C3835),
    borderSubtle: Color(0xFF3C3835),
    textPrimary: Color(0xFFF2EFED),
    textSecondary: Color(0xFFC6C2BF),
    textMuted: Color(0xFFA3A6A6),
    primary: Color(0xFFD2761F),
    // Branco no Figma; o quase preto passa de 4,5:1 sobre o laranja (D-25).
    onPrimary: Color(0xFF141312),
    brand: Color(0xFFE9A268),
    onBrand: Color(0xFF141312), // derivado
    brandStrong: Color(0xFFE9A268), // derivado
    accent: Color(0xFFE07A3F), // derivado
    darkSurface: Color(0xFFF2EFED), // derivado (invertido para contraste)
    onDarkSurface: Color(0xFF141312), // derivado
    navActive: Color(0xFFD56D22),
    onNavActive: Color(0xFF141312),
    // #575F67 no Figma, com contraste de 2,9:1 sobre o fundo (D-25).
    navInactive: Color(0xFFA3A6A6),
    progressTrack: Color(0xFF3C3835), // derivado
    timelineLine: Color(0xFF3C3835), // derivado
    neutralContainer: Color(0xFF2E2A26),
    onNeutralContainer: Color(0xFFC6C2BF),
    neutralDot: Color(0xFF4A4542),
    infoContainer: Color(0xFF2A323A), // derivado
    onInfoContainer: Color(0xFFA9B4BE), // derivado
    successContainer: Color(0xFF1F3326), // derivado
    onSuccessContainer: Color(0xFF81C995), // derivado
    dangerContainer: Color(0xFF3B1F1C), // derivado
    onDangerContainer: Color(0xFFFFB4AB), // derivado
    accentContainer: Color(0x33E07A3F), // derivado
    onAccentContainer: Color(0xFFF0965F),
    whatsapp: Color(0xFF25D366),
    onWhatsapp: Color(0xFF0B141A),
    error: Color(0xFFFFB4AB), // derivado
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceVariant,
    Color? border,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? primary,
    Color? onPrimary,
    Color? brand,
    Color? onBrand,
    Color? brandStrong,
    Color? accent,
    Color? darkSurface,
    Color? onDarkSurface,
    Color? navActive,
    Color? onNavActive,
    Color? navInactive,
    Color? progressTrack,
    Color? timelineLine,
    Color? neutralContainer,
    Color? onNeutralContainer,
    Color? neutralDot,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? dangerContainer,
    Color? onDangerContainer,
    Color? accentContainer,
    Color? onAccentContainer,
    Color? whatsapp,
    Color? onWhatsapp,
    Color? error,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      brandStrong: brandStrong ?? this.brandStrong,
      accent: accent ?? this.accent,
      darkSurface: darkSurface ?? this.darkSurface,
      onDarkSurface: onDarkSurface ?? this.onDarkSurface,
      navActive: navActive ?? this.navActive,
      onNavActive: onNavActive ?? this.onNavActive,
      navInactive: navInactive ?? this.navInactive,
      progressTrack: progressTrack ?? this.progressTrack,
      timelineLine: timelineLine ?? this.timelineLine,
      neutralContainer: neutralContainer ?? this.neutralContainer,
      onNeutralContainer: onNeutralContainer ?? this.onNeutralContainer,
      neutralDot: neutralDot ?? this.neutralDot,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
      accentContainer: accentContainer ?? this.accentContainer,
      onAccentContainer: onAccentContainer ?? this.onAccentContainer,
      whatsapp: whatsapp ?? this.whatsapp,
      onWhatsapp: onWhatsapp ?? this.onWhatsapp,
      error: error ?? this.error,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      surfaceVariant: l(surfaceVariant, other.surfaceVariant),
      border: l(border, other.border),
      borderSubtle: l(borderSubtle, other.borderSubtle),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      brand: l(brand, other.brand),
      onBrand: l(onBrand, other.onBrand),
      brandStrong: l(brandStrong, other.brandStrong),
      accent: l(accent, other.accent),
      darkSurface: l(darkSurface, other.darkSurface),
      onDarkSurface: l(onDarkSurface, other.onDarkSurface),
      navActive: l(navActive, other.navActive),
      onNavActive: l(onNavActive, other.onNavActive),
      navInactive: l(navInactive, other.navInactive),
      progressTrack: l(progressTrack, other.progressTrack),
      timelineLine: l(timelineLine, other.timelineLine),
      neutralContainer: l(neutralContainer, other.neutralContainer),
      onNeutralContainer: l(onNeutralContainer, other.onNeutralContainer),
      neutralDot: l(neutralDot, other.neutralDot),
      infoContainer: l(infoContainer, other.infoContainer),
      onInfoContainer: l(onInfoContainer, other.onInfoContainer),
      successContainer: l(successContainer, other.successContainer),
      onSuccessContainer: l(onSuccessContainer, other.onSuccessContainer),
      dangerContainer: l(dangerContainer, other.dangerContainer),
      onDangerContainer: l(onDangerContainer, other.onDangerContainer),
      accentContainer: l(accentContainer, other.accentContainer),
      onAccentContainer: l(onAccentContainer, other.onAccentContainer),
      whatsapp: l(whatsapp, other.whatsapp),
      onWhatsapp: l(onWhatsapp, other.onWhatsapp),
      error: l(error, other.error),
    );
  }
}

/// Atalho para ler os tokens de cor do tema ativo.
extension AppColorsContext on BuildContext {
  /// Tokens de cor do tema ativo (claro ou escuro).
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
