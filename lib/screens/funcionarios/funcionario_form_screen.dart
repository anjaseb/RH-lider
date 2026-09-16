import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/funcionario_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/common.dart';

/// Formulario de registo e edicao de funcionarios.
class FuncionarioFormScreen extends StatefulWidget {
  final Funcionario? funcionario;

  const FuncionarioFormScreen({super.key, this.funcionario});

  @override
  State<FuncionarioFormScreen> createState() => _FuncionarioFormScreenState();
}

class _FuncionarioFormScreenState extends State<FuncionarioFormScreen> {
  final _codigo = TextEditingController();
  final _nome = TextEditingController();
  final _bi = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _endereco = TextEditingController();
  final _cargo = TextEditingController();
  final _departamento = TextEditingController();
  final _salario = TextEditingController();
  final _iban = TextEditingController();
  final _segurancaSocial = TextEditingController();
  final _observacoes = TextEditingController();

  DateTime? _dataNascimento;
  DateTime? _dataAdmissao;
  DateTime? _dataSaida;
  String _genero = 'Masculino';
  String _estado = 'activo';
  bool _aGuardar = false;

  bool get _edicao => widget.funcionario != null;

  @override
  void initState() {
    super.initState();
    final f = widget.funcionario;
    if (f != null) {
      _codigo.text = f.codigo;
      _nome.text = f.nome;
      _bi.text = f.bi ?? '';
      _telefone.text = f.telefone ?? '';
      _email.text = f.email ?? '';
      _endereco.text = f.endereco ?? '';
      _cargo.text = f.cargo ?? '';
      _departamento.text = f.departamento ?? '';
      _salario.text = f.salarioBase == 0 ? '' : f.salarioBase.toString();
      _iban.text = f.iban ?? '';
      _segurancaSocial.text = f.segurancaSocial ?? '';
      _observacoes.text = f.observacoes ?? '';
      _dataNascimento = Fmt.paraData(f.dataNascimento);
      _dataAdmissao = Fmt.paraData(f.dataAdmissao);
      _dataSaida = Fmt.paraData(f.dataSaida);
      _genero = f.genero ?? 'Masculino';
      _estado = f.estado;
    } else {
      _gerarCodigo();
      _dataAdmissao = DateTime.now();
    }
  }

  Future<void> _gerarCodigo() async {
    final codigo = await FuncionarioService.instance.proximoCodigo();
    if (!mounted) return;
    setState(() => _codigo.text = codigo);
  }

  @override
  void dispose() {
    for (final c in [
      _codigo,
      _nome,
      _bi,
      _telefone,
      _email,
      _endereco,
      _cargo,
      _departamento,
      _salario,
      _iban,
      _segurancaSocial,
      _observacoes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _aGuardar = true);

    final funcionario = Funcionario(
      id: widget.funcionario?.id,
      codigo: _codigo.text.trim(),
      nome: _nome.text.trim(),
      bi: _texto(_bi),
      dataNascimento:
          _dataNascimento == null ? null : Fmt.iso(_dataNascimento!),
      genero: _genero,
      telefone: _texto(_telefone),
      email: _texto(_email),
      endereco: _texto(_endereco),
      cargo: _texto(_cargo),
      departamento: _texto(_departamento),
      dataAdmissao: _dataAdmissao == null ? null : Fmt.iso(_dataAdmissao!),
      dataSaida: _dataSaida == null ? null : Fmt.iso(_dataSaida!),
      salarioBase: Fmt.lerNumero(_salario.text),
      iban: _texto(_iban),
      segurancaSocial: _texto(_segurancaSocial),
      estado: _estado,
      observacoes: _texto(_observacoes),
    );

    final resultado = await FuncionarioService.instance.guardar(funcionario);
    if (!mounted) return;
    setState(() => _aGuardar = false);

    if (!resultado.ok) {
      mostrarAviso(context, resultado.erro!, erro: true);
      return;
    }
    mostrarAviso(context,
        _edicao ? 'Funcionario actualizado.' : 'Funcionario registado.');
    Navigator.pop(context, true);
  }

  String? _texto(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_edicao ? 'Editar funcionario' : 'Registar funcionario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _seccao('Identificacao'),
                    Row(
                      children: [
                        Expanded(
                          child: CampoTexto(
                            controller: _codigo,
                            rotulo: 'Codigo / ID',
                            obrigatorio: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: CampoTexto(
                            controller: _nome,
                            rotulo: 'Nome completo',
                            obrigatorio: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: CampoTexto(
                            controller: _bi,
                            rotulo: 'Bilhete de identidade',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CampoData(
                            rotulo: 'Data de nascimento',
                            valor: _dataNascimento,
                            aoMudar: (d) => setState(() => _dataNascimento = d),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CampoSeleccao<String>(
                            rotulo: 'Genero',
                            valor: _genero,
                            itens: const [
                              DropdownMenuItem(
                                  value: 'Masculino', child: Text('Masculino')),
                              DropdownMenuItem(
                                  value: 'Feminino', child: Text('Feminino')),
                            ],
                            aoMudar: (v) =>
                                setState(() => _genero = v ?? 'Masculino'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _seccao('Contactos'),
                    Row(
                      children: [
                        Expanded(
                          child: CampoTexto(
                            controller: _telefone,
                            rotulo: 'Telefone',
                            tipo: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CampoTexto(
                            controller: _email,
                            rotulo: 'Email',
                            tipo: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    CampoTexto(controller: _endereco, rotulo: 'Endereco'),
                    const SizedBox(height: 24),
                    _seccao('Dados profissionais'),
                    Row(
                      children: [
                        Expanded(
                          child: CampoTexto(controller: _cargo, rotulo: 'Cargo'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CampoTexto(
                            controller: _departamento,
                            rotulo: 'Departamento',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CampoSeleccao<String>(
                            rotulo: 'Estado',
                            valor: _estado,
                            itens: const [
                              DropdownMenuItem(
                                  value: 'activo', child: Text('Activo')),
                              DropdownMenuItem(
                                  value: 'suspenso', child: Text('Suspenso')),
                              DropdownMenuItem(
                                  value: 'inactivo', child: Text('Inactivo')),
                            ],
                            aoMudar: (v) =>
                                setState(() => _estado = v ?? 'activo'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: CampoData(
                            rotulo: 'Data de admissao',
                            valor: _dataAdmissao,
                            aoMudar: (d) => setState(() => _dataAdmissao = d),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CampoData(
                            rotulo: 'Data de saida',
                            valor: _dataSaida,
                            aoMudar: (d) => setState(() => _dataSaida = d),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _seccao('Remuneracao'),
                    Row(
                      children: [
                        Expanded(
                          child: CampoTexto(
                            controller: _salario,
                            rotulo: 'Salario base',
                            dica: 'Ex: 150000',
                            tipo: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CampoTexto(
                            controller: _iban,
                            rotulo: 'IBAN / conta bancaria',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CampoTexto(
                            controller: _segurancaSocial,
                            rotulo: 'Seguranca social',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _seccao('Observacoes'),
                    CampoTexto(
                      controller: _observacoes,
                      rotulo: 'Notas internas',
                      linhas: 4,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _aGuardar
                              ? null
                              : () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _aGuardar ? null : _guardar,
                          child: _aGuardar
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_edicao
                                  ? 'Guardar alteracoes'
                                  : 'Registar funcionario'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccao(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
