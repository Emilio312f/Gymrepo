import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shell/app_shell.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/socios/presentation/socios_screen.dart';
import '../../features/socios/presentation/socio_detalle_screen.dart';
import '../../features/planes/presentation/planes_screen.dart';
import '../../features/personal/presentation/personal_screen.dart';
import '../../features/asistencia/presentation/asistencia_screen.dart';
import '../../features/pagos/presentation/pagos_screen.dart';
import '../../features/mi/presentation/mi_membresia_screen.dart';
import '../../features/mi/presentation/mi_asistencias_screen.dart';
import '../../features/mi/presentation/mi_pagos_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final logueado = auth.logueado;
      final esSocio = auth.usuario?.rol == 'socio';
      final loc = state.matchedLocation;
      final enLogin = loc == '/login';

      if (!logueado && !enLogin) return '/login';
      if (logueado && enLogin) return esSocio ? '/mi' : '/home';
      // Cada rol vive en su propia zona: el socio sólo en /mi/*, el staff fuera.
      if (logueado && esSocio && !loc.startsWith('/mi')) return '/mi';
      if (logueado && !esSocio && loc.startsWith('/mi')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
              path: '/home',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HomeScreen())),
          GoRoute(
              path: '/socios',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SociosScreen())),
          GoRoute(
              path: '/socios/:id',
              pageBuilder: (context, state) => NoTransitionPage(
                  child: SocioDetalleScreen(
                      socioId: state.pathParameters['id']!))),
          GoRoute(
              path: '/planes',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: PlanesScreen())),
          GoRoute(
              path: '/personal',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: PersonalScreen())),
          GoRoute(
              path: '/asistencia',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: AsistenciaScreen())),
          GoRoute(
              path: '/pagos',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: PagosScreen())),
          GoRoute(
              path: '/mi',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: MiMembresiaScreen())),
          GoRoute(
              path: '/mi/asistencias',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: MiAsistenciasScreen())),
          GoRoute(
              path: '/mi/pagos',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: MiPagosScreen())),
        ],
      ),
    ],
  );
});
