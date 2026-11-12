import 'package:sqflite/sqflite.dart';

// Esquema do banco SQLite do app (D-27). Versão do esquema separada da
// `versaoCalculo` da `CalculadoraOrcamento`.
//
// Convenções das colunas:
// - dinheiro em centavos (`INTEGER`);
// - medidas em centésimos de cm (`INTEGER`, sem perda);
// - datas em microssegundos desde a época, no fuso local (`INTEGER`);
// - enums pelo nome (`TEXT`);
// - booleanos em 0 ou 1.
//
// Excluir um orçamento exclui itens e peças (cascata) e tira o vínculo das
// tarefas (`SET NULL`), nunca materiais nem clientes.
//
// Toda mudança de esquema é uma nova versão, com a migração em
// `migrarEsquema`.

/// Versão atual do esquema.
const int versaoEsquema = 2;

/// Liga as chaves estrangeiras, que o SQLite deixa desligadas por padrão.
/// Sem isso, excluir um orçamento não exclui itens e peças.
Future<void> configurarConexao(Database banco) =>
    banco.execute('PRAGMA foreign_keys = ON');

/// Cria o esquema completo na [versao] atual (banco novo).
Future<void> criarEsquema(Database banco, int versao) async {
  final lote = banco.batch();
  [..._tabelasV1, ..._tabelasV2].forEach(lote.execute);
  await lote.commit(noResult: true);
}

/// Migra o esquema de [de] para [para]. Cada versão nova acrescenta um
/// passo aqui.
Future<void> migrarEsquema(Database banco, int de, int para) async {
  if (de < 2) {
    final lote = banco.batch();
    _tabelasV2.forEach(lote.execute);
    await lote.commit(noResult: true);
  }
}

/// Versão 2: preferências do aparelho, como o tema escolhido (D-45).
const List<String> _tabelasV2 = [
  '''
CREATE TABLE preferencias (
  chave TEXT PRIMARY KEY,
  valor TEXT NOT NULL
)''',
];

const String _colunasEndereco = '''
  logradouro TEXT NOT NULL,
  numero TEXT NOT NULL,
  bairro TEXT NOT NULL,
  cidade TEXT NOT NULL,
  uf TEXT NOT NULL,
  cep TEXT,
  complemento TEXT''';

const List<String> _tabelasV1 = [
  '''
CREATE TABLE materiais (
  id TEXT PRIMARY KEY,
  nome TEXT NOT NULL,
  unidade TEXT NOT NULL,
  preco_referencia INTEGER NOT NULL,
  ativo INTEGER NOT NULL DEFAULT 1
)''',
  '''
CREATE TABLE empresa (
  id TEXT PRIMARY KEY,
  nome_razao_social TEXT NOT NULL,
  documento TEXT NOT NULL,
  telefone TEXT NOT NULL,
  email TEXT,
$_colunasEndereco
)''',
  '''
CREATE TABLE clientes (
  id TEXT PRIMARY KEY,
  nome TEXT NOT NULL,
  documento TEXT NOT NULL UNIQUE,
  celular TEXT NOT NULL,
$_colunasEndereco
)''',
  '''
CREATE TABLE orcamentos (
  id TEXT PRIMARY KEY,
  codigo TEXT NOT NULL UNIQUE,
  revisao INTEGER NOT NULL,
  chave_finalizacao TEXT NOT NULL UNIQUE,
  criado_em INTEGER NOT NULL,
  atualizado_em INTEGER NOT NULL,
  enviado_em INTEGER,
  status TEXT NOT NULL,
  cliente_json TEXT NOT NULL,
  emitente_json TEXT NOT NULL,
  insumos INTEGER NOT NULL,
  impostos INTEGER NOT NULL,
  combustivel INTEGER NOT NULL,
  outros INTEGER NOT NULL,
  outros_descricao TEXT,
  desconto INTEGER NOT NULL,
  validade_dias INTEGER,
  observacoes TEXT,
  totais_json TEXT NOT NULL,
  versao_calculo INTEGER NOT NULL
)''',
  'CREATE INDEX orcamentos_atualizado_em ON orcamentos (atualizado_em)',
  '''
CREATE TABLE itens_orcamento (
  id TEXT PRIMARY KEY,
  orcamento_id TEXT NOT NULL
    REFERENCES orcamentos (id) ON DELETE CASCADE,
  ordem INTEGER NOT NULL,
  descricao TEXT NOT NULL,
  quantidade_produtos INTEGER NOT NULL,
  preco_base INTEGER NOT NULL,
  observacoes TEXT
)''',
  'CREATE INDEX itens_orcamento_orcamento ON itens_orcamento (orcamento_id)',
  '''
CREATE TABLE pecas_orcamento (
  id TEXT PRIMARY KEY,
  item_id TEXT NOT NULL
    REFERENCES itens_orcamento (id) ON DELETE CASCADE,
  ordem INTEGER NOT NULL,
  descricao TEXT NOT NULL,
  quantidade_por_produto INTEGER NOT NULL,
  material_nome TEXT NOT NULL,
  material_unidade TEXT NOT NULL,
  material_preco_referencia_copiado INTEGER NOT NULL,
  material_preco_aplicado INTEGER NOT NULL,
  material_origem_id TEXT,
  comprimento INTEGER NOT NULL,
  largura INTEGER NOT NULL,
  espessura INTEGER,
  observacoes TEXT
)''',
  'CREATE INDEX pecas_orcamento_item ON pecas_orcamento (item_id, ordem)',
  '''
CREATE TABLE sequencias (
  dia TEXT PRIMARY KEY,
  ultima INTEGER NOT NULL
)''',
  '''
CREATE TABLE tarefas (
  id TEXT PRIMARY KEY,
  titulo TEXT NOT NULL,
  data INTEGER NOT NULL,
  tipo TEXT NOT NULL,
  concluida INTEGER NOT NULL DEFAULT 0,
  descricao TEXT,
  orcamento_id TEXT REFERENCES orcamentos (id) ON DELETE SET NULL
)''',
];
