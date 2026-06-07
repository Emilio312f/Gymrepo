import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../data/planes_repository.dart';
import 'planes_controller.dart';
import 'nuevo_plan_dialog.dart';

class PlanesScreen extends ConsumerWidget {
  const PlanesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(planesControllerProvider);

    return AppPage(
      titulo: 'Planes',
      subtitulo: 'Planes de membresía que ofrece tu gimnasio',
      accion: FilledButton.icon(
        onPressed: () => mostrarNuevoPlanDialog(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Nuevo plan'),
        style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 18)),
      ),
      child: estado.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Text('No se pudieron cargar los planes',
              style: TextStyle(color: AppColors.textoSecundario)),
        ),
        data: (planes) {
          if (planes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.card_membership_outlined,
                        size: 44, color: AppColors.textoSecundario),
                    SizedBox(height: 14),
                    Text('Aún no hay planes. Crea el primero con "Nuevo plan".',
                        style: TextStyle(color: AppColors.textoSecundario)),
                  ],
                ),
              ),
            );
          }
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (var i = 0; i < planes.length; i++)
                _PlanCard(plan: planes[i])
                    .animate()
                    .fadeIn(duration: 250.ms, delay: (i * 50).ms),
            ],
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan.nombre,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${plan.duracionDias} días',
              style: const TextStyle(
                  color: AppColors.textoSecundario, fontSize: 13)),
          const SizedBox(height: 14),
          Text('S/ ${plan.precio.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.acento)),
          if (plan.descripcion.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(plan.descripcion,
                style: const TextStyle(
                    color: AppColors.textoSecundario, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
