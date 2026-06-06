import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/socios_repository.dart';
import 'socios_controller.dart';
import 'nuevo_socio_dialog.dart';

class SociosScreen extends ConsumerWidget {
  const SociosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(sociosControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 16),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Socios',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Miembros registrados en tu gimnasio',
                        style: TextStyle(color: AppColors.textoSecundario)),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => mostrarNuevoSocioDialog(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Nuevo socio'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: estado.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _Mensaje(
              icono: Icons.cloud_off,
              texto: 'No se pudieron cargar los socios',
              accion: () => ref.invalidate(sociosControllerProvider),
            ),
            data: (socios) {
              if (socios.isEmpty) {
                return const _Mensaje(
                  icono: Icons.group_add_outlined,
                  texto:
                      'Aún no hay socios.\nRegistra el primero con "Nuevo socio".',
                );
              }
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(28, 4, 28, 40),
                    itemCount: socios.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) => _SocioCard(socio: socios[i])
                        .animate()
                        .fadeIn(duration: 250.ms, delay: (i * 40).ms),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SocioCard extends StatelessWidget {
  final Socio socio;

  const _SocioCard({required this.socio});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.superficie,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.go('/socios/${socio.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.acentoSuave,
            child: Text(
              socio.iniciales,
              style: const TextStyle(
                  color: AppColors.acento, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(socio.nombreCompleto,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text('${socio.codigo} · DNI ${socio.documento}',
                    style: const TextStyle(
                        color: AppColors.textoSecundario, fontSize: 13)),
              ],
            ),
          ),
          _EstadoChip(activo: socio.activo),
        ],
      ),
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final bool activo;

  const _EstadoChip({required this.activo});

  @override
  Widget build(BuildContext context) {
    final color = activo ? AppColors.exito : AppColors.textoSecundario;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style:
            TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback? accion;

  const _Mensaje({required this.icono, required this.texto, this.accion});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 48, color: AppColors.textoSecundario),
          const SizedBox(height: 16),
          Text(texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textoSecundario)),
          if (accion != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(
                onPressed: accion, child: const Text('Reintentar')),
          ],
        ],
      ),
    );
  }
}
