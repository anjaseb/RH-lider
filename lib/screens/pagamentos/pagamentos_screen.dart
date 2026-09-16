import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/funcionario_service.dart';
import '../../services/pagamento_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/common.dart';

class PagamentosScreen extends StatefulWidget {
  const PagamentosScreen({super.key});

  @override
  State<PagamentosScreen> createState() => _PagamentosScreenState();
}

class _PagamentosScreenState extends State<PagamentosScreen> {
  late int _ano;
  late int _mes;

  List<Funcionario> _funcionarios = [];
  Map<int, Pagamento> _pagamentos = {};
  Map<String, double> _totais = {};
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
    final pagamentos =
        await PagamentoService.instance.doMesPorFuncionario(_ano, _mes);
    final totais = await PagamentoService.instance.totaisDoMes(_ano, _mes);
    if (!mounted) return;
    setState(() {
      _funcionarios = funcionarios;
      _pagamentos = pagamentos;
      _totais = totais;
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

  Future<void> _gerarFolha() async {
    final ok = await confirmar(
      context,
      titulo: 'Gerar folha de pagamento',
      mensagem:
          'Sera criada a folha de ${Fmt.nomeMes(_mes)} de $_ano para os '
          'funcionarios activos que ainda nao a tenham. O desconto por faltas '
          'e calculado a partir das presencas registadas.',
      textoConfirmar: 'Gerar',
    );
    if (!ok) return;

    final criados = await PagamentoService.instance.gerarFolha(
      ano: _ano,
      mes: _mes,
      funcionarios: _funcionarios,
    );
    if (!mounted) return;
    mostrarAviso(context, '$criados registo(s) criados.');
    _carregar();
  }

  Future<void> _editar(Funcionario f) async {
    final existente = _pagamentos[f.id];
    final base = existente ??
        Pagamento(
          funcionarioId: f.id!,
          ano: _ano,
          mes: _mes,
          salarioBase: f.salarioBase,
          liquido: f.salarioBase,
        );

    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoPagamento(funcionario: f, pagamento: base),
    );
    if (guardado == true) _carregar();
  }

  Future<void> _alternarEstado(Funcionario f) async {
    final p = _pagamentos[f.id];
    if (p == null) {
      mostrarAviso(context, 'Gere primeiro a folha deste mes.', erro: true);
      return;
    }
    final novo = p.estado == 'pago' ? 'pendente' : 'pago';
    final r = await PagamentoService.instance.definirEstado(
      funcionarioId: f.id!,
      ano: _ano,
      mes: _mes,
      estado: novo,
    );
    if (!mounted) return;
    if (!r.ok) {
      mostrarAviso(context, r.erro!, erro: true);
      return;
    }
    _carregar();
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
            titulo: 'Pagamentos',
            descricao:
                'Folha mensal dos funcionarios activos. Os valores podem ser ajustados individualmente.',
            accoes: [
              ElevatedButton(
                onPressed: _funcionarios.isEmpty ? null : _gerarFolha,
                child: const Text('Gerar folha do mes'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
          child: Row(
            children: [
              _SeletorMes(
                ano: _ano,
                mes: _mes,
                aoAnterior: () => _mudarMes(-1),
                aoSeguinte: () => _mudarMes(1),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CartaoIndicador(
                        titulo: 'Total do mes',
                        valor: Fmt.dinheiro(_totais['total'] ?? 0, moeda),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CartaoIndicador(
                        titulo: 'Pago',
                        valor: Fmt.dinheiro(_totais['pago'] ?? 0, moeda),
                        cor: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CartaoIndicador(
                        titulo: 'Pendente',
                        valor: Fmt.dinheiro(_totais['pendente'] ?? 0, moeda),
                        cor: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
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
                          'Registe funcionarios para poder gerar a folha de pagamento.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      itemCount: _funcionarios.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final f = _funcionarios[i];
                        final p = _pagamentos[f.id];
                        return _LinhaPagamento(
                          funcionario: f,
                          pagamento: p,
                          moeda: moeda,
                          aoEditar: () => _editar(f),
                          aoAlternarEstado: () => _alternarEstado(f),
                        );
                      },
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
      height: 74,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
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
            width: 140,
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

class _LinhaPagamento extends StatelessWidget {
  final Funcionario funcionario;
  final Pagamento? pagamento;
  final String moeda;
  final VoidCallback aoEditar;
  final VoidCallback aoAlternarEstado;

  const _LinhaPagamento({
    required this.funcionario,
    required this.pagamento,
    required this.moeda,
    required this.aoEditar,
    required this.aoAlternarEstado,
  });

  @override
  Widget build(BuildContext context) {
    final p = pagamento;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
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
              'Base: ${Fmt.numero(p?.salarioBase ?? funcionario.salarioBase)}',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Descontos: ${Fmt.numero(p?.totalDescontos ?? 0)}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              p == null ? 'Sem folha' : Fmt.dinheiro(p.liquido, moeda),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: p == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 92,
            child: Align(
              alignment: Alignment.centerRight,
              child: p == null
                  ? const Etiqueta(
                      texto: 'Nao gerado', cor: AppColors.textSecondary)
                  : Etiqueta.estadoPagamento(p.estado),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: aoEditar,
            child: Text(p == null ? 'Criar' : 'Editar'),
          ),
          TextButton(
            onPressed: p == null ? null : aoAlternarEstado,
            style: TextButton.styleFrom(
              foregroundColor:
                  p?.estado == 'pago' ? AppColors.warning : AppColors.success,
            ),
            child: Text(p?.estado == 'pago' ? 'Reabrir' : 'Marcar pago'),
          ),
        ],
      ),
    );
  }
}

/// Dialogo de edicao dos valores de um pagamento.
class _DialogoPagamento extends StatefulWidget {
  final Funcionario funcionario;
  final Pagamento pagamento;

  const _DialogoPagamento({
    required this.funcionario,
    required this.pagamento,
  });

  @override
  State<_DialogoPagamento> createState() => _DialogoPagamentoState();
}

class _DialogoPagamentoState extends State<_DialogoPagamento> {
  late TextEditingController _base;
  late TextEditingController _subsidios;
  late TextEditingController _bonus;
  late TextEditingController _horasExtra;
  late TextEditingController _descontoFaltas;
  late TextEditingController _adiantamentos;
  late TextEditingController _outros;
  late TextEditingController _observacao;

  String _metodo = 'Transferencia';
  bool _aGuardar = false;

  static const List<String> _metodos = [
    'Transferencia',
    'Numerario',
    'Multicaixa Express',
    'Cheque',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.pagamento;
    _base = TextEditingController(text: _valor(p.salarioBase));
    _subsidios = TextEditingController(text: _valor(p.subsidios));
    _bonus = TextEditingController(text: _valor(p.bonus));
    _horasExtra = TextEditingController(text: _valor(p.horasExtra));
    _descontoFaltas = TextEditingController(text: _valor(p.descontoFaltas));
    _adiantamentos = TextEditingController(text: _valor(p.adiantamentos));
    _outros = TextEditingController(text: _valor(p.outrosDescontos));
    _observacao = TextEditingController(text: p.observacao ?? '');
    _metodo = p.metodo ?? 'Transferencia';

    // Actualiza o valor liquido a medida que os campos sao preenchidos.
    for (final c in [
      _base,
      _subsidios,
      _bonus,
      _horasExtra,
      _descontoFaltas,
      _adiantamentos,
      _outros,
    ]) {
      c.addListener(_recalcular);
    }
  }

  void _recalcular() {
    if (mounted) setState(() {});
  }

  static String _valor(double v) => v == 0 ? '' : v.toString();

  @override
  void dispose() {
    for (final c in [
      _base,
      _subsidios,
      _bonus,
      _horasExtra,
      _descontoFaltas,
      _adiantamentos,
      _outros,
      _observacao,
    ]) {
      c.removeListener(_recalcular);
      c.dispose();
    }
    super.dispose();
  }

  double get _liquido {
    final ganhos = Fmt.lerNumero(_base.text) +
        Fmt.lerNumero(_subsidios.text) +
        Fmt.lerNumero(_bonus.text) +
        Fmt.lerNumero(_horasExtra.text);
    final descontos = Fmt.lerNumero(_descontoFaltas.text) +
        Fmt.lerNumero(_adiantamentos.text) +
        Fmt.lerNumero(_outros.text);
    return ganhos - descontos;
  }

  Future<void> _guardar() async {
    setState(() => _aGuardar = true);

    final p = widget.pagamento.copyWith(
      salarioBase: Fmt.lerNumero(_base.text),
      subsidios: Fmt.lerNumero(_subsidios.text),
      bonus: Fmt.lerNumero(_bonus.text),
      horasExtra: Fmt.lerNumero(_horasExtra.text),
      descontoFaltas: Fmt.lerNumero(_descontoFaltas.text),
      adiantamentos: Fmt.lerNumero(_adiantamentos.text),
      outrosDescontos: Fmt.lerNumero(_outros.text),
      metodo: _metodo,
      observacao:
          _observacao.text.trim().isEmpty ? null : _observacao.text.trim(),
    );

    await PagamentoService.instance.guardar(p);
    if (!mounted) return;
    setState(() => _aGuardar = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final moeda = AuthService.instance.moeda;

    return AlertDialog(
      title: Text(
        '${widget.funcionario.nome} - '
        '${Fmt.nomeMes(widget.pagamento.mes)} ${widget.pagamento.ano}',
        style: const TextStyle(fontSize: 16),
      ),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GANHOS',
                style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 0.7,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _campo(_base, 'Salario base')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_subsidios, 'Subsidios')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _campo(_bonus, 'Bonus / premios')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_horasExtra, 'Horas extra')),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'DESCONTOS',
                style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 0.7,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _campo(_descontoFaltas, 'Faltas')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_adiantamentos, 'Adiantamentos')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_outros, 'Outros')),
                ],
              ),
              const SizedBox(height: 22),
              CampoSeleccao<String>(
                rotulo: 'Metodo de pagamento',
                valor: _metodo,
                itens: _metodos
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                aoMudar: (v) => setState(() => _metodo = v ?? 'Transferencia'),
              ),
              const SizedBox(height: 12),
              CampoTexto(
                controller: _observacao,
                rotulo: 'Observacao',
                linhas: 2,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Valor liquido',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Fmt.dinheiro(_liquido, moeda),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _aGuardar ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _aGuardar ? null : _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _campo(TextEditingController c, String rotulo) {
    return CampoTexto(
      controller: c,
      rotulo: rotulo,
      dica: '0',
      tipo: const TextInputType.numberWithOptions(decimal: true),
    );
  }
}
