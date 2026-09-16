import 'package:flutter/material.dart';

import 'data/database.dart';
import 'screens/boas_vindas_screen.dart';
import 'screens/configuracoes/registo_empresa_screen.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.db;
  await AuthService.instance.iniciar();
  runApp(const AplicacaoGestao());
}

class AplicacaoGestao extends StatelessWidget {
  const AplicacaoGestao({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RH Lider',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const PontoDeEntrada(),
    );
  }
}

/// Decide o primeiro ecra: boas-vindas, registo da empresa, login ou
/// aplicacao principal.
class PontoDeEntrada extends StatefulWidget {
  const PontoDeEntrada({super.key});

  @override
  State<PontoDeEntrada> createState() => _PontoDeEntradaState();
}

class _PontoDeEntradaState extends State<PontoDeEntrada> {
  bool _boasVindasVistas = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        final auth = AuthService.instance;

        if (!auth.carregado) {
          return const Scaffold(body: Carregando());
        }
        if (!auth.temEmpresa) {
          if (!_boasVindasVistas) {
            return BoasVindasScreen(
              aoContinuar: () => setState(() => _boasVindasVistas = true),
            );
          }
          return const RegistoEmpresaScreen();
        }
        if (!auth.autenticado) {
          return const LoginScreen();
        }
        return const ShellScreen();
      },
    );
  }
}
