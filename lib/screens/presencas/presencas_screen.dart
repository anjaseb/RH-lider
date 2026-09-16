import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/funcionario_service.dart';
import '../../services/presenca_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/common.dart';

/// Folha de presencas mensal em grelha: funcionarios em linha, dias em coluna.
class PresencasScreen extends StatefulWidget {
  const PresencasScreen({super.key});

  @override
  State<PresencasScreen> createState() => _PresencasScreenState();
}

class _PresencasScreenState extends State<PresencasScreen> {
  late int _ano;
  late int _mes;

  List<Funcionario> _funcionarios = [];
  Map<int, Map<int, Presenca>> _folha = {};
  bool _aCarregar = true;

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _ano = agora.year;
    _mes = agora.month;
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _aCarregar = true);
    final funcionarios = await FuncionarioService.instance.listarActivos();
    final folha = await PresencaService.instance.folhaDoMes(_ano, _mes);
    if (!mounted) return;
    setState(() {
      _funcionarios = funcionarios;
      _folha = folha;
      _aCarregar = false;
    });
  }

  void _mudarMes(int delta) {
    var mes = _mes + delta;
    var ano = _ano;
    if (mes < 1) {
      mes = 12;
      ano--;
    } else if (mes > 12) {
      mes = 1;
      ano++;
    }
    setState(() {
      _mes = mes;
      _ano = ano;
    });
    _carregar();
  }

  Future<void> _marcar(Funcionario f, int dia, String estado) async {
    final data = DateTime(_ano, _mes, dia);
    if (estado == 'limpar') {
      await PresencaService.instance.limpar(funcionarioId: f.id!, dia: data);
    } else {
      await PresencaService.instance.marcar(
        funcionarioId: f.id!,
        dia: data,
        estado: estado,
        horas: estado == EstadoPresenca.presente ? 8 : 0,
      );
    }
    _carregar();
  }

  Future<void> _preencherDiasUteis() async {
    final ok = await confirmar(
      context,
      titulo: 'Preencher dias uteis',
      mensagem:
          'Todos os dias de semana ainda sem marcacao serao registados como '
          'presentes. Os registos existentes nao sao alterados.',
      textoConfirmar: 'Preencher',
    );
    if (!ok) return;

    final criados = await PresencaService.instance.preencherDiasUteis(
      _ano,
      _mes,
      funcionarioIds: _funcionarios.map((f) => f.id!).toList(),
    );
    if (!mounted) return;
    mostrarAviso(context, '$criados dia(s) marcados como presentes.');
    _carregar();
  }

  Future<void> _limparMes() async {
    final ok = await confirmar(
      context,
      titulo: 'Limpar mes',
      mensagem:
          'Todas as presencas de ${Fmt.nomeMes(_mes)} de $_ano serao apagadas.',
      textoConfirmar: 'Limpar',
      destrutivo: true,
    );
    if (!ok) return;

    final removidos = await PresencaService.instance
        .limparMes(_ano, _mes, _funcionarios.map((f) => f.id!).toList());
    if (!mounted) return;
    mostrarAviso(context, '$removidos registo(s) removidos.');
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final dias = Fmt.diasNoMes(_ano, _mes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: SecaoTitulo(
            titulo: 'Presencas',
            descricao:
                'Clique numa celula para marcar o estado do dia. Apenas funcionarios activos.',
            accoes: [
              OutlinedButton(
                onPressed: _funcionarios.isEmpty ? null : _preencherDiasUteis,
                child: const Text('Preencher dias uteis'),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: _funcionarios.isEmpty ? null : _limparMes,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
                child: const Text('Limpar mes'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 16),
          child: Row(
            children: [
              _SeletorMes(
                ano: _ano,
                mes: _mes,
                aoAnterior: () => _mudarMes(-1),
                aoSeguinte: () => _mudarMes(1),
              ),
              const SizedBox(width: 20),
              const Expanded(child: _Legenda()),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _aCarregar
              ? const Carregando()
              : _funcionarios.isEmpty
                  ? const EstadoVazio(
                      titulo: 'Nenhum funcionario activo',
                      descricao:
                          'Registe funcionarios para poder marcar presencas.',
                    )
                  : _Grelha(
                      funcionarios: _funcionarios,
                      folha: _folha,
                      ano: _ano,
                      mes: _mes,
                      dias: dias,
                      aoMarcar: _marcar,
                    ),
        ),
      ],
    );
  }
}

class _SeletorMes extends StatelessWidget {
  final int ano;
  final int mes;
  final VoidCallback aoAnterior;
  final VoidCallback aoSeguinte;

  const _SeletorMes({
    required this.ano,
    required this.mes,
    required this.aoAnterior,
    required this.aoSeguinte,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: aoAnterior,
            icon: const Icon(Icons.chevron_left, size: 20),
            color: AppColors.textSecondary,
          ),
          SizedBox(
            width: 150,
            child: Text(
              '${Fmt.nomeMes(mes)} $ano',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: aoSeguinte,
            icon: const Icon(Icons.chevron_right, size: 20),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: EstadoPresenca.todos.map((estado) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _corEstado(estado).withValues(alpha: 0.12),
                border: Border.all(
                    color: _corEstado(estado).withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                EstadoPresenca.sigla(estado),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _corEstado(estado),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              EstadoPresenca.rotulo(estado),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

Color _corEstado(String estado) {
  switch (estado) {
    case EstadoPresenca.presente:
      return AppColors.success;
    case EstadoPresenca.falta:
      return AppColors.danger;
    case EstadoPresenca.justificada:
      return AppColors.warning;
    case EstadoPresenca.atraso:
      return AppColors.warning;
    case EstadoPresenca.ferias:
      return AppColors.info;
    case EstadoPresenca.folga:
      return AppColors.textSecondary;
    default:
      return AppColors.textSecondary;
  }
}

class _Grelha extends StatelessWidget {
  final List<Funcionario> funcionarios;
  final Map<int, Map<int, Presenca>> folha;
  final int ano;
  final int mes;
  final int dias;
  final Future<void> Function(Funcionario, int, String) aoMarcar;

  const _Grelha({
    required this.funcionarios,
    required this.folha,
    required this.ano,
    required this.mes,
    required this.dias,
    required this.aoMarcar,
  });

  static const double _larguraNome = 230;
  static const double _larguraDia = 34;
  static const double _larguraResumo = 200;
  static const double _alturaLinha = 42;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _larguraNome + (_larguraDia * dias) + _larguraResumo,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cabecalho(),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: funcionarios.length,
                itemBuilder: (context, i) => _linha(context, funcionarios[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Container(
      height: 48,
      color: AppColors.surfaceAlt,
      child: Row(
        children: [
          Container(
            width: _larguraNome,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: const Text(
              'Funcionario',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...List.generate(dias, (i) {
            final dia = i + 1;
            final data = DateTime(ano, mes, dia);
            final fds = Fmt.fimDeSemana(data);
            return Container(
              width: _larguraDia,
              alignment: Alignment.center,
              color: fds ? AppColors.border.withValues(alpha: 0.35) : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$dia',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: fds
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    Fmt.diaSemanaCurto(data),
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
          Container(
            width: _larguraResumo,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: const Text(
              'Resumo do mes',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linha(BuildContext context, Funcionario f) {
    final marcacoes = folha[f.id] ?? {};
    var presentes = 0;
    var faltas = 0;
    var justificadas = 0;
    for (final p in marcacoes.values) {
      if (p.estado == EstadoPresenca.presente) presentes++;
      if (p.estado == EstadoPresenca.falta) faltas++;
      if (p.estado == EstadoPresenca.justificada) justificadas++;
    }

    return Container(
      height: _alturaLinha,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: _larguraNome,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  f.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  f.codigo,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(dias, (i) {
            final dia = i + 1;
            final data = DateTime(ano, mes, dia);
            final fds = Fmt.fimDeSemana(data);
            final presenca = marcacoes[dia];
            return _Celula(
              largura: _larguraDia,
              fimDeSemana: fds,
              presenca: presenca,
              aoEscolher: (estado) => aoMarcar(f, dia, estado),
            );
          }),
          Container(
            width: _larguraResumo,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              'P: $presentes   F: $faltas   J: $justificadas',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Celula extends StatelessWidget {
  final double largura;
  final bool fimDeSemana;
  final Presenca? presenca;
  final ValueChanged<String> aoEscolher;

  const _Celula({
    required this.largura,
    required this.fimDeSemana,
    required this.presenca,
    required this.aoEscolher,
  });

  @override
  Widget build(BuildContext context) {
    final estado = presenca?.estado;
    final cor = estado == null ? null : _corEstado(estado);

    return SizedBox(
      width: largura,
      child: PopupMenuButton<String>(
        tooltip: estado == null ? 'Marcar' : EstadoPresenca.rotulo(estado),
        padding: EdgeInsets.zero,
        onSelected: aoEscolher,
        itemBuilder: (context) => [
          ...EstadoPresenca.todos.map(
            (e) => PopupMenuItem(
              value: e,
              height: 38,
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _corEstado(e).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      EstadoPresenca.sigla(e),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _corEstado(e),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(EstadoPresenca.rotulo(e),
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'limpar',
            height: 38,
            child: Text('Remover marcacao',
                style: TextStyle(fontSize: 13, color: AppColors.danger)),
          ),
        ],
        child: Container(
          margin: const EdgeInsets.all(4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cor != null
                ? cor.withValues(alpha: 0.12)
                : fimDeSemana
                    ? AppColors.border.withValues(alpha: 0.3)
                    : AppColors.surface,
            border: Border.all(
              color: cor != null
                  ? cor.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            estado == null ? '' : EstadoPresenca.sigla(estado),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cor ?? AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
