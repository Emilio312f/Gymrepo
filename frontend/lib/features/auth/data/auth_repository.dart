import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class UsuarioActual {
  final String id;
  final String nombre;
  final String email;
  final String rol;

  const UsuarioActual({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  factory UsuarioActual.fromJson(Map<String, dynamic> json) {
    return UsuarioActual(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rol: json['rol'] as String? ?? '',
    );
  }
}

class ResultadoLogin {
  final String token;
  final UsuarioActual usuario;

  const ResultadoLogin(this.token, this.usuario);
}

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<ResultadoLogin> login(String slug, String email, String password) async {
    final resp = await _dio.post('/login', data: {
      'slug': slug,
      'email': email,
      'password': password,
    });
    final data = resp.data as Map<String, dynamic>;
    return ResultadoLogin(
      data['token'] as String,
      UsuarioActual.fromJson(data['usuario'] as Map<String, dynamic>),
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});
