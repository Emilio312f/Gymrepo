import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).usuario;

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
              ],
            ),
            const SizedBox(height: 4),
            const Text('Resumen de tu gimnasio',
                style: TextStyle(color: AppColors.textoSecundario)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: const [
                _MetricCard(
                  icono: Icons.groups_outlined,
                  color: AppColors.acento,
                  valor: '128',
                  etiqueta: 'Socios activos',
                ),
                _MetricCard(
                  icono: Icons.payments_outlined,
                  color: AppColors.exito,
                  valor: 'S/ 9,240',
                  etiqueta: 'Ingresos del mes',
                ),
                _MetricCard(
                  icono: Icons.schedule_outlined,
                  color: AppColors.advertencia,
                  valor: '7',
                  etiqueta: 'Vencen esta semana',
                ),
                _MetricCard(
                  icono: Icons.event_busy_outlined,
                  color: AppColors.peligro,
                  valor: '15',
                  etiqueta: 'Membresías vencidas',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.acentoSuave,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.acento, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Datos de muestra. Las métricas reales se conectarán con la API en la siguiente feature.',
                      style: TextStyle(
                          color: AppColors.textoSecundario, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn(duration: 350.ms),
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
