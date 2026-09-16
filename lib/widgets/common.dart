import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Componentes visuais reutilizados em toda a aplicacao.

class SecaoTitulo extends StatelessWidget {
  final String titulo;
  final String? descricao;
  final List<Widget> accoes;

  const SecaoTitulo({
    super.key,
    required this.titulo,
    this.descricao,
    this.accoes = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (descricao != null) ...[
                const SizedBox(height: 4),
                Text(
                  descricao!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        ...accoes,
      ],
    );
  }
}

class CartaoIndicador extends StatelessWidget {
  final String titulo;
  final String valor;
  final String? detalhe;
  final Color? cor;

  const CartaoIndicador({
    super.key,
    required this.titulo,
    required this.valor,
    this.detalhe,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titulo.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: cor ?? AppColors.textPrimary,
            ),
          ),
          if (detalhe != null) ...[
            const SizedBox(height: 6),
            Text(
              detalhe!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class Etiqueta extends StatelessWidget {
  final String texto;
  final Color cor;

  const Etiqueta({super.key, required this.texto, required this.cor});

  factory Etiqueta.estadoFuncionario(String estado) {
    switch (estado) {
      case 'activo':
        return Etiqueta(texto: 'Activo', cor: AppColors.success);
      case 'suspenso':
        return Etiqueta(texto: 'Suspenso', cor: AppColors.warning);
      case 'inactivo':
        return Etiqueta(texto: 'Inactivo', cor: AppColors.textSecondary);
      default:
        return Etiqueta(texto: estado, cor: AppColors.textSecondary);
    }
  }

  factory Etiqueta.estadoPagamento(String estado) {
    if (estado == 'pago') {
      return Etiqueta(texto: 'Pago', cor: AppColors.success);
    }
    return Etiqueta(texto: 'Pendente', cor: AppColors.warning);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: cor,
        ),
      ),
    );
  }
}

class EstadoVazio extends StatelessWidget {
  final String titulo;
  final String? descricao;
  final Widget? accao;

  const EstadoVazio({
    super.key,
    required this.titulo,
    this.descricao,
    this.accao,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (descricao != null) ...[
              const SizedBox(height: 6),
              Text(
                descricao!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (accao != null) ...[
              const SizedBox(height: 18),
              accao!,
            ],
          ],
        ),
      ),
    );
  }
}

class CampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String rotulo;
  final String? dica;
  final bool obrigatorio;
  final bool senha;
  final int linhas;
  final TextInputType? tipo;
  final List<TextInputFormatter>? formatadores;
  final bool activo;

  const CampoTexto({
    super.key,
    required this.controller,
    required this.rotulo,
    this.dica,
    this.obrigatorio = false,
    this.senha = false,
    this.linhas = 1,
    this.tipo,
    this.formatadores,
    this.activo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              rotulo,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            if (obrigatorio)
              const Text(
                ' *',
                style: TextStyle(color: AppColors.danger, fontSize: 12.5),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: senha,
          enabled: activo,
          maxLines: senha ? 1 : linhas,
          keyboardType: tipo,
          inputFormatters: formatadores,
          decoration: InputDecoration(hintText: dica),
        ),
      ],
    );
  }
}

class CampoSeleccao<T> extends StatelessWidget {
  final String rotulo;
  final T valor;
  final List<DropdownMenuItem<T>> itens;
  final ValueChanged<T?> aoMudar;

  const CampoSeleccao({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.itens,
    required this.aoMudar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: valor,
          items: itens,
          onChanged: aoMudar,
          isExpanded: true,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}

/// Campo de data que abre o calendario do sistema.
class CampoData extends StatelessWidget {
  final String rotulo;
  final DateTime? valor;
  final ValueChanged<DateTime?> aoMudar;
  final bool permiteLimpar;

  const CampoData({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.aoMudar,
    this.permiteLimpar = true,
  });

  @override
  Widget build(BuildContext context) {
    final texto = valor == null
        ? 'Seleccionar data'
        : '${valor!.day.toString().padLeft(2, '0')}/'
            '${valor!.month.toString().padLeft(2, '0')}/${valor!.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final escolhida = await showDatePicker(
              context: context,
              initialDate: valor ?? DateTime.now(),
              firstDate: DateTime(1940),
              lastDate: DateTime(2100),
            );
            if (escolhida != null) aoMudar(escolhida);
          },
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    texto,
                    style: TextStyle(
                      fontSize: 14,
                      color: valor == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (valor != null && permiteLimpar)
                  InkWell(
                    onTap: () => aoMudar(null),
                    child: const Icon(Icons.close,
                        size: 16, color: AppColors.textSecondary),
                  )
                else
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Mostra uma mensagem curta no fundo da janela.
void mostrarAviso(BuildContext context, String mensagem, {bool erro = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? AppColors.danger : AppColors.textPrimary,
        duration: const Duration(seconds: 3),
      ),
    );
}

/// Caixa de confirmacao antes de accoes destrutivas.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String textoConfirmar = 'Confirmar',
  bool destrutivo = false,
}) async {
  final resposta = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo, style: const TextStyle(fontSize: 16)),
      content: Text(mensagem, style: const TextStyle(fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: destrutivo
              ? ElevatedButton.styleFrom(backgroundColor: AppColors.danger)
              : null,
          child: Text(textoConfirmar),
        ),
      ],
    ),
  );
  return resposta ?? false;
}

class Carregando extends StatelessWidget {
  const Carregando({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2.4),
      ),
    );
  }
}
