import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/database.dart';
import '../models/models.dart';
import 'auth_service.dart';

/// Operacoes sobre funcionarios e respectivos documentos.
class FuncionarioService {
  FuncionarioService._();

  static final FuncionarioService instance = FuncionarioService._();

  final AppDatabase _database = AppDatabase.instance;

  /// Gera o proximo codigo de identificacao (FUNC-0001, FUNC-0002, ...).
  Future<String> proximoCodigo() async {
    final d = await _database.db;
    final linhas = await d.rawQuery(
      "SELECT codigo FROM funcionarios WHERE codigo LIKE 'FUNC-%' "
      'ORDER BY id DESC LIMIT 50',
    );
    var maior = 0;
    for (final linha in linhas) {
      final codigo = linha['codigo'] as String;
      final numero = int.tryParse(codigo.replaceAll('FUNC-', ''));
      if (numero != null && numero > maior) maior = numero;
    }
    return 'FUNC-${(maior + 1).toString().padLeft(4, '0')}';
  }

  Future<List<Funcionario>> listar({
    String pesquisa = '',
    String estado = 'todos',
  }) async {
    final d = await _database.db;
    final condicoes = <String>[];
    final args = <Object?>[];

    if (estado != 'todos') {
      condicoes.add('estado = ?');
      args.add(estado);
    }
    if (pesquisa.trim().isNotEmpty) {
      condicoes.add(
          '(nome LIKE ? OR codigo LIKE ? OR bi LIKE ? OR cargo LIKE ? OR telefone LIKE ?)');
      final termo = '%${pesquisa.trim()}%';
      args.addAll([termo, termo, termo, termo, termo]);
    }

    final linhas = await d.query(
      'funcionarios',
      where: condicoes.isEmpty ? null : condicoes.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'nome COLLATE NOCASE',
    );
    return linhas.map(Funcionario.fromMap).toList();
  }

  Future<List<Funcionario>> listarActivos() => listar(estado: 'activo');

  Future<Funcionario?> obter(int id) async {
    final d = await _database.db;
    final linhas =
        await d.query('funcionarios', where: 'id = ?', whereArgs: [id], limit: 1);
    if (linhas.isEmpty) return null;
    return Funcionario.fromMap(linhas.first);
  }

  Future<Resultado> guardar(Funcionario f) async {
    if (f.nome.trim().isEmpty) {
      return const Resultado.falha('Indique o nome do funcionario.');
    }
    if (f.codigo.trim().isEmpty) {
      return const Resultado.falha('Indique o codigo do funcionario.');
    }

    final d = await _database.db;
    final duplicado = await d.query(
      'funcionarios',
      where: f.id == null ? 'codigo = ?' : 'codigo = ? AND id <> ?',
      whereArgs: f.id == null ? [f.codigo.trim()] : [f.codigo.trim(), f.id],
      limit: 1,
    );
    if (duplicado.isNotEmpty) {
      return const Resultado.falha('Ja existe um funcionario com esse codigo.');
    }

    final agora = DateTime.now().toIso8601String();
    final dados = f.toMap();

    if (f.id == null) {
      dados['criado_em'] = agora;
      dados['actualizado_em'] = agora;
      await d.insert('funcionarios', dados);
      await _database.registarActividade(
          AuthService.instance.usuario?.username,
          'Funcionario registado',
          f.nome);
    } else {
      dados['actualizado_em'] = agora;
      await d.update('funcionarios', dados,
          where: 'id = ?', whereArgs: [f.id]);
      await _database.registarActividade(
          AuthService.instance.usuario?.username,
          'Funcionario actualizado',
          f.nome);
    }
    return const Resultado.sucesso();
  }

  /// Elimina o funcionario, as presencas, pagamentos e ficheiros anexados.
  Future<Resultado> eliminar(int id) async {
    final d = await _database.db;
    final docs = await d.query('documentos',
        where: 'funcionario_id = ?', whereArgs: [id]);
    for (final doc in docs) {
      final ficheiro = File(doc['caminho'] as String);
      if (await ficheiro.exists()) {
        try {
          await ficheiro.delete();
        } on FileSystemException {
          // Se o ficheiro estiver aberto noutro programa, ignora-se.
        }
      }
    }
    await d.delete('funcionarios', where: 'id = ?', whereArgs: [id]);
    await _database.registarActividade(
        AuthService.instance.usuario?.username,
        'Funcionario eliminado',
        'id=$id');
    return const Resultado.sucesso();
  }

  Future<Map<String, int>> contagens() async {
    final d = await _database.db;
    final linhas = await d.rawQuery(
        'SELECT estado, COUNT(*) AS total FROM funcionarios GROUP BY estado');
    final mapa = <String, int>{
      'activo': 0,
      'suspenso': 0,
      'inactivo': 0,
      'total': 0,
    };
    for (final linha in linhas) {
      final estado = linha['estado'] as String;
      final total = (linha['total'] as int?) ?? 0;
      mapa[estado] = total;
      mapa['total'] = (mapa['total'] ?? 0) + total;
    }
    return mapa;
  }

  Future<double> totalSalarios() async {
    final d = await _database.db;
    final linhas = await d.rawQuery(
      "SELECT SUM(salario_base) AS total FROM funcionarios WHERE estado = 'activo'",
    );
    return ((linhas.first['total'] as num?) ?? 0).toDouble();
  }

  // ------------------------------------------------------------- documentos

  Future<List<Documento>> documentos(int funcionarioId) async {
    final d = await _database.db;
    final linhas = await d.query(
      'documentos',
      where: 'funcionario_id = ?',
      whereArgs: [funcionarioId],
      orderBy: 'criado_em DESC',
    );
    return linhas.map(Documento.fromMap).toList();
  }

  /// Copia o ficheiro para a pasta da aplicacao e regista-o na base de dados.
  Future<Resultado> anexarDocumento({
    required int funcionarioId,
    required String caminhoOrigem,
    required String tipo,
    required String titulo,
    String? dataEmissao,
    String? dataValidade,
    String? observacao,
  }) async {
    final origem = File(caminhoOrigem);
    if (!await origem.exists()) {
      return const Resultado.falha('O ficheiro seleccionado nao foi encontrado.');
    }

    final dir = await _database.documentosDir();
    final pastaFuncionario =
        Directory(p.join(dir.path, funcionarioId.toString()));
    if (!await pastaFuncionario.exists()) {
      await pastaFuncionario.create(recursive: true);
    }

    final nomeOriginal = p.basename(caminhoOrigem);
    final extensao = p.extension(nomeOriginal);
    final base = p.basenameWithoutExtension(nomeOriginal);
    final carimbo = DateTime.now().millisecondsSinceEpoch;
    final destino = p.join(pastaFuncionario.path, '${base}_$carimbo$extensao');

    try {
      await origem.copy(destino);
    } on FileSystemException catch (e) {
      return Resultado.falha('Nao foi possivel copiar o ficheiro: ${e.message}');
    }

    final d = await _database.db;
    await d.insert('documentos', {
      'funcionario_id': funcionarioId,
      'tipo': tipo,
      'titulo': titulo.trim().isEmpty ? nomeOriginal : titulo.trim(),
      'ficheiro_nome': nomeOriginal,
      'caminho': destino,
      'data_emissao': dataEmissao,
      'data_validade': dataValidade,
      'observacao': observacao,
      'criado_em': DateTime.now().toIso8601String(),
    });

    await _database.registarActividade(
        AuthService.instance.usuario?.username, 'Documento anexado', titulo);
    return const Resultado.sucesso();
  }

  Future<Resultado> eliminarDocumento(Documento doc) async {
    final ficheiro = File(doc.caminho);
    if (await ficheiro.exists()) {
      try {
        await ficheiro.delete();
      } on FileSystemException {
        // Ignora-se se o ficheiro nao puder ser removido.
      }
    }
    final d = await _database.db;
    await d.delete('documentos', where: 'id = ?', whereArgs: [doc.id]);
    return const Resultado.sucesso();
  }

  /// Abre o documento no programa predefinido do sistema operativo.
  Future<Resultado> abrirDocumento(Documento doc) async {
    final ficheiro = File(doc.caminho);
    if (!await ficheiro.exists()) {
      return const Resultado.falha('O ficheiro ja nao existe no disco.');
    }
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', doc.caminho]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [doc.caminho]);
      } else {
        await Process.run('xdg-open', [doc.caminho]);
      }
      return const Resultado.sucesso();
    } on ProcessException catch (e) {
      return Resultado.falha('Nao foi possivel abrir o ficheiro: ${e.message}');
    }
  }

  /// Documentos cuja validade termina nos proximos [dias] dias.
  Future<List<Map<String, Object?>>> documentosAExpirar({int dias = 60}) async {
    final d = await _database.db;
    final hoje = DateTime.now();
    final limite = hoje.add(Duration(days: dias));
    return d.rawQuery(
      '''
      SELECT d.titulo, d.tipo, d.data_validade, f.nome AS funcionario
      FROM documentos d
      JOIN funcionarios f ON f.id = d.funcionario_id
      WHERE d.data_validade IS NOT NULL
        AND d.data_validade <> ''
        AND d.data_validade <= ?
      ORDER BY d.data_validade ASC
      LIMIT 20
      ''',
      [limite.toIso8601String().substring(0, 10)],
    );
  }
}
