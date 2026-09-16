import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../data/database.dart';
import '../models/models.dart';
import '../utils/helpers.dart';
import 'auth_service.dart';

/// Operacoes sobre a folha de presencas mensal.
class PresencaService {
  PresencaService._();

  static final PresencaService instance = PresencaService._();

  final AppDatabase _database = AppDatabase.instance;

  String _prefixoMes(int ano, int mes) =>
      '$ano-${mes.toString().padLeft(2, '0')}';

  /// Devolve o mapa funcionarioId -> (dia -> presenca) para o mes indicado.
  Future<Map<int, Map<int, Presenca>>> folhaDoMes(int ano, int mes) async {
    final d = await _database.db;
    final linhas = await d.query(
      'presencas',
      where: 'data LIKE ?',
      whereArgs: ['${_prefixoMes(ano, mes)}-%'],
    );

    final mapa = <int, Map<int, Presenca>>{};
    for (final linha in linhas) {
      final presenca = Presenca.fromMap(linha);
      final dia = int.tryParse(presenca.data.split('-').last);
      if (dia == null) continue;
      mapa.putIfAbsent(presenca.funcionarioId, () => {})[dia] = presenca;
    }
    return mapa;
  }

  /// Regista ou actualiza a presenca de um funcionario num dia.
  Future<void> marcar({
    required int funcionarioId,
    required DateTime dia,
    required String estado,
    double horas = 0,
    String? observacao,
  }) async {
    final d = await _database.db;
    await d.insert(
      'presencas',
      {
        'funcionario_id': funcionarioId,
        'data': Fmt.iso(dia),
        'estado': estado,
        'horas': horas,
        'observacao': observacao,
        'registado_em': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> limpar({
    required int funcionarioId,
    required DateTime dia,
  }) async {
    final d = await _database.db;
    await d.delete(
      'presencas',
      where: 'funcionario_id = ? AND data = ?',
      whereArgs: [funcionarioId, Fmt.iso(dia)],
    );
  }

  /// Marca todos os dias uteis do mes como presentes, sem apagar o que ja existe.
  Future<int> preencherDiasUteis(int ano, int mes,
      {required List<int> funcionarioIds, double horas = 8}) async {
    final d = await _database.db;
    final dias = Fmt.diasNoMes(ano, mes);
    final agora = DateTime.now().toIso8601String();
    var criados = 0;

    final existentes = await folhaDoMes(ano, mes);

    await d.transaction((txn) async {
      for (final id in funcionarioIds) {
        final jaMarcados = existentes[id] ?? {};
        for (var dia = 1; dia <= dias; dia++) {
          if (jaMarcados.containsKey(dia)) continue;
          final data = DateTime(ano, mes, dia);
          if (Fmt.fimDeSemana(data)) continue;
          await txn.insert('presencas', {
            'funcionario_id': id,
            'data': Fmt.iso(data),
            'estado': EstadoPresenca.presente,
            'horas': horas,
            'observacao': null,
            'registado_em': agora,
          });
          criados++;
        }
      }
    });

    await _database.registarActividade(
      AuthService.instance.usuario?.username,
      'Presencas preenchidas',
      '${Fmt.nomeMes(mes)} $ano',
    );
    return criados;
  }

  /// Apaga todas as presencas do mes para os funcionarios indicados.
  Future<int> limparMes(int ano, int mes, List<int> funcionarioIds) async {
    if (funcionarioIds.isEmpty) return 0;
    final d = await _database.db;
    final marcas = List.filled(funcionarioIds.length, '?').join(',');
    final removidos = await d.delete(
      'presencas',
      where: 'data LIKE ? AND funcionario_id IN ($marcas)',
      whereArgs: ['${_prefixoMes(ano, mes)}-%', ...funcionarioIds],
    );
    return removidos;
  }

  /// Contagem por estado de um funcionario num mes.
  Future<Map<String, int>> resumoFuncionario(
      int funcionarioId, int ano, int mes) async {
    final d = await _database.db;
    final linhas = await d.rawQuery(
      'SELECT estado, COUNT(*) AS total FROM presencas '
      'WHERE funcionario_id = ? AND data LIKE ? GROUP BY estado',
      [funcionarioId, '${_prefixoMes(ano, mes)}-%'],
    );
    final mapa = <String, int>{for (final e in EstadoPresenca.todos) e: 0};
    for (final linha in linhas) {
      mapa[linha['estado'] as String] = (linha['total'] as int?) ?? 0;
    }
    return mapa;
  }

  /// Contagem por estado de todos os funcionarios num mes.
  Future<Map<int, Map<String, int>>> resumoMes(int ano, int mes) async {
    final d = await _database.db;
    final linhas = await d.rawQuery(
      'SELECT funcionario_id, estado, COUNT(*) AS total FROM presencas '
      'WHERE data LIKE ? GROUP BY funcionario_id, estado',
      ['${_prefixoMes(ano, mes)}-%'],
    );
    final mapa = <int, Map<String, int>>{};
    for (final linha in linhas) {
      final id = linha['funcionario_id'] as int;
      mapa.putIfAbsent(
          id, () => {for (final e in EstadoPresenca.todos) e: 0});
      mapa[id]![linha['estado'] as String] = (linha['total'] as int?) ?? 0;
    }
    return mapa;
  }

  /// Total de horas registadas por funcionario no mes.
  Future<Map<int, double>> horasMes(int ano, int mes) async {
    final d = await _database.db;
    final linhas = await d.rawQuery(
      'SELECT funcionario_id, SUM(horas) AS total FROM presencas '
      'WHERE data LIKE ? GROUP BY funcionario_id',
      ['${_prefixoMes(ano, mes)}-%'],
    );
    return {
      for (final linha in linhas)
        linha['funcionario_id'] as int:
            ((linha['total'] as num?) ?? 0).toDouble(),
    };
  }

  /// Presencas registadas hoje, por estado.
  Future<Map<String, int>> resumoHoje() async {
    final d = await _database.db;
    final linhas = await d.rawQuery(
      'SELECT estado, COUNT(*) AS total FROM presencas '
      'WHERE data = ? GROUP BY estado',
      [Fmt.iso(DateTime.now())],
    );
    final mapa = <String, int>{for (final e in EstadoPresenca.todos) e: 0};
    for (final linha in linhas) {
      mapa[linha['estado'] as String] = (linha['total'] as int?) ?? 0;
    }
    return mapa;
  }
}
