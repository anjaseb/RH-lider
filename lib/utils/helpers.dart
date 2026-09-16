import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

/// Funcoes de apoio: senhas, datas e valores monetarios.

class Seguranca {
  static final Random _random = Random.secure();

  /// Gera um salt aleatorio em base64.
  static String gerarSalt([int bytes = 16]) {
    final valores = List<int>.generate(bytes, (_) => _random.nextInt(256));
    return base64Url.encode(valores);
  }

  /// Calcula o hash da senha usando SHA-256 com salt.
  static String hashSenha(String senha, String salt) {
    final bytes = utf8.encode('$salt|$senha');
    return sha256.convert(bytes).toString();
  }

  static bool verificar(String senha, String salt, String hashGuardado) {
    return hashSenha(senha, salt) == hashGuardado;
  }
}

class Fmt {
  static final DateFormat _iso = DateFormat('yyyy-MM-dd');
  static final DateFormat _humano = DateFormat('dd/MM/yyyy');
  static final DateFormat _humanoHora = DateFormat('dd/MM/yyyy HH:mm');

  static const List<String> meses = [
    'Janeiro',
    'Fevereiro',
    'Marco',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  static String nomeMes(int mes) {
    if (mes < 1 || mes > 12) return '-';
    return meses[mes - 1];
  }

  static String iso(DateTime d) => _iso.format(d);

  static DateTime? paraData(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;
    return DateTime.tryParse(valor);
  }

  /// Converte uma data guardada (YYYY-MM-DD) para o formato dd/MM/yyyy.
  static String data(String? valor) {
    final d = paraData(valor);
    if (d == null) return '-';
    return _humano.format(d);
  }

  static String dataHora(String? valor) {
    final d = paraData(valor);
    if (d == null) return '-';
    return _humanoHora.format(d);
  }

  /// Formata valores monetarios sem simbolo colado ao numero.
  static String dinheiro(num valor, [String moeda = 'AOA']) {
    final f = NumberFormat.currency(
      locale: 'pt_PT',
      symbol: '',
      decimalDigits: 2,
    );
    return '${f.format(valor).trim()} $moeda';
  }

  static String numero(num valor, [int casas = 2]) {
    return NumberFormat.decimalPatternDigits(
      locale: 'pt_PT',
      decimalDigits: casas,
    ).format(valor);
  }

  /// Le um numero escrito com virgula ou ponto decimal.
  static double lerNumero(String? texto) {
    if (texto == null) return 0;
    final limpo = texto.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(limpo) ?? 0;
  }

  /// Numero de dias de um mes.
  static int diasNoMes(int ano, int mes) {
    return DateTime(ano, mes + 1, 0).day;
  }

  static bool fimDeSemana(DateTime d) {
    return d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
  }

  static String diaSemanaCurto(DateTime d) {
    const nomes = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
    return nomes[d.weekday - 1];
  }

  /// Iniciais do nome, usadas no avatar de texto.
  static String iniciais(String nome) {
    final partes =
        nome.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1))
        .toUpperCase();
  }
}
