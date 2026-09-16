import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Acesso unico a base de dados SQLite local.
/// Todos os dados ficam no computador, sem necessidade de internet.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;
  String? _rootDir;

  /// Pasta base da aplicacao (base de dados + documentos dos funcionarios).
  Future<String> get rootDir async {
    if (_rootDir != null) return _rootDir!;
    final docs = await getApplicationSupportDirectory();
    final dir = Directory(p.join(docs.path, 'RH Lider'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _rootDir = dir.path;
    return _rootDir!;
  }

  /// Pasta onde sao guardadas as copias dos documentos anexados.
  Future<Directory> documentosDir() async {
    final root = await rootDir;
    final dir = Directory(p.join(root, 'documentos'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final root = await rootDir;
    final path = p.join(root, 'rh_lider.db');

    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (d) async {
          await d.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (d, version) async {
          await _createSchema(d);
        },
      ),
    );
  }

  Future<void> _createSchema(Database d) async {
    // Dados da empresa. Apenas uma linha (id = 1).
    await d.execute('''
      CREATE TABLE empresa (
        id            INTEGER PRIMARY KEY CHECK (id = 1),
        nome          TEXT NOT NULL,
        nif           TEXT,
        endereco      TEXT,
        telefone      TEXT,
        email         TEXT,
        senha_hash    TEXT NOT NULL,
        senha_salt    TEXT NOT NULL,
        moeda         TEXT NOT NULL DEFAULT 'AOA',
        criado_em     TEXT NOT NULL
      )
    ''');

    // Utilizadores que acedem ao sistema.
    await d.execute('''
      CREATE TABLE usuarios (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        nome          TEXT NOT NULL,
        username      TEXT NOT NULL UNIQUE,
        senha_hash    TEXT NOT NULL,
        senha_salt    TEXT NOT NULL,
        perfil        TEXT NOT NULL DEFAULT 'operador',
        ativo         INTEGER NOT NULL DEFAULT 1,
        criado_em     TEXT NOT NULL
      )
    ''');

    // Funcionarios da empresa.
    await d.execute('''
      CREATE TABLE funcionarios (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo            TEXT NOT NULL UNIQUE,
        nome              TEXT NOT NULL,
        bi                TEXT,
        data_nascimento   TEXT,
        genero            TEXT,
        telefone          TEXT,
        email             TEXT,
        endereco          TEXT,
        cargo             TEXT,
        departamento      TEXT,
        data_admissao     TEXT,
        data_saida        TEXT,
        salario_base      REAL NOT NULL DEFAULT 0,
        iban              TEXT,
        seguranca_social  TEXT,
        estado            TEXT NOT NULL DEFAULT 'activo',
        observacoes       TEXT,
        criado_em         TEXT NOT NULL,
        actualizado_em    TEXT
      )
    ''');
    await d.execute(
        'CREATE INDEX idx_funcionarios_nome ON funcionarios (nome)');
    await d.execute(
        'CREATE INDEX idx_funcionarios_estado ON funcionarios (estado)');

    // Documentos anexados a cada funcionario.
    await d.execute('''
      CREATE TABLE documentos (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        funcionario_id  INTEGER NOT NULL,
        tipo            TEXT NOT NULL,
        titulo          TEXT NOT NULL,
        ficheiro_nome   TEXT NOT NULL,
        caminho         TEXT NOT NULL,
        data_emissao    TEXT,
        data_validade   TEXT,
        observacao      TEXT,
        criado_em       TEXT NOT NULL,
        FOREIGN KEY (funcionario_id) REFERENCES funcionarios (id)
          ON DELETE CASCADE
      )
    ''');
    await d.execute(
        'CREATE INDEX idx_documentos_func ON documentos (funcionario_id)');

    // Presencas diarias. Um registo por funcionario por dia.
    await d.execute('''
      CREATE TABLE presencas (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        funcionario_id  INTEGER NOT NULL,
        data            TEXT NOT NULL,
        estado          TEXT NOT NULL,
        horas           REAL NOT NULL DEFAULT 0,
        observacao      TEXT,
        registado_em    TEXT NOT NULL,
        UNIQUE (funcionario_id, data),
        FOREIGN KEY (funcionario_id) REFERENCES funcionarios (id)
          ON DELETE CASCADE
      )
    ''');
    await d.execute('CREATE INDEX idx_presencas_data ON presencas (data)');

    // Pagamentos mensais. Um registo por funcionario por mes.
    await d.execute('''
      CREATE TABLE pagamentos (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        funcionario_id      INTEGER NOT NULL,
        ano                 INTEGER NOT NULL,
        mes                 INTEGER NOT NULL,
        salario_base        REAL NOT NULL DEFAULT 0,
        subsidios           REAL NOT NULL DEFAULT 0,
        bonus               REAL NOT NULL DEFAULT 0,
        horas_extra         REAL NOT NULL DEFAULT 0,
        desconto_faltas     REAL NOT NULL DEFAULT 0,
        adiantamentos       REAL NOT NULL DEFAULT 0,
        outros_descontos    REAL NOT NULL DEFAULT 0,
        liquido             REAL NOT NULL DEFAULT 0,
        estado              TEXT NOT NULL DEFAULT 'pendente',
        metodo              TEXT,
        data_pagamento      TEXT,
        observacao          TEXT,
        criado_em           TEXT NOT NULL,
        actualizado_em      TEXT,
        UNIQUE (funcionario_id, ano, mes),
        FOREIGN KEY (funcionario_id) REFERENCES funcionarios (id)
          ON DELETE CASCADE
      )
    ''');
    await d.execute(
        'CREATE INDEX idx_pagamentos_periodo ON pagamentos (ano, mes)');

    // Registo de actividade do sistema.
    await d.execute('''
      CREATE TABLE actividade (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario     TEXT,
        accao       TEXT NOT NULL,
        detalhe     TEXT,
        criado_em   TEXT NOT NULL
      )
    ''');
  }

  Future<void> registarActividade(
    String? usuario,
    String accao, [
    String? detalhe,
  ]) async {
    final d = await db;
    await d.insert('actividade', {
      'usuario': usuario,
      'accao': accao,
      'detalhe': detalhe,
      'criado_em': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> empresaConfigurada() async {
    final d = await db;
    final r = await d.query('empresa', limit: 1);
    return r.isNotEmpty;
  }

  Future<void> fechar() async {
    await _db?.close();
    _db = null;
  }
}
