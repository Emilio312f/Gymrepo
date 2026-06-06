import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dashboard/data/stats_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).usuario;
    final stats = ref.watch(dashboardStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Hola, ${usuario?.nombre ?? ''}',
                  style:
                      const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.acentoSuave,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    usuario?.rol ?? '',
                    style: const TextStyle(
                        color: AppColors.acento,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: () => ref.invalidate(dashboardStatsProvider),
                  icon: const Icon(Icons.refresh,
                      color: AppColors.textoSecundario),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Resumen de tu gimnasio',
                style: TextStyle(color: AppColors.textoSecundario)),
            const SizedBox(height: 24),
            stats.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _BannerInfo(
                color: AppColors.peligro,
                icono: Icons.cloud_off,
                texto: 'No se pudieron cargar las estadísticas.',
              ),
              data: (s) => Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _MetricCard(
                    icono: Icons.groups_outlined,
                    color: AppColors.acento,
                    valor: '${s.sociosActivos}',
                    etiqueta: 'Socios activos',
                  ),
                  _MetricCard(
                    icono: Icons.payments_outlined,
                    color: AppColors.exito,
                    valor: 'S/ ${s.ingresosMes.toStringAsFixed(2)}',
                    etiqueta: 'Ingresos del mes',
                  ),
                  _MetricCard(
                    icono: Icons.schedule_outlined,
                    color: AppColors.advertencia,
                    valor: '${s.vencenSemana}',
                    etiqueta: 'Vencen esta semana',
                  ),
                  _MetricCard(
                    icono: Icons.event_busy_outlined,
                    color: AppColors.peligro,
                    valor: '${s.vencidas}',
                    etiqueta: 'Membresías vencidas',
                  ),
                ].animate(interval: 60.ms).fadeIn(duration: 250.ms),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerInfo extends StatelessWidget {
  final Color color;
  final IconData icono;
  final String texto;

  const _BannerInfo(
      {required this.color, required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 20),
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

class _MetricCard extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String valor;
  final String etiqueta;

  const _MetricCard({
    required this.icono,
    required this.color,
    required this.valor,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 224,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(valor,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(etiqueta,
              style: const TextStyle(
                  color: AppColors.textoSecundario, fontSize: 13)),
        ],
      ),
    );
  }
}
