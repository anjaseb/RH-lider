import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../models/models.dart';
import '../utils/helpers.dart';

/// Resultado simples de operacoes que podem falhar com uma mensagem.
class Resultado {
  final bool ok;
  final String? erro;

  const Resultado.sucesso()
      : ok = true,
        erro = null;

  const Resultado.falha(this.erro) : ok = false;
}

/// Gere o estado da sessao: empresa registada e utilizador com sessao iniciada.
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  final AppDatabase _database = AppDatabase.instance;

  Empresa? _empresa;
  Usuario? _usuario;
  bool _carregado = false;

  Empresa? get empresa => _empresa;
  Usuario? get usuario => _usuario;
  bool get carregado => _carregado;
  bool get temEmpresa => _empresa != null;
  bool get autenticado => _usuario != null;
  bool get isAdmin => _usuario?.isAdmin ?? false;
  String get moeda => _empresa?.moeda ?? 'AOA';

  /// Le o estado inicial da base de dados ao arrancar a aplicacao.
  Future<void> iniciar() async {
    final d = await _database.db;
    final linhas = await d.query('empresa', limit: 1);
    if (linhas.isNotEmpty) {
      _empresa = Empresa.fromMap(linhas.first);
    }
    _carregado = true;
    notifyListeners();
  }

  /// Regista a empresa e cria o primeiro utilizador administrador.
  Future<Resultado> registarEmpresa({
    required String nomeEmpresa,
    String? nif,
    String? endereco,
    String? telefone,
    String? email,
    String moeda = 'AOA',
    required String senhaEmpresa,
    required String nomeAdmin,
    required String usernameAdmin,
    required String senhaAdmin,
  }) async {
    if (nomeEmpresa.trim().isEmpty) {
      return const Resultado.falha('Indique o nome da empresa.');
    }
    if (senhaEmpresa.length < 4) {
      return const Resultado.falha(
          'A senha da empresa deve ter pelo menos 4 caracteres.');
    }
    if (usernameAdmin.trim().isEmpty) {
      return const Resultado.falha('Indique o utilizador do administrador.');
    }
    if (senhaAdmin.length < 4) {
      return const Resultado.falha(
          'A senha do administrador deve ter pelo menos 4 caracteres.');
    }

    final d = await _database.db;
    final jaExiste = await d.query('empresa', limit: 1);
    if (jaExiste.isNotEmpty) {
      return const Resultado.falha('Ja existe uma empresa registada.');
    }

    final agora = DateTime.now().toIso8601String();
    final saltEmpresa = Seguranca.gerarSalt();
    final saltAdmin = Seguranca.gerarSalt();

    await d.transaction((txn) async {
      await txn.insert('empresa', {
        'id': 1,
        'nome': nomeEmpresa.trim(),
        'nif': _ouNulo(nif),
        'endereco': _ouNulo(endereco),
        'telefone': _ouNulo(telefone),
        'email': _ouNulo(email),
        'senha_hash': Seguranca.hashSenha(senhaEmpresa, saltEmpresa),
        'senha_salt': saltEmpresa,
        'moeda': moeda,
        'criado_em': agora,
      });

      await txn.insert('usuarios', {
        'nome': nomeAdmin.trim(),
        'username': usernameAdmin.trim().toLowerCase(),
        'senha_hash': Seguranca.hashSenha(senhaAdmin, saltAdmin),
        'senha_salt': saltAdmin,
        'perfil': 'admin',
        'ativo': 1,
        'criado_em': agora,
      });
    });

    final linhas = await d.query('empresa', limit: 1);
    _empresa = Empresa.fromMap(linhas.first);
    await _database.registarActividade(
        usernameAdmin, 'Empresa registada', nomeEmpresa);
    notifyListeners();
    return const Resultado.sucesso();
  }

  /// Inicia sessao validando utilizador e senha.
  Future<Resultado> entrar(String username, String senha) async {
    final d = await _database.db;
    final linhas = await d.query(
      'usuarios',
      where: 'username = ?',
      whereArgs: [username.trim().toLowerCase()],
      limit: 1,
    );

    if (linhas.isEmpty) {
      return const Resultado.falha('Utilizador ou senha incorrectos.');
    }

    final linha = linhas.first;
    final ativo = ((linha['ativo'] as int?) ?? 1) == 1;
    if (!ativo) {
      return const Resultado.falha('Este utilizador esta desactivado.');
    }

    final valido = Seguranca.verificar(
      senha,
      linha['senha_salt'] as String,
      linha['senha_hash'] as String,
    );
    if (!valido) {
      return const Resultado.falha('Utilizador ou senha incorrectos.');
    }

    _usuario = Usuario.fromMap(linha);
    await _database.registarActividade(_usuario!.username, 'Sessao iniciada');
    notifyListeners();
    return const Resultado.sucesso();
  }

  /// Valida a senha geral da empresa (usada em operacoes sensiveis).
  Future<bool> validarSenhaEmpresa(String senha) async {
    final d = await _database.db;
    final linhas = await d.query('empresa', limit: 1);
    if (linhas.isEmpty) return false;
    return Seguranca.verificar(
      senha,
      linhas.first['senha_salt'] as String,
      linhas.first['senha_hash'] as String,
    );
  }

  Future<void> sair() async {
    if (_usuario != null) {
      await _database.registarActividade(_usuario!.username, 'Sessao terminada');
    }
    _usuario = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------- empresa

  Future<Resultado> actualizarEmpresa({
    required String nome,
    String? nif,
    String? endereco,
    String? telefone,
    String? email,
    required String moeda,
  }) async {
    if (nome.trim().isEmpty) {
      return const Resultado.falha('Indique o nome da empresa.');
    }
    final d = await _database.db;
    await d.update(
      'empresa',
      {
        'nome': nome.trim(),
        'nif': _ouNulo(nif),
        'endereco': _ouNulo(endereco),
        'telefone': _ouNulo(telefone),
        'email': _ouNulo(email),
        'moeda': moeda,
      },
      where: 'id = 1',
    );
    final linhas = await d.query('empresa', limit: 1);
    _empresa = Empresa.fromMap(linhas.first);
    notifyListeners();
    return const Resultado.sucesso();
  }

  Future<Resultado> alterarSenhaEmpresa(String actual, String nova) async {
    if (!await validarSenhaEmpresa(actual)) {
      return const Resultado.falha('Senha actual incorrecta.');
    }
    if (nova.length < 4) {
      return const Resultado.falha(
          'A nova senha deve ter pelo menos 4 caracteres.');
    }
    final salt = Seguranca.gerarSalt();
    final d = await _database.db;
    await d.update(
      'empresa',
      {
        'senha_hash': Seguranca.hashSenha(nova, salt),
        'senha_salt': salt,
      },
      where: 'id = 1',
    );
    return const Resultado.sucesso();
  }

  // ------------------------------------------------------------- utilizadores

  Future<List<Usuario>> listarUsuarios() async {
    final d = await _database.db;
    final linhas = await d.query('usuarios', orderBy: 'nome COLLATE NOCASE');
    return linhas.map(Usuario.fromMap).toList();
  }

  Future<Resultado> criarUsuario({
    required String nome,
    required String username,
    required String senha,
    required String perfil,
  }) async {
    if (nome.trim().isEmpty) {
      return const Resultado.falha('Indique o nome do utilizador.');
    }
    if (username.trim().length < 3) {
      return const Resultado.falha(
          'O nome de utilizador deve ter pelo menos 3 caracteres.');
    }
    if (senha.length < 4) {
      return const Resultado.falha(
          'A senha deve ter pelo menos 4 caracteres.');
    }

    final d = await _database.db;
    final existente = await d.query(
      'usuarios',
      where: 'username = ?',
      whereArgs: [username.trim().toLowerCase()],
      limit: 1,
    );
    if (existente.isNotEmpty) {
      return const Resultado.falha('Ja existe um utilizador com esse nome.');
    }

    final salt = Seguranca.gerarSalt();
    await d.insert('usuarios', {
      'nome': nome.trim(),
      'username': username.trim().toLowerCase(),
      'senha_hash': Seguranca.hashSenha(senha, salt),
      'senha_salt': salt,
      'perfil': perfil,
      'ativo': 1,
      'criado_em': DateTime.now().toIso8601String(),
    });
    await _database.registarActividade(
        _usuario?.username, 'Utilizador criado', username);
    return const Resultado.sucesso();
  }

  Future<Resultado> definirEstadoUsuario(int id, bool ativo) async {
    final d = await _database.db;

    if (!ativo) {
      final admins = await d.query(
        'usuarios',
        where: 'perfil = ? AND ativo = 1',
        whereArgs: ['admin'],
      );
      final alvo = await d.query('usuarios',
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (alvo.isNotEmpty &&
          alvo.first['perfil'] == 'admin' &&
          admins.length <= 1) {
        return const Resultado.falha(
            'Tem de existir pelo menos um administrador activo.');
      }
      if (_usuario != null && _usuario!.id == id) {
        return const Resultado.falha(
            'Nao pode desactivar o utilizador com sessao iniciada.');
      }
    }

    await d.update('usuarios', {'ativo': ativo ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
    return const Resultado.sucesso();
  }

  Future<Resultado> redefinirSenhaUsuario(int id, String nova) async {
    if (nova.length < 4) {
      return const Resultado.falha(
          'A senha deve ter pelo menos 4 caracteres.');
    }
    final salt = Seguranca.gerarSalt();
    final d = await _database.db;
    await d.update(
      'usuarios',
      {
        'senha_hash': Seguranca.hashSenha(nova, salt),
        'senha_salt': salt,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _database.registarActividade(
        _usuario?.username, 'Senha de utilizador redefinida', 'id=$id');
    return const Resultado.sucesso();
  }

  Future<Resultado> eliminarUsuario(int id) async {
    final d = await _database.db;
    if (_usuario != null && _usuario!.id == id) {
      return const Resultado.falha(
          'Nao pode eliminar o utilizador com sessao iniciada.');
    }
    final admins = await d.query('usuarios',
        where: 'perfil = ? AND ativo = 1', whereArgs: ['admin']);
    final alvo =
        await d.query('usuarios', where: 'id = ?', whereArgs: [id], limit: 1);
    if (alvo.isNotEmpty &&
        alvo.first['perfil'] == 'admin' &&
        admins.length <= 1) {
      return const Resultado.falha(
          'Tem de existir pelo menos um administrador.');
    }
    await d.delete('usuarios', where: 'id = ?', whereArgs: [id]);
    return const Resultado.sucesso();
  }

  static String? _ouNulo(String? valor) {
    if (valor == null) return null;
    final limpo = valor.trim();
    return limpo.isEmpty ? null : limpo;
  }
}
