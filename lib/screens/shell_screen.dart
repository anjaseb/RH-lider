import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';
import 'configuracoes/configuracoes_screen.dart';
import 'funcionarios/funcionarios_screen.dart';
import 'pagamentos/pagamentos_screen.dart';
import 'painel_screen.dart';
import 'presencas/presencas_screen.dart';
import 'usuarios/usuarios_screen.dart';

class _ItemMenu {
  final String titulo;
  final IconData icone;
  final bool apenasAdmin;

  const _ItemMenu(this.titulo, this.icone, {this.apenasAdmin = false});
}

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _indice = 0;

  static const List<_ItemMenu> _itens = [
    _ItemMenu('Painel', Icons.dashboard_outlined),
    _ItemMenu('Funcionarios', Icons.people_outline),
    _ItemMenu('Presencas', Icons.event_available_outlined),
    _ItemMenu('Pagamentos', Icons.payments_outlined),
    _ItemMenu('Utilizadores', Icons.manage_accounts_outlined,
        apenasAdmin: true),
    _ItemMenu('Configuracoes', Icons.settings_outlined, apenasAdmin: true),
  ];

  List<_ItemMenu> get _visiveis {
    final admin = AuthService.instance.isAdmin;
    return _itens.where((i) => !i.apenasAdmin || admin).toList();
  }

  Widget _conteudo(String titulo) {
    switch (titulo) {
      case 'Painel':
        return PainelScreen(
          aoNavegar: (destino) {
            final idx = _visiveis.indexWhere((i) => i.titulo == destino);
            if (idx >= 0) setState(() => _indice = idx);
          },
        );
      case 'Funcionarios':
        return const FuncionariosScreen();
      case 'Presencas':
        return const PresencasScreen();
      case 'Pagamentos':
        return const PagamentosScreen();
      case 'Utilizadores':
        return const UsuariosScreen();
      case 'Configuracoes':
        return const ConfiguracoesScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _terminarSessao() async {
    final ok = await confirmar(
      context,
      titulo: 'Terminar sessao',
      mensagem: 'Deseja sair da aplicacao?',
      textoConfirmar: 'Sair',
    );
    if (ok) await AuthService.instance.sair();
  }

  @override
  Widget build(BuildContext context) {
    final itens = _visiveis;
    final indice = _indice >= itens.length ? itens.length - 1 : _indice;
    final auth = AuthService.instance;

    return Scaffold(
      body: Row(
        children: [
          _MenuLateral(
            itens: itens,
            indice: indice,
            aoSeleccionar: (i) => setState(() => _indice = i),
            nomeEmpresa: auth.empresa?.nome ?? 'Empresa',
            nomeUsuario: auth.usuario?.nome ?? '',
            perfilUsuario:
                auth.isAdmin ? 'Administrador' : 'Operador',
            aoSair: _terminarSessao,
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Container(
              color: AppColors.background,
              child: _conteudo(itens[indice].titulo),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuLateral extends StatelessWidget {
  final List<_ItemMenu> itens;
  final int indice;
  final ValueChanged<int> aoSeleccionar;
  final String nomeEmpresa;
  final String nomeUsuario;
  final String perfilUsuario;
  final VoidCallback aoSair;

  const _MenuLateral({
    required this.itens,
    required this.indice,
    required this.aoSeleccionar,
    required this.nomeEmpresa,
    required this.nomeUsuario,
    required this.perfilUsuario,
    required this.aoSair,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomeEmpresa,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'RH Lider',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: itens.length,
              itemBuilder: (context, i) {
                final activo = i == indice;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: InkWell(
                    onTap: () => aoSeleccionar(i),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: activo
                            ? AppColors.primaryLight
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            itens[i].icone,
                            size: 18,
                            color: activo
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              itens[i].titulo,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: activo
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: activo
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    Fmt.iniciais(nomeUsuario),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nomeUsuario,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        perfilUsuario,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Terminar sessao',
                  onPressed: aoSair,
                  icon: const Icon(Icons.logout, size: 17),
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
