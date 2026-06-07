import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/mi_repository.dart';

Future<void> mostrarPagarDialog(
    BuildContext context, MembresiaPendiente pendiente) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PagarDialog(pendiente: pendiente),
  );
}

class _PagarDialog extends ConsumerStatefulWidget {
  final MembresiaPendiente pendiente;

  const _PagarDialog({required this.pendiente});

  @override
  ConsumerState<_PagarDialog> createState() => _PagarDialogState();
}

class _PagarDialogState extends ConsumerState<_PagarDialog> {
  final _operacion = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _operacion.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_operacion.text.trim().isEmpty) {
      setState(() => _error = 'Ingresa el N° de operación de tu Yape');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(miRepositoryProvider).pagarPendiente(_operacion.text.trim());
      ref.invalidate(miPendienteProvider);
      if (mounted) Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Listo. Tu pago quedó en revisión.')));
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'No se pudo registrar tu pago. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pendiente;
    return AlertDialog(
      backgroundColor: AppColors.superficie,
      surfaceTintColor: AppColors.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Pagar con Yape',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.acentoSuave,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(p.planNombre,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Text('S/ ${p.precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppColors.acento)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('1. Yapea el monto al número de tu gimnasio.\n'
                '2. Copia el N° de operación que te da Yape.\n'
                '3. Pégalo abajo y envíalo para que el gimnasio lo valide.',
                style:
                    TextStyle(color: AppColors.textoSecundario, fontSize: 13)),
            const SizedBox(height: 16),
            const Text('N° de operación',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _operacion,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: 'Ej. 00123456'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  style:
                      const TextStyle(color: AppColors.peligro, fontSize: 13)),
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
                    onPressed: _guardando ? null : _enviar,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46)),
                    child: _guardando
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: Colors.white))
                        : const Text('Enviar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
