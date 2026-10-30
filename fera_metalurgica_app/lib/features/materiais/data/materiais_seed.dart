import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/unidade_cobranca.dart';
import 'package:fera_metalurgica_app/features/materiais/domain/material.dart';

/// Granito de exemplo (m², R$ 300,00), do exemplo A do prompt §9.
const Material granitoExemplo = Material(
  id: 'material-granito',
  nome: 'Granito - variedade B - 2 cm',
  unidade: UnidadeCobranca.m2,
  precoReferencia: Dinheiro(30000),
);

/// Madeira de exemplo (m³, R$ 3.500,00), do exemplo A do prompt §9.
const Material madeiraExemplo = Material(
  id: 'material-madeira',
  nome: 'Madeira - espécie A',
  unidade: UnidadeCobranca.m3,
  precoReferencia: Dinheiro(350000),
);

/// MDF de exemplo (m², R$ 90,00), do exemplo B do prompt §9.
const Material mdfExemplo = Material(
  id: 'material-mdf',
  nome: 'MDF 15 mm',
  unidade: UnidadeCobranca.m2,
  precoReferencia: Dinheiro(9000),
);

/// Materiais de exemplo dos dados de debug (D-17): um de cada unidade.
const List<Material> materiaisExemplo = [
  granitoExemplo,
  madeiraExemplo,
  mdfExemplo,
];
