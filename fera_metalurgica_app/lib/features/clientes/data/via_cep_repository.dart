import 'dart:convert';
import 'dart:io';

import 'package:fera_metalurgica_app/features/clientes/domain/cep_repository.dart';
import 'package:fera_metalurgica_app/features/clientes/domain/endereco_encontrado.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'via_cep_repository.g.dart';

/// Baixa o texto de [uri].
typedef BaixarTexto = Future<String> Function(Uri uri);

/// Tempo máximo de espera do serviço de CEP.
const Duration _limite = Duration(seconds: 5);

/// [CepRepository] no ViaCEP (viacep.com.br): gratuito e sem chave.
class ViaCepRepository implements CepRepository {
  /// Cria o repositório. A função que baixa só é trocada nos testes.
  const ViaCepRepository([this._baixar = _baixarDaInternet]);

  final BaixarTexto _baixar;

  @override
  Future<EnderecoEncontrado?> buscar(String cep) async {
    final corpo = await _baixar(Uri.https('viacep.com.br', '/ws/$cep/json/'));
    final json = jsonDecode(corpo) as Map<String, dynamic>;
    // CEP bem formado, mas inexistente: `{"erro": true}`.
    if (json.containsKey('erro')) return null;
    return EnderecoEncontrado.fromJson(json);
  }

  static Future<String> _baixarDaInternet(Uri uri) async {
    final cliente = HttpClient()..connectionTimeout = _limite;
    try {
      final pedido = await cliente.getUrl(uri);
      final resposta = await pedido.close().timeout(_limite);
      if (resposta.statusCode != HttpStatus.ok) {
        throw HttpException('Resposta ${resposta.statusCode}', uri: uri);
      }
      return await resposta.transform(utf8.decoder).join().timeout(_limite);
    } finally {
      cliente.close(force: true);
    }
  }
}

/// Provider do [CepRepository]; os testes o trocam por um mock.
@riverpod
CepRepository cepRepository(Ref ref) => const ViaCepRepository();
