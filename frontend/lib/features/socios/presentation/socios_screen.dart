import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../data/socios_repository.dart';
import 'socios_controller.dart';
import 'nuevo_socio_dialog.dart';

class SociosScreen extends ConsumerWidget {
  const SociosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(sociosControllerProvider);

    return AppPage(
      titulo: 'Socios',
      subtitulo: 'Miembros registrados en tu gimnasio',
      accion: FilledButton.icon(
        onPressed: () => mostrarNuevoSocioDialog(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Nuevo socio'),
        style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 18)),
      ),
      child: estado.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const _Vacio(texto: 'No se pudieron cargar los socios'),
        data: (socios) {
          if (socios.isEmpty) {
            return const _Vacio(
                texto: 'Aún no hay socios. Registra el primero con "Nuevo socio".');
          }
          return AppTabla(
            columnas: const [
              ColumnaTabla('SOCIO', flex: 3),
              ColumnaTabla('DOCUMENTO', flex: 2),
              ColumnaTabla('CÓDIGO', flex: 2),
              ColumnaTabla('ESTADO', flex: 2),
            ],
            filas: [
              for (final s in socios) _filaSocio(context, s),
            ],
          );
        },
      ),
    );
  }

  FilaTabla _filaSocio(BuildContext context, Socio s) {
    return FilaTabla(
      onTap: () => context.go('/socios/${s.id}'),
      celdas: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.acentoSuave,
              child: Text(s.iniciales,
                  style: const TextStyle(
                      color: AppColors.acento,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(s.nombreCompleto,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        Text('DNI ${s.documento}',
            style: const TextStyle(color: AppColors.textoSecundario)),
        Text(s.codigo, style: const TextStyle(color: AppColors.textoSecundario)),
        Align(
          alignment: Alignment.centerLeft,
          child: _Chip(
            texto: s.activo ? 'Activo' : 'Inactivo',
            color: s.activo ? AppColors.exito : AppColors.textoSecundario,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String texto;
  final Color color;

  const _Chip({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto,
          style:
              TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _Vacio extends StatelessWidget {
  final String texto;

  const _Vacio({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_add_outlined,
              size: 44, color: AppColors.textoSecundario),
          const SizedBox(height: 14),
          Text(texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textoSecundario)),
        ],
      ),
    );
  }
}
