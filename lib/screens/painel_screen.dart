import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/funcionario_service.dart';
import '../services/pagamento_service.dart';
import '../services/presenca_service.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';

class PainelScreen extends StatefulWidget {
  final ValueChanged<String>? aoNavegar;

  const PainelScreen({super.key, this.aoNavegar});

  @override
  State<PainelScreen> createState() => _PainelScreenState();
}

class _PainelScreenState extends State<PainelScreen> {
  bool _aCarregar = true;
  Map<String, int> _contagens = {};
  double _totalSalarios = 0;
  Map<String, int> _presencasHoje = {};
  Map<String, double> _totaisMes = {};
  List<Map<String, Object?>> _documentosExpirar = [];

  final _agora = DateTime.now();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _aCarregar = true);

    final contagens = await FuncionarioService.instance.contagens();
    final salarios = await FuncionarioService.instance.totalSalarios();
    final hoje = await PresencaService.instance.resumoHoje();
    final totais = await PagamentoService.instance
        .totaisDoMes(_agora.year, _agora.month);
    final docs = await FuncionarioService.instance.documentosAExpirar();

    if (!mounted) return;
    setState(() {
      _contagens = contagens;
      _totalSalarios = salarios;
      _presencasHoje = hoje;
      _totaisMes = totais;
      _documentosExpirar = docs;
      _aCarregar = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final moeda = AuthService.instance.moeda;

    if (_aCarregar) return const Carregando();

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          SecaoTitulo(
            titulo: 'Painel',
            descricao:
                '${Fmt.nomeMes(_agora.month)} de ${_agora.year} - visao geral da empresa',
            accoes: [
              OutlinedButton(
                onPressed: _carregar,
                child: const Text('Actualizar'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final colunas = constraints.maxWidth > 1100
                  ? 4
                  : constraints.maxWidth > 760
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: colunas,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: colunas == 1 ? 4.2 : 2.1,
                children: [
                  CartaoIndicador(
                    titulo: 'Funcionarios activos',
                    valor: '${_contagens['activo'] ?? 0}',
                    detalhe: 'Total registado: ${_contagens['total'] ?? 0}',
                  ),
                  CartaoIndicador(
                    titulo: 'Presencas hoje',
                    valor: '${_presencasHoje[EstadoPresenca.presente] ?? 0}',
                    detalhe:
                        'Faltas: ${_presencasHoje[EstadoPresenca.falta] ?? 0}  '
                        'Atrasos: ${_presencasHoje[EstadoPresenca.atraso] ?? 0}',
                  ),
                  CartaoIndicador(
                    titulo: 'Massa salarial',
                    valor: Fmt.dinheiro(_totalSalarios, moeda),
                    detalhe: 'Soma dos salarios base activos',
                  ),
                  CartaoIndicador(
                    titulo: 'Pagamentos do mes',
                    valor: Fmt.dinheiro(_totaisMes['total'] ?? 0, moeda),
                    detalhe:
                        'Pendente: ${Fmt.dinheiro(_totaisMes['pendente'] ?? 0, moeda)}',
                    cor: (_totaisMes['pendente'] ?? 0) > 0
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) {
              final largo = constraints.maxWidth > 900;
              final cartoes = [
                _CartaoPresencasHoje(dados: _presencasHoje),
                _CartaoDocumentos(documentos: _documentosExpirar),
              ];
              if (!largo) {
                return Column(
                  children: [
                    cartoes[0],
                    const SizedBox(height: 14),
                    cartoes[1],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cartoes[0]),
                  const SizedBox(width: 14),
                  Expanded(child: cartoes[1]),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          _AccoesRapidas(aoNavegar: widget.aoNavegar),
        ],
      ),
    );
  }
}

class _CartaoPresencasHoje extends StatelessWidget {
  final Map<String, int> dados;

  const _CartaoPresencasHoje({required this.dados});

  @override
  Widget build(BuildContext context) {
    final total = dados.values.fold<int>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Presencas de hoje',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          if (total == 0)
            const Text(
              'Ainda nao ha registos de presenca para hoje.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            )
          else
            ...EstadoPresenca.todos.map((estado) {
              final valor = dados[estado] ?? 0;
              if (valor == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        EstadoPresenca.rotulo(estado),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '$valor',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _CartaoDocumentos extends StatelessWidget {
  final List<Map<String, Object?>> documentos;

  const _CartaoDocumentos({required this.documentos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Documentos a expirar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Validade nos proximos 60 dias',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          if (documentos.isEmpty)
            const Text(
              'Nao ha documentos a expirar.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            )
          else
            ...documentos.take(6).map((d) {
              final validade = d['data_validade'] as String?;
              final expirado = validade != null &&
                  DateTime.tryParse(validade) != null &&
                  DateTime.parse(validade).isBefore(DateTime.now());
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${d['titulo']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            '${d['funcionario']}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Etiqueta(
                      texto: Fmt.data(validade),
                      cor: expirado ? AppColors.danger : AppColors.warning,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AccoesRapidas extends StatelessWidget {
  final ValueChanged<String>? aoNavegar;

  const _AccoesRapidas({this.aoNavegar});

  @override
  Widget build(BuildContext context) {
    final accoes = {
      'Registar funcionario': 'Funcionarios',
      'Marcar presencas': 'Presencas',
      'Folha de pagamento': 'Pagamentos',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accoes rapidas',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: accoes.entries
                .map(
                  (e) => OutlinedButton(
                    onPressed: () => aoNavegar?.call(e.value),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                    ),
                    child: Text(e.key),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
