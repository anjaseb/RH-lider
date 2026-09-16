import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Primeiro arranque: cria a empresa, a senha geral e o utilizador administrador.
class RegistoEmpresaScreen extends StatefulWidget {
  const RegistoEmpresaScreen({super.key});

  @override
  State<RegistoEmpresaScreen> createState() => _RegistoEmpresaScreenState();
}

class _RegistoEmpresaScreenState extends State<RegistoEmpresaScreen> {
  final _nomeEmpresa = TextEditingController();
  final _nif = TextEditingController();
  final _endereco = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _senhaEmpresa = TextEditingController();
  final _senhaEmpresaConfirma = TextEditingController();

  final _nomeAdmin = TextEditingController();
  final _usernameAdmin = TextEditingController();
  final _senhaAdmin = TextEditingController();
  final _senhaAdminConfirma = TextEditingController();

  String _moeda = 'AOA';
  int _passo = 0;
  bool _aGuardar = false;

  @override
  void dispose() {
    _nomeEmpresa.dispose();
    _nif.dispose();
    _endereco.dispose();
    _telefone.dispose();
    _email.dispose();
    _senhaEmpresa.dispose();
    _senhaEmpresaConfirma.dispose();
    _nomeAdmin.dispose();
    _usernameAdmin.dispose();
    _senhaAdmin.dispose();
    _senhaAdminConfirma.dispose();
    super.dispose();
  }

  void _seguinte() {
    if (_nomeEmpresa.text.trim().isEmpty) {
      mostrarAviso(context, 'Indique o nome da empresa.', erro: true);
      return;
    }
    if (_senhaEmpresa.text.length < 4) {
      mostrarAviso(context, 'A senha da empresa deve ter pelo menos 4 caracteres.',
          erro: true);
      return;
    }
    if (_senhaEmpresa.text != _senhaEmpresaConfirma.text) {
      mostrarAviso(context, 'As senhas da empresa nao coincidem.', erro: true);
      return;
    }
    setState(() => _passo = 1);
  }

  Future<void> _concluir() async {
    if (_nomeAdmin.text.trim().isEmpty) {
      mostrarAviso(context, 'Indique o nome do administrador.', erro: true);
      return;
    }
    if (_usernameAdmin.text.trim().length < 3) {
      mostrarAviso(context,
          'O nome de utilizador deve ter pelo menos 3 caracteres.',
          erro: true);
      return;
    }
    if (_senhaAdmin.text != _senhaAdminConfirma.text) {
      mostrarAviso(context, 'As senhas do administrador nao coincidem.',
          erro: true);
      return;
    }

    setState(() => _aGuardar = true);
    final resultado = await AuthService.instance.registarEmpresa(
      nomeEmpresa: _nomeEmpresa.text,
      nif: _nif.text,
      endereco: _endereco.text,
      telefone: _telefone.text,
      email: _email.text,
      moeda: _moeda,
      senhaEmpresa: _senhaEmpresa.text,
      nomeAdmin: _nomeAdmin.text,
      usernameAdmin: _usernameAdmin.text,
      senhaAdmin: _senhaAdmin.text,
    );
    if (!mounted) return;
    setState(() => _aGuardar = false);

    if (!resultado.ok) {
      mostrarAviso(context, resultado.erro!, erro: true);
    }
    // Quando o registo tem sucesso, o PontoDeEntrada mostra o ecra de login.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Configuracao inicial',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _passo == 0
                        ? 'Passo 1 de 2 - Dados e senha da empresa'
                        : 'Passo 2 de 2 - Utilizador administrador',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_passo == 0) ..._camposEmpresa() else ..._camposAdmin(),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      if (_passo == 1)
                        OutlinedButton(
                          onPressed:
                              _aGuardar ? null : () => setState(() => _passo = 0),
                          child: const Text('Voltar'),
                        ),
                      const Spacer(),
                      SizedBox(
                        width: 160,
                        child: ElevatedButton(
                          onPressed: _aGuardar
                              ? null
                              : (_passo == 0 ? _seguinte : _concluir),
                          child: _aGuardar
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_passo == 0 ? 'Continuar' : 'Concluir'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _camposEmpresa() {
    return [
      CampoTexto(
        controller: _nomeEmpresa,
        rotulo: 'Nome da empresa',
        obrigatorio: true,
        dica: 'Ex: Domingos Humba, Lda',
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(child: CampoTexto(controller: _nif, rotulo: 'NIF')),
          const SizedBox(width: 12),
          Expanded(
            child: CampoSeleccao<String>(
              rotulo: 'Moeda',
              valor: _moeda,
              itens: const [
                DropdownMenuItem(value: 'AOA', child: Text('AOA - Kwanza')),
                DropdownMenuItem(value: 'USD', child: Text('USD - Dolar')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro')),
              ],
              aoMudar: (v) => setState(() => _moeda = v ?? 'AOA'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      CampoTexto(controller: _endereco, rotulo: 'Endereco'),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(child: CampoTexto(controller: _telefone, rotulo: 'Telefone')),
          const SizedBox(width: 12),
          Expanded(child: CampoTexto(controller: _email, rotulo: 'Email')),
        ],
      ),
      const SizedBox(height: 20),
      const Divider(),
      const SizedBox(height: 16),
      const Text(
        'Senha geral da empresa',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 4),
      const Text(
        'Usada para confirmar operacoes sensiveis, como eliminar registos.',
        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: CampoTexto(
              controller: _senhaEmpresa,
              rotulo: 'Senha',
              senha: true,
              obrigatorio: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CampoTexto(
              controller: _senhaEmpresaConfirma,
              rotulo: 'Confirmar senha',
              senha: true,
              obrigatorio: true,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _camposAdmin() {
    return [
      CampoTexto(
        controller: _nomeAdmin,
        rotulo: 'Nome completo',
        obrigatorio: true,
      ),
      const SizedBox(height: 14),
      CampoTexto(
        controller: _usernameAdmin,
        rotulo: 'Nome de utilizador',
        obrigatorio: true,
        dica: 'Ex: admin',
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: CampoTexto(
              controller: _senhaAdmin,
              rotulo: 'Senha',
              senha: true,
              obrigatorio: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CampoTexto(
              controller: _senhaAdminConfirma,
              rotulo: 'Confirmar senha',
              senha: true,
              obrigatorio: true,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Guarde estas credenciais. O administrador tem acesso total ao '
          'sistema e pode criar novos utilizadores.',
          style: TextStyle(fontSize: 12.5, color: AppColors.primaryDark),
        ),
      ),
    ];
  }
}
