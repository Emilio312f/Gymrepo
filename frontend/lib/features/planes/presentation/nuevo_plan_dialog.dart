import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'planes_controller.dart';

Future<void> mostrarNuevoPlanDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _NuevoPlanDialog(),
  );
}

class _NuevoPlanDialog extends ConsumerStatefulWidget {
  const _NuevoPlanDialog();

  @override
  ConsumerState<_NuevoPlanDialog> createState() => _NuevoPlanDialogState();
}

class _NuevoPlanDialogState extends ConsumerState<_NuevoPlanDialog> {
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _precio = TextEditingController();
  final _duracion = TextEditingController(text: '30');

  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _precio.dispose();
    _duracion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final precio = double.tryParse(_precio.text.trim());
    final duracion = int.tryParse(_duracion.text.trim());
    if (_nombre.text.trim().isEmpty ||
        precio == null ||
        precio <= 0 ||
        duracion == null ||
        duracion <= 0) {
      setState(() => _error = 'Nombre, precio y duración válidos son obligatorios');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final err = await ref.read(planesControllerProvider.notifier).crear(
          nombre: _nombre.text.trim(),
          descripcion: _descripcion.text.trim(),
          precio: precio,
          duracionDias: duracion,
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
      title: const Text('Nuevo plan',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _lbl('Nombre'),
              const SizedBox(height: 6),
              TextField(
                  controller: _nombre,
                  decoration:
                      const InputDecoration(hintText: 'Mensual, Trimestral...')),
              const SizedBox(height: 16),
              _lbl('Descripción'),
              const SizedBox(height: 6),
              TextField(
                  controller: _descripcion,
                  decoration: const InputDecoration(hintText: 'Opcional')),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _lbl('Precio (S/)'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _precio,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'))
                          ],
                          decoration: const InputDecoration(hintText: '80.00'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _lbl('Duración (días)'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _duracion,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(hintText: '30'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.peligro, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _guardando ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        foregroundColor: AppColors.textoSecundario,
                        side: const BorderSide(color: AppColors.borde),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _guardando ? null : _guardar,
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46)),
                      child: _guardando
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2, color: Colors.white))
                          : const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lbl(String t) => Text(t,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600));
}
