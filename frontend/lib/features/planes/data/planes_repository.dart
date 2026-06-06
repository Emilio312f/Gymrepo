import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class Plan {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int duracionDias;
  final bool activo;

  const Plan({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.duracionDias,
    required this.activo,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
      duracionDias: json['duracion_dias'] as int? ?? 0,
      activo: json['activo'] as bool? ?? false,
    );
  }
}

class PlanesRepository {
  final Dio _dio;

  PlanesRepository(this._dio);

  Future<List<Plan>> listar({bool soloActivos = false}) async {
    final resp = await _dio.get('/planes',
        queryParameters: soloActivos ? {'activos': 'true'} : null);
    final lista = (resp.data['planes'] as List).cast<Map<String, dynamic>>();
    return lista.map(Plan.fromJson).toList();
  }

  Future<Plan> crear({
    required String nombre,
    required String descripcion,
    required double precio,
    required int duracionDias,
  }) async {
    final resp = await _dio.post('/planes', data: {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'duracion_dias': duracionDias,
    });
    return Plan.fromJson(resp.data as Map<String, dynamic>);
  }
}

final planesRepositoryProvider = Provider<PlanesRepository>((ref) {
  return PlanesRepository(ref.watch(dioProvider));
});
