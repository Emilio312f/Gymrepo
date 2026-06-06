import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/personal_repository.dart';
import 'personal_controller.dart';
import 'nuevo_personal_dialog.dart';

class PersonalScreen extends ConsumerWidget {
  const PersonalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(personalControllerProvider);

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
                    Text('Personal',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Cuentas del personal que usa el sistema',
                        style: TextStyle(color: AppColors.textoSecundario)),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => mostrarNuevoPersonalDialog(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Nuevo usuario'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 18)),
              ),
            ],
          ),
        ),
        Expanded(
          child: estado.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('No se pudo cargar el personal',
                  style: TextStyle(color: AppColors.textoSecundario)),
            ),
            data: (lista) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(28, 4, 28, 40),
                  itemCount: lista.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, i) => _StaffCard(usuario: lista[i])
                      .animate()
                      .fadeIn(duration: 250.ms, delay: (i * 40).ms),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StaffCard extends StatelessWidget {
  final UsuarioStaff usuario;

  const _StaffCard({required this.usuario});

  @override
  Widget build(BuildContext context) {
    final esAdmin = usuario.rol == 'admin';
    return Container(
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
              usuario.nombre.isNotEmpty ? usuario.nombre[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppColors.acento, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(usuario.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(usuario.email,
                    style: const TextStyle(
                        color: AppColors.textoSecundario, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (esAdmin ? AppColors.acento : AppColors.textoSecundario)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              esAdmin ? 'Administrador' : 'Recepción',
              style: TextStyle(
                  color: esAdmin ? AppColors.acento : AppColors.textoSecundario,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
