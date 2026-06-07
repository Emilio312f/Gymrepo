import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../data/mi_repository.dart';
import 'formato.dart';

class MiAsistenciasScreen extends ConsumerWidget {
  const MiAsistenciasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asistencias = ref.watch(misAsistenciasProvider);

    return AppPage(
      titulo: 'Mis asistencias',
      subtitulo: 'Tus últimos ingresos al gimnasio',
      accion: OutlinedButton.icon(
        onPressed: () => ref.invalidate(misAsistenciasProvider),
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Actualizar'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          foregroundColor: AppColors.textoSecundario,
          side: const BorderSide(color: AppColors.borde),
        ),
      ),
      child: asistencias.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => const Text('No se pudieron cargar tus asistencias.',
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
                  Icon(Icons.event_busy_outlined,
                      color: AppColors.textoSecundario),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text('Todavía no registras ingresos al gimnasio.',
                          style:
                              TextStyle(color: AppColors.textoSecundario))),
                ],
              ),
            );
          }
          return Column(
            children: [
              for (final a in lista)
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
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.acentoSuave,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.how_to_reg_outlined,
                            color: AppColors.acento, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(fechaLarga(a.fechaHora),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                      Text(hora(a.fechaHora),
                          style: const TextStyle(
                              color: AppColors.textoSecundario, fontSize: 14)),
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
