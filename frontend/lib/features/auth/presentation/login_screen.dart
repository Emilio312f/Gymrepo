import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _slug = TextEditingController(text: 'powerfit');
  final _email = TextEditingController(text: 'diego@powerfit.com');
  final _password = TextEditingController(text: 'secreto123');
  bool _ocultarPassword = true;

  @override
  void dispose() {
    _slug.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final ok = await ref.read(authControllerProvider.notifier).login(
          _slug.text,
          _email.text,
          _password.text,
        );
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(authControllerProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.acento,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.fitness_center,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'GymControl',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  'Inicia sesión',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Accede al panel de tu gimnasio',
                  style: TextStyle(color: AppColors.textoSecundario),
                ),
                const SizedBox(height: 32),
                _Campo(
                  etiqueta: 'Gimnasio',
                  child: TextField(
                    controller: _slug,
                    decoration: const InputDecoration(hintText: 'powerfit'),
                  ),
                ),
                const SizedBox(height: 18),
                _Campo(
                  etiqueta: 'Correo',
                  child: TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(hintText: 'tu@correo.com'),
                  ),
                ),
                const SizedBox(height: 18),
                _Campo(
                  etiqueta: 'Contraseña',
                  child: TextField(
                    controller: _password,
                    obscureText: _ocultarPassword,
                    onSubmitted: (_) => _entrar(),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        iconSize: 20,
                        color: AppColors.textoSecundario,
                        icon: Icon(_ocultarPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(
                            () => _ocultarPassword = !_ocultarPassword),
                      ),
                    ),
                  ),
                ),
                if (estado.error != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.peligro.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.peligro.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.peligro, size: 19),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(estado.error!,
                              style: const TextStyle(
                                  color: AppColors.peligro, fontSize: 13)),
                        ),
                      ],
                    ),
                  ).animate().shake(duration: 400.ms),
                ],
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: estado.cargando ? null : _entrar,
                  child: estado.cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('Continuar'),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).moveY(begin: 12, end: 0),
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final String etiqueta;
  final Widget child;

  const _Campo({required this.etiqueta, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textoPrincipal),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}
