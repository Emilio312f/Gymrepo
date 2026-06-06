import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../../features/auth/presentation/auth_controller.dart';

class Modulo {
  final String titulo;
  final IconData icono;
  final String? ruta;

  const Modulo(this.titulo, this.icono, [this.ruta]);

  bool get habilitado => ruta != null;
}

const List<Modulo> modulos = [
  Modulo('Dashboard', Icons.dashboard_outlined, '/home'),
  Modulo('Socios', Icons.groups_outlined, '/socios'),
  Modulo('Planes', Icons.card_membership_outlined),
  Modulo('Pagos', Icons.payments_outlined),
  Modulo('Asistencia', Icons.how_to_reg_outlined),
  Modulo('Personal', Icons.badge_outlined),
];

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final esAncho = MediaQuery.of(context).size.width >= 820;

    if (esAncho) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(width: 252, child: _NavContent()),
            Container(width: 1, color: AppColors.borde),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.superficie,
        surfaceTintColor: AppColors.superficie,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.borde)),
        iconTheme: const IconThemeData(color: AppColors.textoPrincipal),
        title: const Text('GymControl',
            style: TextStyle(
                color: AppColors.textoPrincipal,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
      ),
      drawer: const Drawer(
          backgroundColor: AppColors.superficie, child: _NavContent()),
      body: child,
    );
  }
}

class _NavContent extends ConsumerWidget {
  const _NavContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final usuario = ref.watch(authControllerProvider).usuario;

    return Container(
      color: AppColors.superficie,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.acento,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fitness_center,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('GymControl',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borde),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                for (final m in modulos)
                  _NavTile(
                      modulo: m,
                      activo: m.ruta != null &&
                          (location == m.ruta ||
                              location.startsWith('${m.ruta}/'))),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borde),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.acentoSuave,
                  child: Text(
                    (usuario?.nombre.isNotEmpty ?? false)
                        ? usuario!.nombre[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppColors.acento, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(usuario?.nombre ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(usuario?.rol ?? '',
                          style: const TextStyle(
                              color: AppColors.textoSecundario, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar sesión',
                  color: AppColors.textoSecundario,
                  icon: const Icon(Icons.logout, size: 20),
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).cerrarSesion();
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final Modulo modulo;
  final bool activo;

  const _NavTile({required this.modulo, required this.activo});

  @override
  Widget build(BuildContext context) {
    final colorTexto = activo
        ? AppColors.acento
        : modulo.habilitado
            ? AppColors.textoPrincipal
            : AppColors.textoSecundario;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: activo ? AppColors.acentoSuave : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: modulo.habilitado
              ? () {
                  final scaffold = Scaffold.maybeOf(context);
                  if (scaffold?.isDrawerOpen ?? false) Navigator.pop(context);
                  if (!activo) context.go(modulo.ruta!);
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(modulo.icono,
                    size: 20,
                    color: activo ? AppColors.acento : colorTexto),
                const SizedBox(width: 12),
                Text(modulo.titulo,
                    style: TextStyle(
                        color: colorTexto,
                        fontWeight:
                            activo ? FontWeight.w600 : FontWeight.w500)),
                if (!modulo.habilitado) ...[
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.fondo,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Pronto',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textoSecundario)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
