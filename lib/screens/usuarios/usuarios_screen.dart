import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/common.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<Usuario> _lista = [];
  bool _aCarregar = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _aCarregar = true);
    final lista = await AuthService.instance.listarUsuarios();
    if (!mounted) return;
    setState(() {
      _lista = lista;
      _aCarregar = false;
    });
  }

  Future<void> _novo() async {
    final criado = await showDialog<bool>(
      context: context,
      builder: (_) => const _DialogoNovoUsuario(),
    );
    if (criado == true) _carregar();
  }

  Future<void> _redefinirSenha(Usuario u) async {
    final nova = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoSenha(nome: u.nome),
    );
    if (nova == null) return;

    final r = await AuthService.instance.redefinirSenhaUsuario(u.id, nova);
    if (!mounted) return;
    if (!r.ok) {
      mostrarAviso(context, r.erro!, erro: true);
      return;
    }
    mostrarAviso(context, 'Senha actualizada.');
  }

  Future<void> _alternarEstado(Usuario u) async {
    final r = await AuthService.instance.definirEstadoUsuario(u.id, !u.ativo);
    if (!mounted) return;
    if (!r.ok) {
      mostrarAviso(context, r.erro!, erro: true);
      return;
    }
    _carregar();
  }

  Future<void> _eliminar(Usuario u) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar utilizador',
      mensagem: 'O acesso de ${u.nome} sera removido permanentemente.',
      textoConfirmar: 'Eliminar',
      destrutivo: true,
    );
    if (!ok) return;

    final r = await AuthService.instance.eliminarUsuario(u.id);
    if (!mounted) return;
    if (!r.ok) {
      mostrarAviso(context, r.erro!, erro: true);
      return;
    }
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
          child: SecaoTitulo(
            titulo: 'Utilizadores',
            descricao:
                'Contas com acesso ao sistema. Apenas administradores gerem utilizadores.',
            accoes: [
              ElevatedButton(
                onPressed: _novo,
                child: const Text('Novo utilizador'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _aCarregar
              ? const Carregando()
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  itemCount: _lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final u = _lista[i];
                    final actual = AuthService.instance.usuario?.id == u.id;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              Fmt.iniciais(u.nome),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      u.nome,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (actual) ...[
                                      const SizedBox(width: 8),
                                      const Etiqueta(
                                        texto: 'Sessao actual',
                                        cor: AppColors.info,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  u.username,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              u.isAdmin ? 'Administrador' : 'Operador',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: Etiqueta(
                              texto: u.ativo ? 'Activo' : 'Desactivado',
                              cor: u.ativo
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _redefinirSenha(u),
                            child: const Text('Senha'),
                          ),
                          TextButton(
                            onPressed: () => _alternarEstado(u),
                            child: Text(u.ativo ? 'Desactivar' : 'Activar'),
                          ),
                          TextButton(
                            onPressed: () => _eliminar(u),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.danger,
                            ),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DialogoNovoUsuario extends StatefulWidget {
  const _DialogoNovoUsuario();

  @override
  State<_DialogoNovoUsuario> createState() => _DialogoNovoUsuarioState();
}

class _DialogoNovoUsuarioState extends State<_DialogoNovoUsuario> {
  final _nome = TextEditingController();
  final _username = TextEditingController();
  final _senha = TextEditingController();
  String _perfil = 'operador';
  bool _aGuardar = false;

  @override
  void dispose() {
    _nome.dispose();
    _username.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _aGuardar = true);
    final r = await AuthService.instance.criarUsuario(
      nome: _nome.text,
      username: _username.text,
      senha: _senha.text,
      perfil: _perfil,
    );
    if (!mounted) return;
    setState(() => _aGuardar = false);

    if (!r.ok) {
      mostrarAviso(context, r.erro!, erro: true);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo utilizador', style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CampoTexto(
                controller: _nome, rotulo: 'Nome completo', obrigatorio: true),
            const SizedBox(height: 14),
            CampoTexto(
              controller: _username,
              rotulo: 'Nome de utilizador',
              obrigatorio: true,
            ),
            const SizedBox(height: 14),
            CampoTexto(
              controller: _senha,
              rotulo: 'Senha',
              senha: true,
              obrigatorio: true,
            ),
            const SizedBox(height: 14),
            CampoSeleccao<String>(
              rotulo: 'Perfil',
              valor: _perfil,
              itens: const [
                DropdownMenuItem(value: 'operador', child: Text('Operador')),
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
              ],
              aoMudar: (v) => setState(() => _perfil = v ?? 'operador'),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'O operador pode gerir funcionarios, presencas e pagamentos. '
                'O administrador tem tambem acesso a utilizadores e configuracoes.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _aGuardar ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _aGuardar ? null : _guardar,
          child: const Text('Criar'),
        ),
      ],
    );
  }
}

class _DialogoSenha extends StatefulWidget {
  final String nome;

  const _DialogoSenha({required this.nome});

  @override
  State<_DialogoSenha> createState() => _DialogoSenhaState();
}

class _DialogoSenhaState extends State<_DialogoSenha> {
  final _senha = TextEditingController();
  final _confirma = TextEditingController();

  @override
  void dispose() {
    _senha.dispose();
    _confirma.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Redefinir senha de ${widget.nome}',
          style: const TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CampoTexto(
                controller: _senha, rotulo: 'Nova senha', senha: true),
            const SizedBox(height: 14),
            CampoTexto(
              controller: _confirma,
              rotulo: 'Confirmar senha',
              senha: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_senha.text != _confirma.text) {
              mostrarAviso(context, 'As senhas nao coincidem.', erro: true);
              return;
            }
            Navigator.pop(context, _senha.text);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
