import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'socios_controller.dart';

Future<void> mostrarNuevoSocioDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _NuevoSocioDialog(),
  );
}

class _NuevoSocioDialog extends ConsumerStatefulWidget {
  const _NuevoSocioDialog();

  @override
  ConsumerState<_NuevoSocioDialog> createState() => _NuevoSocioDialogState();
}

class _NuevoSocioDialogState extends ConsumerState<_NuevoSocioDialog> {
  final _codigo = TextEditingController();
  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _documento = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();

  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _codigo.dispose();
    _nombres.dispose();
    _apellidos.dispose();
    _documento.dispose();
    _telefono.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_codigo.text.trim().isEmpty ||
        _nombres.text.trim().isEmpty ||
        _apellidos.text.trim().isEmpty ||
        _documento.text.trim().isEmpty) {
      setState(() =>
          _error = 'Código, nombres, apellidos y documento son obligatorios');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final err = await ref.read(sociosControllerProvider.notifier).crear(
          codigo: _codigo.text.trim(),
          nombres: _nombres.text.trim(),
          apellidos: _apellidos.text.trim(),
          documento: _documento.text.trim(),
          telefono: _telefono.text.trim(),
          email: _email.text.trim(),
        );

    if (!mounted) return;

    if (err == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _guardando = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.superficie,
      surfaceTintColor: AppColors.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Nuevo socio',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Campo(
                        etiqueta: 'Código', controller: _codigo, hint: 'A001'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Campo(
                        etiqueta: 'Documento',
                        controller: _documento,
                        hint: 'DNI'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Campo(
                  etiqueta: 'Nombres',
                  controller: _nombres,
                  hint: 'Ana María'),
              const SizedBox(height: 16),
              _Campo(
                  etiqueta: 'Apellidos',
                  controller: _apellidos,
                  hint: 'Pérez Gómez'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Campo(
                        etiqueta: 'Teléfono',
                        controller: _telefono,
                        hint: 'Opcional'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Campo(
                        etiqueta: 'Correo',
                        controller: _email,
                        hint: 'Opcional'),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.peligro, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.textoSecundario)),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: Colors.white))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _Campo extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;
  final String hint;

  const _Campo({
    required this.etiqueta,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta,
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
