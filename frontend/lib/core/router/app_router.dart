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

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final logueado = ref.read(authControllerProvider).logueado;
      final enLogin = state.matchedLocation == '/login';
      if (!logueado && !enLogin) return '/login';
      if (logueado && enLogin) return '/home';
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
        ],
      ),
    ],
  );
});
