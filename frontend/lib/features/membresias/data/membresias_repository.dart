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

class MembresiaPendiente {
  final bool tienePendiente;
  final String membresiaId;
  final String planNombre;
  final double precio;
  final String estado;
  final String operacion;

  const MembresiaPendiente({
    required this.tienePendiente,
    required this.membresiaId,
    required this.planNombre,
    required this.precio,
    required this.estado,
    required this.operacion,
  });

  bool get enRevision => estado == 'en_revision';

  factory MembresiaPendiente.fromJson(Map<String, dynamic> json) {
    return MembresiaPendiente(
      tienePendiente: json['tiene_pendiente'] as bool? ?? false,
      membresiaId: json['membresia_id'] as String? ?? '',
      planNombre: json['plan_nombre'] as String? ?? '',
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
      estado: json['estado'] as String? ?? '',
      operacion: json['operacion'] as String? ?? '',
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

  Future<MembresiaPendiente> pendiente(String socioId) async {
    final resp = await _dio.get('/socios/$socioId/pendiente');
    return MembresiaPendiente.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> asignarPlan(String socioId, String planId) async {
    await _dio.post('/socios/$socioId/asignar-plan', data: {'plan_id': planId});
  }

  Future<void> confirmarPago(String membresiaId) async {
    await _dio.post('/membresias/$membresiaId/confirmar');
  }

  Future<void> rechazarPago(String membresiaId) async {
    await _dio.post('/membresias/$membresiaId/rechazar');
  }

  Future<void> cancelarPendiente(String membresiaId) async {
    await _dio.post('/membresias/$membresiaId/cancelar');
  }
}

final membresiasRepositoryProvider = Provider<MembresiasRepository>((ref) {
  return MembresiasRepository(ref.watch(dioProvider));
});

final estadoMembresiaProvider =
    FutureProvider.family<EstadoMembresia, String>((ref, socioId) {
  return ref.watch(membresiasRepositoryProvider).estadoActual(socioId);
});

final pendienteAdminProvider =
    FutureProvider.family<MembresiaPendiente, String>((ref, socioId) {
  return ref.watch(membresiasRepositoryProvider).pendiente(socioId);
});
