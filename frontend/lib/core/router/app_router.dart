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
              path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(
              path: '/socios',
              builder: (context, state) => const SociosScreen()),
          GoRoute(
              path: '/socios/:id',
              builder: (context, state) =>
                  SocioDetalleScreen(socioId: state.pathParameters['id']!)),
          GoRoute(
              path: '/planes',
              builder: (context, state) => const PlanesScreen()),
          GoRoute(
              path: '/personal',
              builder: (context, state) => const PersonalScreen()),
        ],
      ),
    ],
  );
});
