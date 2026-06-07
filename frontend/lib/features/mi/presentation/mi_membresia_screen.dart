import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../membresias/data/membresias_repository.dart';
import '../../planes/data/planes_repository.dart';
import '../data/mi_repository.dart';

final _planesActivosProvider = FutureProvider<List<Plan>>((ref) {
  return ref.watch(planesRepositoryProvider).listar(soloActivos: true);
});

class MiMembresiaScreen extends ConsumerWidget {
  const MiMembresiaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).usuario;
    final membresia = ref.watch(miMembresiaProvider);

    return AppPage(
      titulo: 'Hola, ${usuario?.nombre ?? ''}',
      subtitulo: 'Tu membresía y próximo pago',
      accion: OutlinedButton.icon(
        onPressed: () {
          ref.invalidate(miMembresiaProvider);
          ref.invalidate(_planesActivosProvider);
        },
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Actualizar'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          foregroundColor: AppColors.textoSecundario,
          side: const BorderSide(color: AppColors.borde),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          membresia.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const _Aviso(
                'No se pudo cargar tu membresía. Inténtalo de nuevo.'),
            data: (m) => _TarjetaMembresia(estado: m),
          ),
          const SizedBox(height: 24),
          const Text('Planes disponibles',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ref.watch(_planesActivosProvider).when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    const _Aviso('No se pudieron cargar los planes.'),
                data: (planes) {
                  if (planes.isEmpty) {
                    return const Text('Tu gimnasio aún no publica planes.',
                        style: TextStyle(color: AppColors.textoSecundario));
                  }
                  return Column(
                    children: [
                      for (final p in planes) _TarjetaPlan(plan: p),
                    ],
                  );
                },
              ),
        ],
      ),
    );
  }
}

class _TarjetaMembresia extends StatelessWidget {
  final EstadoMembresia estado;

  const _TarjetaMembresia({required this.estado});

  @override
  Widget build(BuildContext context) {
    if (!estado.tieneMembresia) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borde),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.textoSecundario),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                  'Aún no tienes una membresía activa. Acércate a recepción para registrar tu pago.',
                  style: TextStyle(color: AppColors.textoSecundario)),
            ),
          ],
        ),
      );
    }

    final color = estado.alDia ? AppColors.exito : AppColors.peligro;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(estado.alDia ? 'AL DÍA' : 'VENCIDO',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(estado.planNombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _fila(estado.alDia ? 'Tu plan vence el' : 'Venció el',
              estado.fechaFin),
          _fila(
            estado.alDia ? 'Días restantes' : 'Vencido hace',
            estado.alDia
                ? '${estado.diasRestantes} días'
                : '${-estado.diasRestantes} días',
          ),
          if (!estado.alDia) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.peligro.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                  'Tu membresía está vencida. Renueva tu pago en recepción para seguir entrenando.',
                  style: TextStyle(color: AppColors.peligro, fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fila(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
              width: 160,
              child: Text(k,
                  style: const TextStyle(
                      color: AppColors.textoSecundario, fontSize: 14))),
          Text(v,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TarjetaPlan extends StatelessWidget {
  final Plan plan;

  const _TarjetaPlan({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(plan.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text('${plan.duracionDias} días',
                    style: const TextStyle(
                        color: AppColors.textoSecundario, fontSize: 13)),
              ],
            ),
          ),
          Text('S/ ${plan.precio.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.acento)),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final String texto;

  const _Aviso(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.peligro.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: AppColors.peligro, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(texto,
                  style: const TextStyle(
                      color: AppColors.textoSecundario, fontSize: 13))),
        ],
      ),
    );
  }
}
