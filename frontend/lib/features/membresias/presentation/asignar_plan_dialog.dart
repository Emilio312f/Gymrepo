import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../planes/data/planes_repository.dart';
import '../../planes/presentation/planes_controller.dart';
import '../data/membresias_repository.dart';

Future<void> mostrarAsignarPlanDialog(BuildContext context, String socioId) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AsignarPlanDialog(socioId: socioId),
  );
}

class _AsignarPlanDialog extends ConsumerStatefulWidget {
  final String socioId;

  const _AsignarPlanDialog({required this.socioId});

  @override
  ConsumerState<_AsignarPlanDialog> createState() => _AsignarPlanDialogState();
}

class _AsignarPlanDialogState extends ConsumerState<_AsignarPlanDialog> {
  String? _planId;
  bool _guardando = false;
  String? _error;

  Future<void> _guardar() async {
    if (_planId == null) {
      setState(() => _error = 'Selecciona un plan');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(membresiasRepositoryProvider)
          .asignarPlan(widget.socioId, _planId!);
      ref.invalidate(pendienteAdminProvider(widget.socioId));
      if (mounted) Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Plan asignado. El socio debe pagarlo desde su app.')));
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.response?.statusCode == 409
            ? 'El socio ya tiene un plan pendiente de pago'
            : 'No se pudo asignar el plan';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final planes = ref.watch(planesActivosProvider);

    return AlertDialog(
      backgroundColor: AppColors.superficie,
      surfaceTintColor: AppColors.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Asignar plan',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: planes.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator())),
          error: (e, _) => const Text('No se pudieron cargar los planes'),
          data: (lista) {
            if (lista.isEmpty) {
              return const Text(
                  'Primero crea un plan en el módulo Planes para poder asignarlo.');
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                    'El plan quedará pendiente de pago. El socio lo pagará por Yape desde su app y tú confirmas la operación.',
                    style: TextStyle(color: AppColors.textoSecundario)),
                const SizedBox(height: 18),
                _lbl('Plan'),
                const SizedBox(height: 6),
                AppDropdown<String>(
                  value: _planId,
                  hint: 'Seleccionar',
                  items: [
                    for (final Plan p in lista)
                      DropdownMenuItem(
                        value: p.id,
                        child: Text(
                            '${p.nombre} · S/ ${p.precio.toStringAsFixed(2)} · ${p.duracionDias} días'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _planId = v),
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
                        onPressed: _guardando
                            ? null
                            : () => Navigator.of(context).pop(),
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
                            : const Text('Asignar'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _lbl(String t) => Text(t,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600));
}
