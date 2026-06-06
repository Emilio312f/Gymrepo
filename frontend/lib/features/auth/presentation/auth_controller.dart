import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';

class AuthState {
  final bool cargando;
  final String? error;
  final UsuarioActual? usuario;

  const AuthState({this.cargando = false, this.error, this.usuario});

  bool get logueado => usuario != null;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> login(String slug, String email, String password) async {
    state = const AuthState(cargando: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final res = await repo.login(slug.trim(), email.trim(), password);
      ref.read(tokenProvider.notifier).state = res.token;
      state = AuthState(usuario: res.usuario);
      return true;
    } on DioException catch (e) {
      final mensaje = e.response?.statusCode == 401
          ? 'Credenciales inválidas'
          : 'No se pudo conectar con el servidor';
      state = AuthState(error: mensaje);
      return false;
    } catch (_) {
      state = const AuthState(error: 'Ocurrió un error inesperado');
      return false;
    }
  }

  void cerrarSesion() {
    ref.read(tokenProvider.notifier).state = null;
    state = const AuthState();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
