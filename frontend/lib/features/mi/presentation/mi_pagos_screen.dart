import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../data/mi_repository.dart';
import 'formato.dart';

const _metodos = {
  'efectivo': 'Efectivo',
  'tarjeta': 'Tarjeta',
  'transferencia': 'Transferencia',
  'yape_plin': 'Yape / Plin',
};

class MiPagosScreen extends ConsumerWidget {
  const MiPagosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagos = ref.watch(misPagosProvider);

    return AppPage(
      titulo: 'Mis pagos',
      subtitulo: 'Historial de tus pagos',
      accion: OutlinedButton.icon(
        onPressed: () => ref.invalidate(misPagosProvider),
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Actualizar'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          foregroundColor: AppColors.textoSecundario,
          side: const BorderSide(color: AppColors.borde),
        ),
      ),
      child: pagos.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => const Text('No se pudieron cargar tus pagos.',
            style: TextStyle(color: AppColors.textoSecundario)),
        data: (lista) {
          if (lista.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.superficie,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borde),
              ),
              child: const Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      color: AppColors.textoSecundario),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text('Aún no tienes pagos registrados.',
                          style:
                              TextStyle(color: AppColors.textoSecundario))),
                ],
              ),
            );
          }
          return Column(
            children: [
              for (final p in lista)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.superficie,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borde),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.planNombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(
                                '${fechaCorta(p.fechaPago)} · ${_metodos[p.metodo] ?? p.metodo}',
                                style: const TextStyle(
                                    color: AppColors.textoSecundario,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      Text('S/ ${p.monto.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.exito)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
