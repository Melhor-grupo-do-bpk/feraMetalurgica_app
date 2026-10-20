import 'package:fera_metalurgica_app/features/catalogo/domain/produto_catalogo.dart';

/// Produtos de exemplo, com nomes e descrições da tela "Catálogo de
/// Produtos" do Figma. As categorias não aparecem no Figma e são
/// provisórias. As fotos ficam em `assets/images/catalogo/<id>.jpg` (D-18).
const List<ProdutoCatalogo> catalogoSeed = [
  ProdutoCatalogo(
    id: 'produto-portao-basculante',
    nome: 'Portão Basculante',
    categoria: 'Portões',
    descricaoTecnica:
        'Sistema de abertura vertical otimizado para espaços reduzidos. '
        'Fabricado em aço galvanizado de alta resistência com contrapesos '
        'embutidos.',
    fotoPath: 'assets/images/catalogo/produto-portao-basculante.jpg',
  ),
  ProdutoCatalogo(
    id: 'produto-estrutura-trelicada',
    nome: 'Estrutura Treliçada',
    categoria: 'Estruturas',
    descricaoTecnica:
        'Vigas em treliça ideais para grandes vãos livres. Proporciona '
        'excelente relação peso-resistência para galpões e coberturas '
        'industriais.',
    fotoPath: 'assets/images/catalogo/produto-estrutura-trelicada.jpg',
  ),
  ProdutoCatalogo(
    id: 'produto-grade-protecao-pesada',
    nome: 'Grade de Proteção Pesada',
    categoria: 'Grades',
    descricaoTecnica:
        'Módulos de gradeamento para segurança perimetral de alto nível. '
        'Solda MIG contínua e pintura eletrostática texturizada.',
    fotoPath: 'assets/images/catalogo/produto-grade-protecao-pesada.jpg',
  ),
];
