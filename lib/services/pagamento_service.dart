import '../data/database.dart';
import '../models/models.dart';
import '../utils/helpers.dart';
import 'auth_service.dart';
import 'presenca_service.dart';

/// Operacoes sobre a folha de pagamentos mensal.
class PagamentoService {
  PagamentoService._();

  static final PagamentoService instance = PagamentoService._();

  final AppDatabase _database = AppDatabase.instance;

  Future<List<Pagamento>> doMes(int ano, int mes) async {
    final d = await _database.db;
    final linhas = await d.query(
      'pagamentos',
      where: 'ano = ? AND mes = ?',
      whereArgs: [ano, mes],
    );
    return linhas.map(Pagamento.fromMap).toList();
  }

  Future<Map<int, Pagamento>> doMesPorFuncionario(int ano, int mes) async {
    final lista = await doMes(ano, mes);
    return {for (final p in lista) p.funcionarioId: p};
  }

  Future<Pagamento?> obter(int funcionarioId, int ano, int mes) async {
    final d = await _database.db;
    final linhas = await d.query(
      'pagamentos',
      where: 'funcionario_id = ? AND ano = ? AND mes = ?',
      whereArgs: [funcionarioId, ano, mes],
      limit: 1,
    );
    if (linhas.isEmpty) return null;
    return Pagamento.fromMap(linhas.first);
  }

  /// Historico de pagamentos de um funcionario.
  Future<List<Pagamento>> historico(int funcionarioId) async {
    final d = await _database.db;
    final linhas = await d.query(
      'pagamentos',
      where: 'funcionario_id = ?',
      whereArgs: [funcionarioId],
      orderBy: 'ano DESC, mes DESC',
    );
    return linhas.map(Pagamento.fromMap).toList();
  }

  Future<Resultado> guardar(Pagamento p) async {
    final d = await _database.db;
    final agora = DateTime.now().toIso8601String();
    final dados = p.toMap();
    dados['liquido'] = p.calculado;

    final existente = await obter(p.funcionarioId, p.ano, p.mes);
    if (existente == null) {
      dados['criado_em'] = agora;
      dados['actualizado_em'] = agora;
      await d.insert('pagamentos', dados);
    } else {
      dados['actualizado_em'] = agora;
      await d.update(
        'pagamentos',
        dados,
        where: 'funcionario_id = ? AND ano = ? AND mes = ?',
        whereArgs: [p.funcionarioId, p.ano, p.mes],
      );
    }
    return const Resultado.sucesso();
  }

  /// Marca um pagamento como pago ou volta a coloca-lo pendente.
  Future<Resultado> definirEstado({
    required int funcionarioId,
    required int ano,
    required int mes,
    required String estado,
    String? metodo,
  }) async {
    final d = await _database.db;
    final actualizacao = <String, Object?>{
      'estado': estado,
      'actualizado_em': DateTime.now().toIso8601String(),
    };
    if (estado == 'pago') {
      actualizacao['data_pagamento'] = Fmt.iso(DateTime.now());
      if (metodo != null) actualizacao['metodo'] = metodo;
    } else {
      actualizacao['data_pagamento'] = null;
    }

    final alteradas = await d.update(
      'pagamentos',
      actualizacao,
      where: 'funcionario_id = ? AND ano = ? AND mes = ?',
      whereArgs: [funcionarioId, ano, mes],
    );
    if (alteradas == 0) {
      return const Resultado.falha(
          'Ainda nao existe folha de pagamento para este mes.');
    }
    return const Resultado.sucesso();
  }

  /// Cria a folha do mes para os funcionarios activos que ainda nao a tenham.
  /// O desconto por faltas e calculado a partir das presencas registadas.
  Future<int> gerarFolha({
    required int ano,
    required int mes,
    required List<Funcionario> funcionarios,
    bool descontarFaltas = true,
  }) async {
    final d = await _database.db;
    final existentes = await doMesPorFuncionario(ano, mes);
    final resumos = await PresencaService.instance.resumoMes(ano, mes);
    final agora = DateTime.now().toIso8601String();
    final diasUteis = _diasUteisDoMes(ano, mes);
    var criados = 0;

    await d.transaction((txn) async {
      for (final f in funcionarios) {
        if (f.id == null) continue;
        if (existentes.containsKey(f.id)) continue;

        var desconto = 0.0;
        if (descontarFaltas && diasUteis > 0) {
          final faltas = resumos[f.id]?[EstadoPresenca.falta] ?? 0;
          desconto = (f.salarioBase / diasUteis) * faltas;
        }

        final liquido = f.salarioBase - desconto;

        await txn.insert('pagamentos', {
          'funcionario_id': f.id,
          'ano': ano,
          'mes': mes,
          'salario_base': f.salarioBase,
          'subsidios': 0,
          'bonus': 0,
          'horas_extra': 0,
          'desconto_faltas': double.parse(desconto.toStringAsFixed(2)),
          'adiantamentos': 0,
          'outros_descontos': 0,
          'liquido': double.parse(liquido.toStringAsFixed(2)),
          'estado': 'pendente',
          'metodo': null,
          'data_pagamento': null,
          'observacao': null,
          'criado_em': agora,
          'actualizado_em': agora,
        });
        criados++;
      }
    });

    await _database.registarActividade(
      AuthService.instance.usuario?.username,
      'Folha de pagamento gerada',
      '${Fmt.nomeMes(mes)} $ano',
    );
    return criados;
  }

  Future<Resultado> eliminar(int funcionarioId, int ano, int mes) async {
    final d = await _database.db;
    await d.delete(
      'pagamentos',
      where: 'funcionario_id = ? AND ano = ? AND mes = ?',
      whereArgs: [funcionarioId, ano, mes],
    );
    return const Resultado.sucesso();
  }

  /// Totais do mes: valor total, pago e pendente.
  Future<Map<String, double>> totaisDoMes(int ano, int mes) async {
    final d = await _database.db;
    final linhas = await d.rawQuery(
      '''
      SELECT
        COALESCE(SUM(liquido), 0) AS total,
        COALESCE(SUM(CASE WHEN estado = 'pago' THEN liquido ELSE 0 END), 0) AS pago,
        COALESCE(SUM(CASE WHEN estado <> 'pago' THEN liquido ELSE 0 END), 0) AS pendente,
        COUNT(*) AS registos
      FROM pagamentos WHERE ano = ? AND mes = ?
      ''',
      [ano, mes],
    );
    final linha = linhas.first;
    return {
      'total': ((linha['total'] as num?) ?? 0).toDouble(),
      'pago': ((linha['pago'] as num?) ?? 0).toDouble(),
      'pendente': ((linha['pendente'] as num?) ?? 0).toDouble(),
      'registos': ((linha['registos'] as num?) ?? 0).toDouble(),
    };
  }

  /// Evolucao dos ultimos meses, para o painel inicial.
  Future<List<Map<String, Object?>>> evolucao({int meses = 6}) async {
    final d = await _database.db;
    return d.rawQuery(
      '''
      SELECT ano, mes, COALESCE(SUM(liquido), 0) AS total
      FROM pagamentos
      GROUP BY ano, mes
      ORDER BY ano DESC, mes DESC
      LIMIT ?
      ''',
      [meses],
    );
  }

  static int _diasUteisDoMes(int ano, int mes) {
    final dias = Fmt.diasNoMes(ano, mes);
    var total = 0;
    for (var dia = 1; dia <= dias; dia++) {
      if (!Fmt.fimDeSemana(DateTime(ano, mes, dia))) total++;
    }
    return total;
  }
}
