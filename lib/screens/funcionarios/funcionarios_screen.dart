import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/funcionario_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/common.dart';
import 'funcionario_detalhe_screen.dart';
import 'funcionario_form_screen.dart';

class FuncionariosScreen extends StatefulWidget {
  const FuncionariosScreen({super.key});

  @override
  State<FuncionariosScreen> createState() => _FuncionariosScreenState();
}

class _FuncionariosScreenState extends State<FuncionariosScreen> {
  final _pesquisa = TextEditingController();
  String _estado = 'todos';
  List<Funcionario> _lista = [];
  bool _aCarregar = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _pesquisa.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _aCarregar = true);
    final lista = await FuncionarioService.instance
        .listar(pesquisa: _pesquisa.text, estado: _estado);
    if (!mounted) return;
    setState(() {
      _lista = lista;
      _aCarregar = false;
    });
  }

  Future<void> _novo() async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FuncionarioFormScreen()),
    );
    if (guardado == true) _carregar();
  }

  Future<void> _abrir(Funcionario f) async {
    final alterado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FuncionarioDetalheScreen(funcionarioId: f.id!),
      ),
    );
    if (alterado == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final moeda = AuthService.instance.moeda;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: SecaoTitulo(
            titulo: 'Funcionarios',
            descricao: '${_lista.length} registo(s) apresentado(s)',
            accoes: [
              ElevatedButton(
                onPressed: _novo,
                child: const Text('Registar funcionario'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _pesquisa,
                  onChanged: (_) => _carregar(),
                  decoration: const InputDecoration(
                    hintText: 'Pesquisar por nome, codigo, BI, cargo ou telefone',
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  initialValue: _estado,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todos os estados')),
                    DropdownMenuItem(value: 'activo', child: Text('Activos')),
                    DropdownMenuItem(value: 'suspenso', child: Text('Suspensos')),
                    DropdownMenuItem(value: 'inactivo', child: Text('Inactivos')),
                  ],
                  onChanged: (v) {
                    setState(() => _estado = v ?? 'todos');
                    _carregar();
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _aCarregar
              ? const Carregando()
              : _lista.isEmpty
                  ? EstadoVazio(
                      titulo: 'Nenhum funcionario encontrado',
                      descricao:
                          'Registe o primeiro funcionario para comecar a marcar '
                          'presencas e gerar pagamentos.',
                      accao: ElevatedButton(
                        onPressed: _novo,
                        child: const Text('Registar funcionario'),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                      itemCount: _lista.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final f = _lista[i];
                        return _LinhaFuncionario(
                          funcionario: f,
                          moeda: moeda,
                          aoTocar: () => _abrir(f),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _LinhaFuncionario extends StatelessWidget {
  final Funcionario funcionario;
  final String moeda;
  final VoidCallback aoTocar;

  const _LinhaFuncionario({
    required this.funcionario,
    required this.moeda,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                Fmt.iniciais(funcionario.nome),
                style: const TextStyle(
                  fontSize: 13,
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
                  Text(
                    funcionario.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${funcionario.codigo}'
                    '${funcionario.cargo != null ? '  -  ${funcionario.cargo}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                funcionario.departamento ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                funcionario.telefone ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                Fmt.dinheiro(funcionario.salarioBase, moeda),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 90,
              child: Align(
                alignment: Alignment.centerRight,
                child: Etiqueta.estadoFuncionario(funcionario.estado),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
