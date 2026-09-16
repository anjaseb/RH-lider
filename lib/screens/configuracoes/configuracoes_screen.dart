import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final _nome = TextEditingController();
  final _nif = TextEditingController();
  final _endereco = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();

  final _senhaActual = TextEditingController();
  final _senhaNova = TextEditingController();
  final _senhaConfirma = TextEditingController();

  String _moeda = 'AOA';
  bool _aGuardar = false;
  String _pastaDados = '';

  @override
  void initState() {
    super.initState();
    final e = AuthService.instance.empresa;
    if (e != null) {
      _nome.text = e.nome;
      _nif.text = e.nif ?? '';
      _endereco.text = e.endereco ?? '';
      _telefone.text = e.telefone ?? '';
      _email.text = e.email ?? '';
      _moeda = e.moeda;
    }
    _lerPasta();
  }

  Future<void> _lerPasta() async {
    final pasta = await AppDatabase.instance.rootDir;
    if (!mounted) return;
    setState(() => _pastaDados = pasta);
  }

  @override
  void dispose() {
    for (final c in [
      _nome,
      _nif,
      _endereco,
      _telefone,
      _email,
      _senhaActual,
      _senhaNova,
      _senhaConfirma,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardarEmpresa() async {
    setState(() => _aGuardar = true);
    final r = await AuthService.instance.actualizarEmpresa(
      nome: _nome.text,
      nif: _nif.text,
      endereco: _endereco.text,
      telefone: _telefone.text,
      email: _email.text,
      moeda: _moeda,
    );
    if (!mounted) return;
    setState(() => _aGuardar = false);

    if (!r.ok) {
      mostrarAviso(context, r.erro!, erro: true);
      return;
    }
    mostrarAviso(context, 'Dados da empresa actualizados.');
  }

  Future<void> _alterarSenha() async {
    if (_senhaNova.text != _senhaConfirma.text) {
      mostrarAviso(context, 'As senhas nao coincidem.', erro: true);
      return;
    }
    final r = await AuthService.instance
        .alterarSenhaEmpresa(_senhaActual.text, _senhaNova.text);
    if (!mounted) return;

    if (!r.ok) {
      mostrarAviso(context, r.erro!, erro: true);
      return;
    }
    _senhaActual.clear();
    _senhaNova.clear();
    _senhaConfirma.clear();
    mostrarAviso(context, 'Senha da empresa alterada.');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SecaoTitulo(
              titulo: 'Configuracoes',
              descricao: 'Dados da empresa, senha geral e localizacao dos ficheiros',
            ),
            const SizedBox(height: 26),
            _cartao(
              'Dados da empresa',
              [
                CampoTexto(
                    controller: _nome, rotulo: 'Nome', obrigatorio: true),
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
                          DropdownMenuItem(
                              value: 'AOA', child: Text('AOA - Kwanza')),
                          DropdownMenuItem(
                              value: 'USD', child: Text('USD - Dolar')),
                          DropdownMenuItem(
                              value: 'EUR', child: Text('EUR - Euro')),
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
                    Expanded(
                        child:
                            CampoTexto(controller: _telefone, rotulo: 'Telefone')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: CampoTexto(controller: _email, rotulo: 'Email')),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _aGuardar ? null : _guardarEmpresa,
                  child: const Text('Guardar alteracoes'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _cartao(
              'Senha geral da empresa',
              [
                const Text(
                  'Usada para confirmar operacoes sensiveis.',
                  style: TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                CampoTexto(
                  controller: _senhaActual,
                  rotulo: 'Senha actual',
                  senha: true,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CampoTexto(
                        controller: _senhaNova,
                        rotulo: 'Nova senha',
                        senha: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CampoTexto(
                        controller: _senhaConfirma,
                        rotulo: 'Confirmar nova senha',
                        senha: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: _alterarSenha,
                  child: const Text('Alterar senha'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _cartao(
              'Ficheiros e copia de seguranca',
              [
                const Text(
                  'A base de dados e os documentos anexados sao guardados na '
                  'pasta abaixo. Para fazer copia de seguranca, copie esta '
                  'pasta inteira para uma pen ou disco externo com a aplicacao '
                  'fechada.',
                  style: TextStyle(fontSize: 12.5, height: 1.5),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    _pastaDados.isEmpty ? 'A carregar...' : _pastaDados,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartao(String titulo, List<Widget> filhos) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ...filhos,
        ],
      ),
    );
  }
}
