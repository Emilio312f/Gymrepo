import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class Socio {
  final String id;
  final String codigo;
  final String nombres;
  final String apellidos;
  final String documento;
  final String telefono;
  final String email;
  final String sexo;
  final String direccion;
  final String fechaNacimiento;
  final bool activo;

  const Socio({
    required this.id,
    required this.codigo,
    required this.nombres,
    required this.apellidos,
    required this.documento,
    required this.telefono,
    required this.email,
    required this.sexo,
    required this.direccion,
    required this.fechaNacimiento,
    required this.activo,
  });

  String get nombreCompleto => '$nombres $apellidos';

  String get iniciales {
    final n = nombres.isNotEmpty ? nombres[0] : '';
    final a = apellidos.isNotEmpty ? apellidos[0] : '';
    return '$n$a'.toUpperCase();
  }

  factory Socio.fromJson(Map<String, dynamic> json) {
    return Socio(
      id: json['id'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      documento: json['documento'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      email: json['email'] as String? ?? '',
      sexo: json['sexo'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      fechaNacimiento: json['fecha_nacimiento'] as String? ?? '',
      activo: json['activo'] as bool? ?? false,
    );
  }
}

class SociosRepository {
  final Dio _dio;

  SociosRepository(this._dio);

  Future<List<Socio>> listar() async {
    final resp = await _dio.get('/socios');
    final lista = (resp.data['socios'] as List).cast<Map<String, dynamic>>();
    return lista.map(Socio.fromJson).toList();
  }

  Future<Socio> obtener(String id) async {
    final resp = await _dio.get('/socios/$id');
    return Socio.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Socio> actualizar({
    required String id,
    required String nombres,
    required String apellidos,
    required String documento,
    String telefono = '',
    String email = '',
    String sexo = '',
    String direccion = '',
    String fechaNacimiento = '',
  }) async {
    final resp = await _dio.put('/socios/$id', data: {
      'nombres': nombres,
      'apellidos': apellidos,
      'documento': documento,
      'telefono': telefono,
      'email': email,
      'sexo': sexo,
      'direccion': direccion,
      'fecha_nacimiento': fechaNacimiento,
    });
    return Socio.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> cambiarEstado(String id, bool activo) async {
    await _dio.patch('/socios/$id/estado', data: {'activo': activo});
  }

  Future<Socio> crear({
    required String nombres,
    required String apellidos,
    required String documento,
    String telefono = '',
    String email = '',
    String sexo = '',
    String direccion = '',
    String fechaNacimiento = '',
  }) async {
    final resp = await _dio.post('/socios', data: {
      'nombres': nombres,
      'apellidos': apellidos,
      'documento': documento,
      'telefono': telefono,
      'email': email,
      'sexo': sexo,
      'direccion': direccion,
      'fecha_nacimiento': fechaNacimiento,
    });
    return Socio.fromJson(resp.data as Map<String, dynamic>);
  }
}

final sociosRepositoryProvider = Provider<SociosRepository>((ref) {
  return SociosRepository(ref.watch(dioProvider));
});
