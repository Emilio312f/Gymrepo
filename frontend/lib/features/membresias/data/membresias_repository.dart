import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class EstadoMembresia {
  final bool tieneMembresia;
  final String planNombre;
  final String fechaInicio;
  final String fechaFin;
  final bool alDia;
  final int diasRestantes;

  const EstadoMembresia({
    required this.tieneMembresia,
    required this.planNombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.alDia,
    required this.diasRestantes,
  });

  factory EstadoMembresia.fromJson(Map<String, dynamic> json) {
    return EstadoMembresia(
      tieneMembresia: json['tiene_membresia'] as bool? ?? false,
      planNombre: json['plan_nombre'] as String? ?? '',
      fechaInicio: json['fecha_inicio'] as String? ?? '',
      fechaFin: json['fecha_fin'] as String? ?? '',
      alDia: json['al_dia'] as bool? ?? false,
      diasRestantes: json['dias_restantes'] as int? ?? 0,
    );
  }
}

class MembresiasRepository {
  final Dio _dio;

  MembresiasRepository(this._dio);

  Future<EstadoMembresia> estadoActual(String socioId) async {
    final resp = await _dio.get('/socios/$socioId/membresia');
    return EstadoMembresia.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> registrarPago(
      String socioId, String planId, String metodo) async {
    await _dio.post('/socios/$socioId/pagos',
        data: {'plan_id': planId, 'metodo': metodo});
  }
}

final membresiasRepositoryProvider = Provider<MembresiasRepository>((ref) {
  return MembresiasRepository(ref.watch(dioProvider));
});

final estadoMembresiaProvider =
    FutureProvider.family<EstadoMembresia, String>((ref, socioId) {
  return ref.watch(membresiasRepositoryProvider).estadoActual(socioId);
});
