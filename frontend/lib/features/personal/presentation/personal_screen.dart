import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../data/personal_repository.dart';
import 'personal_controller.dart';
import 'nuevo_personal_dialog.dart';

class PersonalScreen extends ConsumerWidget {
  const PersonalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(personalControllerProvider);

    return AppPage(
      titulo: 'Personal',
      subtitulo: 'Cuentas del personal que usa el sistema',
      accion: FilledButton.icon(
        onPressed: () => mostrarNuevoPersonalDialog(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Nuevo usuario'),
        style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 18)),
      ),
      child: estado.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Text('No se pudo cargar el personal',
              style: TextStyle(color: AppColors.textoSecundario)),
        ),
        data: (lista) => AppTabla(
          columnas: const [
            ColumnaTabla('USUARIO', flex: 3),
            ColumnaTabla('CORREO', flex: 3),
            ColumnaTabla('ROL', flex: 2),
          ],
          filas: [
            for (final u in lista) _fila(u),
          ],
        ),
      ),
    );
  }

  FilaTabla _fila(UsuarioStaff u) {
    final esAdmin = u.rol == 'admin';
    return FilaTabla(
      celdas: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.acentoSuave,
              child: Text(
                  u.nombre.isNotEmpty ? u.nombre[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.acento, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(u.nombre,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        Text(u.email,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textoSecundario)),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (esAdmin ? AppColors.acento : AppColors.textoSecundario)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(esAdmin ? 'Administrador' : 'Recepción',
                style: TextStyle(
                    color:
                        esAdmin ? AppColors.acento : AppColors.textoSecundario,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
        ),
      ],
    );
  }
}
