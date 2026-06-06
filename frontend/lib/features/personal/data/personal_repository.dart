import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class UsuarioStaff {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final bool activo;

  const UsuarioStaff({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.activo,
  });

  factory UsuarioStaff.fromJson(Map<String, dynamic> json) {
    return UsuarioStaff(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rol: json['rol'] as String? ?? '',
      activo: json['activo'] as bool? ?? false,
    );
  }
}

class PersonalRepository {
  final Dio _dio;

  PersonalRepository(this._dio);

  Future<List<UsuarioStaff>> listar() async {
    final resp = await _dio.get('/personal');
    final lista = (resp.data['personal'] as List).cast<Map<String, dynamic>>();
    return lista.map(UsuarioStaff.fromJson).toList();
  }

  Future<UsuarioStaff> crear({
    required String nombre,
    required String email,
    required String password,
    required String rol,
  }) async {
    final resp = await _dio.post('/personal', data: {
      'nombre': nombre,
      'email': email,
      'password': password,
      'rol': rol,
    });
    return UsuarioStaff.fromJson(resp.data as Map<String, dynamic>);
  }
}

final personalRepositoryProvider = Provider<PersonalRepository>((ref) {
  return PersonalRepository(ref.watch(dioProvider));
});
