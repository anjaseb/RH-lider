import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/funcionario_service.dart';
import '../../services/pagamento_service.dart';
import '../../services/presenca_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/common.dart';
import 'funcionario_form_screen.dart';

class FuncionarioDetalheScreen extends StatefulWidget {
  final int funcionarioId;

  const FuncionarioDetalheScreen({super.key, required this.funcionarioId});

  @override
  State<FuncionarioDetalheScreen> createState() =>
      _FuncionarioDetalheScreenState();
}

class _FuncionarioDetalheScreenState extends State<FuncionarioDetalheScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Funcionario? _funcionario;
  List<Documento> _documentos = [];
  List<Pagamento> _pagamentos = [];
  Map<String, int> _resumoPresencas = {};
  bool _aCarregar = true;
  bool _alterado = false;

  final _agora = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _carregar();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _aCarregar = true);
    final f = await FuncionarioService.instance.obter(widget.funcionarioId);
    final docs =
        await FuncionarioService.instance.documentos(widget.funcionarioId);
    final pags =
        await PagamentoService.instance.historico(widget.funcionarioId);
    final presencas = await PresencaService.instance
        .resumoFuncionario(widget.funcionarioId, _agora.year, _agora.month);

    if (!mounted) return;
    setState(() {
      _funcionario = f;
      _documentos = docs;
      _pagamentos = pags;
      _resumoPresencas = presencas;
      _aCarregar = false;
    });
  }

  Future<void> _editar() async {
    if (_funcionario == null) return;
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FuncionarioFormScreen(funcionario: _funcionario),
      ),
    );
    if (guardado == true) {
      _alterado = true;
      _carregar();
    }
  }

  Future<void> _eliminar() async {
    if (_funcionario == null) return;
    final ok = await confirmar(
      context,
      titulo: 'Eliminar funcionario',
      mensagem:
          'Esta accao remove o funcionario, as presencas, os pagamentos e os '
          'documentos anexados. Nao pode ser revertida.',
      textoConfirmar: 'Eliminar',
      destrutivo: true,
    );
    if (!ok) return;

    await FuncionarioService.instance.eliminar(widget.funcionarioId);
    if (!mounted) return;
    mostrarAviso(context, 'Funcionario eliminado.');
    Navigator.pop(context, true);
  }

  Future<void> _anexarDocumento() async {
    final resultado = await FilePicker.platform.pickFiles(
      dialogTitle: 'Seleccionar documento',
      withData: false,
    );
    if (resultado == null || resultado.files.isEmpty) return;
    final caminho = resultado.files.single.path;
    if (caminho == null) return;
    if (!mounted) return;

    final dados = await showDialog<Map<String, String?>>(
      context: context,
      builder: (_) => _DialogoDocumento(nomeFicheiro: resultado.files.single.name),
    );
    if (dados == null) return;

    final r = await FuncionarioService.instance.anexarDocumento(
      funcionarioId: widget.funcionarioId,
      caminhoOrigem: caminho,
      tipo: dados['tipo'] ?? 'Outro',
      titulo: dados['titulo'] ?? resultado.files.single.name,
      dataEmissao: dados['emissao'],
      dataValidade: dados['validade'],
      observacao: dados['observacao'],
    );

    if (!mounted) return;
    if (!r.ok) {
      mostrarAviso(context, r.erro!, erro: true);
      return;
    }
    mostrarAviso(context, 'Documento anexado.');
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final f = _funcionario;

    return Scaffold(
      appBar: AppBar(
        title: Text(f?.nome ?? 'Funcionario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context, _alterado),
        ),
        actions: [
          if (f != null) ...[
            OutlinedButton(onPressed: _editar, child: const Text('Editar')),
            const SizedBox(width: 10),
            if (AuthService.instance.isAdmin)
              OutlinedButton(
                onPressed: _eliminar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
                child: const Text('Eliminar'),
              ),
            const SizedBox(width: 20),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              dividerColor: Colors.transparent,
              labelStyle:
                  const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Dados'),
                Tab(text: 'Documentos'),
                Tab(text: 'Presencas'),
                Tab(text: 'Pagamentos'),
              ],
            ),
          ),
        ),
      ),
      body: _aCarregar
          ? const Carregando()
          : f == null
              ? const EstadoVazio(titulo: 'Funcionario nao encontrado')
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _AbaDados(funcionario: f),
                    _AbaDocumentos(
                      documentos: _documentos,
                      aoAnexar: _anexarDocumento,
                      aoActualizar: _carregar,
                    ),
                    _AbaPresencas(resumo: _resumoPresencas, referencia: _agora),
                    _AbaPagamentos(pagamentos: _pagamentos),
                  ],
                ),
    );
  }
}

// --------------------------------------------------------------- aba dados

class _AbaDados extends StatelessWidget {
  final Funcionario funcionario;

  const _AbaDados({required this.funcionario});

  @override
  Widget build(BuildContext context) {
    final moeda = AuthService.instance.moeda;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    Fmt.iniciais(funcionario.nome),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        funcionario.nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${funcionario.codigo}'
                        '${funcionario.cargo != null ? '  -  ${funcionario.cargo}' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Etiqueta.estadoFuncionario(funcionario.estado),
              ],
            ),
            const SizedBox(height: 28),
            _grupo('Identificacao', {
              'Codigo': funcionario.codigo,
              'Bilhete de identidade': funcionario.bi ?? '-',
              'Data de nascimento': Fmt.data(funcionario.dataNascimento),
              'Genero': funcionario.genero ?? '-',
            }),
            _grupo('Contactos', {
              'Telefone': funcionario.telefone ?? '-',
              'Email': funcionario.email ?? '-',
              'Endereco': funcionario.endereco ?? '-',
            }),
            _grupo('Dados profissionais', {
              'Cargo': funcionario.cargo ?? '-',
              'Departamento': funcionario.departamento ?? '-',
              'Data de admissao': Fmt.data(funcionario.dataAdmissao),
              'Data de saida': Fmt.data(funcionario.dataSaida),
            }),
            _grupo('Remuneracao', {
              'Salario base': Fmt.dinheiro(funcionario.salarioBase, moeda),
              'IBAN': funcionario.iban ?? '-',
              'Seguranca social': funcionario.segurancaSocial ?? '-',
            }),
            if (funcionario.observacoes != null)
              _grupo('Observacoes', {'Notas': funcionario.observacoes!}),
          ],
        ),
      ),
    );
  }

  Widget _grupo(String titulo, Map<String, String> campos) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo.toUpperCase(),
            style: const TextStyle(
              fontSize: 11.5,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: campos.entries.map((e) {
                final ultimo = e.key == campos.keys.last;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: ultimo
                        ? null
                        : const Border(
                            bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 200,
                        child: Text(
                          e.key,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------- aba documentos

class _AbaDocumentos extends StatelessWidget {
  final List<Documento> documentos;
  final VoidCallback aoAnexar;
  final VoidCallback aoActualizar;

  const _AbaDocumentos({
    required this.documentos,
    required this.aoAnexar,
    required this.aoActualizar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 16),
          child: SecaoTitulo(
            titulo: 'Documentos',
            descricao:
                'Contratos, bilhete de identidade, certificados e outros ficheiros',
            accoes: [
              ElevatedButton(
                onPressed: aoAnexar,
                child: const Text('Anexar documento'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: documentos.isEmpty
              ? EstadoVazio(
                  titulo: 'Sem documentos anexados',
                  descricao:
                      'Os ficheiros anexados sao copiados para a pasta da '
                      'aplicacao e ficam disponiveis mesmo sem internet.',
                  accao: ElevatedButton(
                    onPressed: aoAnexar,
                    child: const Text('Anexar documento'),
                  ),
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  itemCount: documentos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final d = documentos[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file_outlined,
                              size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.titulo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  d.ficheiroNome,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              d.tipo,
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Validade: ${Fmt.data(d.dataValidade)}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final r = await FuncionarioService.instance
                                  .abrirDocumento(d);
                              if (!context.mounted) return;
                              if (!r.ok) {
                                mostrarAviso(context, r.erro!, erro: true);
                              }
                            },
                            child: const Text('Abrir'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final ok = await confirmar(
                                context,
                                titulo: 'Eliminar documento',
                                mensagem:
                                    'O ficheiro sera removido da pasta da aplicacao.',
                                textoConfirmar: 'Eliminar',
                                destrutivo: true,
                              );
                              if (!ok) return;
                              await FuncionarioService.instance
                                  .eliminarDocumento(d);
                              aoActualizar();
                            },
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

class _DialogoDocumento extends StatefulWidget {
  final String nomeFicheiro;

  const _DialogoDocumento({required this.nomeFicheiro});

  @override
  State<_DialogoDocumento> createState() => _DialogoDocumentoState();
}

class _DialogoDocumentoState extends State<_DialogoDocumento> {
  final _titulo = TextEditingController();
  final _observacao = TextEditingController();
  String _tipo = 'Contrato';
  DateTime? _emissao;
  DateTime? _validade;

  static const List<String> _tipos = [
    'Contrato',
    'Bilhete de identidade',
    'Certificado',
    'Curriculo',
    'Atestado medico',
    'Declaracao',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    _titulo.text = widget.nomeFicheiro;
  }

  @override
  void dispose() {
    _titulo.dispose();
    _observacao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detalhes do documento',
          style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CampoTexto(controller: _titulo, rotulo: 'Titulo'),
              const SizedBox(height: 14),
              CampoSeleccao<String>(
                rotulo: 'Tipo',
                valor: _tipo,
                itens: _tipos
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                aoMudar: (v) => setState(() => _tipo = v ?? 'Outro'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CampoData(
                      rotulo: 'Data de emissao',
                      valor: _emissao,
                      aoMudar: (d) => setState(() => _emissao = d),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CampoData(
                      rotulo: 'Data de validade',
                      valor: _validade,
                      aoMudar: (d) => setState(() => _validade = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CampoTexto(
                controller: _observacao,
                rotulo: 'Observacao',
                linhas: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'titulo': _titulo.text,
            'tipo': _tipo,
            'emissao': _emissao == null ? null : Fmt.iso(_emissao!),
            'validade': _validade == null ? null : Fmt.iso(_validade!),
            'observacao':
                _observacao.text.trim().isEmpty ? null : _observacao.text.trim(),
          }),
          child: const Text('Anexar'),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ aba presencas

class _AbaPresencas extends StatelessWidget {
  final Map<String, int> resumo;
  final DateTime referencia;

  const _AbaPresencas({required this.resumo, required this.referencia});

  @override
  Widget build(BuildContext context) {
    final total = resumo.values.fold<int>(0, (a, b) => a + b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SecaoTitulo(
            titulo: 'Resumo de ${Fmt.nomeMes(referencia.month)} de ${referencia.year}',
            descricao: 'Total de dias registados: $total',
          ),
          const SizedBox(height: 20),
          if (total == 0)
            const EstadoVazio(
              titulo: 'Sem registos neste mes',
              descricao:
                  'Use o separador Presencas do menu lateral para marcar a folha mensal.',
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: EstadoPresenca.todos.map((estado) {
                return SizedBox(
                  width: 190,
                  child: CartaoIndicador(
                    titulo: EstadoPresenca.rotulo(estado),
                    valor: '${resumo[estado] ?? 0}',
                    detalhe: 'dias',
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------- aba pagamentos

class _AbaPagamentos extends StatelessWidget {
  final List<Pagamento> pagamentos;

  const _AbaPagamentos({required this.pagamentos});

  @override
  Widget build(BuildContext context) {
    final moeda = AuthService.instance.moeda;

    if (pagamentos.isEmpty) {
      return const EstadoVazio(
        titulo: 'Sem pagamentos registados',
        descricao:
            'Gere a folha de pagamento no separador Pagamentos do menu lateral.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SecaoTitulo(
            titulo: 'Historico de pagamentos',
            descricao: 'Valores liquidos por mes',
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: pagamentos.map((p) {
                final ultimo = p == pagamentos.last;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    border: ultimo
                        ? null
                        : const Border(
                            bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${Fmt.nomeMes(p.mes)} ${p.ano}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Ganhos: ${Fmt.numero(p.totalGanhos)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Descontos: ${Fmt.numero(p.totalDescontos)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          Fmt.dinheiro(p.liquido, moeda),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 90,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Etiqueta.estadoPagamento(p.estado),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
