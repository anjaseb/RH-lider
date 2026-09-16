import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _senha = TextEditingController();
  final _focoSenha = FocusNode();
  bool _aEntrar = false;
  String? _erro;

  @override
  void dispose() {
    _username.dispose();
    _senha.dispose();
    _focoSenha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    setState(() {
      _aEntrar = true;
      _erro = null;
    });

    final resultado =
        await AuthService.instance.entrar(_username.text, _senha.text);

    if (!mounted) return;
    setState(() {
      _aEntrar = false;
      _erro = resultado.ok ? null : resultado.erro;
    });
  }

  @override
  Widget build(BuildContext context) {
    final empresa = AuthService.instance.empresa;

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    empresa?.nome ?? 'RH Lider',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Inicie sessao para continuar',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  CampoTexto(
                    controller: _username,
                    rotulo: 'Utilizador',
                    dica: 'Ex: admin',
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Senha',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _senha,
                        focusNode: _focoSenha,
                        obscureText: true,
                        onSubmitted: (_) => _aEntrar ? null : _entrar(),
                      ),
                    ],
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _erro!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _aEntrar ? null : _entrar,
                    child: _aEntrar
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Entrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
