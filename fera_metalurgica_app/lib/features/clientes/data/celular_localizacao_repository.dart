import 'package:fera_metalurgica_app/core/utils/texto_busca.dart';
import 'package:fera_metalurgica_app/core/utils/validators.dart';
import 'package:fera_metalurgica_app/features/clientes/domain/endereco_encontrado.dart';
import 'package:fera_metalurgica_app/features/clientes/domain/localizacao_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'celular_localizacao_repository.g.dart';

/// Lugar em que o aparelho está, ou `null` se não houver endereço para ele.
typedef ObterLugar = Future<Placemark?> Function();

/// Tempo máximo de espera do GPS.
const Duration _limiteGps = Duration(seconds: 15);

/// Sigla de cada UF pelo nome normalizado.
const Map<String, String> _ufs = {
  'acre': 'AC',
  'alagoas': 'AL',
  'amapa': 'AP',
  'amazonas': 'AM',
  'bahia': 'BA',
  'ceara': 'CE',
  'distrito federal': 'DF',
  'federal district': 'DF',
  'espirito santo': 'ES',
  'goias': 'GO',
  'maranhao': 'MA',
  'mato grosso': 'MT',
  'mato grosso do sul': 'MS',
  'minas gerais': 'MG',
  'para': 'PA',
  'paraiba': 'PB',
  'parana': 'PR',
  'pernambuco': 'PE',
  'piaui': 'PI',
  'rio de janeiro': 'RJ',
  'rio grande do norte': 'RN',
  'rio grande do sul': 'RS',
  'rondonia': 'RO',
  'roraima': 'RR',
  'santa catarina': 'SC',
  'sao paulo': 'SP',
  'sergipe': 'SE',
  'tocantins': 'TO',
};

final RegExp _prefixoEstado = RegExp(r'^(estado d[eoa]|state of)\s+');
final RegExp _sigla = RegExp(r'^[A-Z]{2}$');

/// Sigla da UF em [area], que o celular devolve como sigla ou como nome
/// (ex: `Rio Grande do Sul`, `State of São Paulo`). Vazio se não reconhecer.
String _siglaDaUf(String area) {
  final texto = area.trim();
  if (_sigla.hasMatch(texto)) return texto;
  final nome = normalizarParaBusca(texto).replaceFirst(_prefixoEstado, '');
  return _ufs[nome] ?? '';
}

/// [LocalizacaoRepository] com o GPS e o geocodificador do próprio celular:
/// gratuito e sem chave. As coordenadas passam pelo serviço do sistema.
class CelularLocalizacaoRepository implements LocalizacaoRepository {
  /// Cria o repositório. A função que obtém o lugar só é trocada nos testes.
  const CelularLocalizacaoRepository([this._obterLugar = _lugarDoCelular]);

  final ObterLugar _obterLugar;

  @override
  Future<EnderecoEncontrado> enderecoAtual() async {
    final lugar = await _obterLugar();
    final logradouro = lugar?.thoroughfare?.trim() ?? '';
    final local = lugar?.locality?.trim() ?? '';
    final cidade = local.isEmpty
        ? lugar?.subAdministrativeArea?.trim() ?? ''
        : local;
    if (logradouro.isEmpty && cidade.isEmpty) {
      throw const FalhaLocalizacao(MotivoFalhaLocalizacao.semEndereco);
    }
    // Um CEP parcial (ex: `90010`) não serve para o formulário.
    final cep = somenteDigitos(lugar?.postalCode ?? '');
    return EnderecoEncontrado(
      cidade: cidade,
      uf: _siglaDaUf(lugar?.administrativeArea ?? ''),
      logradouro: logradouro,
      bairro: lugar?.subLocality?.trim() ?? '',
      cep: cep.length == 8 ? cep : '',
    );
  }

  static Future<Placemark?> _lugarDoCelular() async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw const FalhaLocalizacao(MotivoFalhaLocalizacao.indisponivel);
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const FalhaLocalizacao(MotivoFalhaLocalizacao.gpsDesligado);
    }
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      throw const FalhaLocalizacao(MotivoFalhaLocalizacao.semPermissao);
    }
    final posicao = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: _limiteGps,
      ),
    );
    final lugares = await Geocoding(
      locale: const Locale('pt', 'BR'),
    ).placemarkFromCoordinates(posicao.latitude, posicao.longitude);
    return lugares.firstOrNull;
  }
}

/// Provider do [LocalizacaoRepository]; os testes o trocam por um mock.
@riverpod
LocalizacaoRepository localizacaoRepository(Ref ref) =>
    const CelularLocalizacaoRepository();
