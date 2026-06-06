import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'socios_controller.dart';

Future<void> mostrarNuevoSocioDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => const Dialog(
      backgroundColor: AppColors.superficie,
      child: _NuevoSocioForm(),
    ),
  );
}

class _NuevoSocioForm extends ConsumerStatefulWidget {
  const _NuevoSocioForm();

  @override
  ConsumerState<_NuevoSocioForm> createState() => _NuevoSocioFormState();
}

class _NuevoSocioFormState extends ConsumerState<_NuevoSocioForm> {
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
      setState(() => _error = 'Código, nombres, apellidos y documento son obligatorios');
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nuevo socio',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Registra un nuevo miembro del gimnasio',
                style: TextStyle(color: AppColors.textoSecundario)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _Campo(
                      etiqueta: 'Código',
                      controller: _codigo,
                      hint: 'A001'),
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
            _Campo(etiqueta: 'Nombres', controller: _nombres, hint: 'Ana María'),
            const SizedBox(height: 16),
            _Campo(etiqueta: 'Apellidos', controller: _apellidos, hint: 'Pérez'),
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
                  style: const TextStyle(color: AppColors.peligro, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _guardando ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar',
                      style: TextStyle(color: AppColors.textoSecundario)),
                ),
                const SizedBox(width: 8),
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
            ),
          ],
        ),
      ),
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
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
