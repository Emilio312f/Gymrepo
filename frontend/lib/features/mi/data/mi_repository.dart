import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../membresias/data/membresias_repository.dart';

class MiAsistencia {
  final DateTime fechaHora;

  const MiAsistencia({required this.fechaHora});

  factory MiAsistencia.fromJson(Map<String, dynamic> json) {
    return MiAsistencia(
      fechaHora:
          DateTime.tryParse(json['fecha_hora'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }
}

class MiPago {
  final String planNombre;
  final double monto;
  final String metodo;
  final DateTime fechaPago;

  const MiPago({
    required this.planNombre,
    required this.monto,
    required this.metodo,
    required this.fechaPago,
  });

  factory MiPago.fromJson(Map<String, dynamic> json) {
    return MiPago(
      planNombre: json['plan_nombre'] as String? ?? '',
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      metodo: json['metodo'] as String? ?? '',
      fechaPago:
          DateTime.tryParse(json['fecha_pago'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }
}

class MiRepository {
  final Dio _dio;

  MiRepository(this._dio);

  Future<EstadoMembresia> miMembresia() async {
    final resp = await _dio.get('/mi/membresia');
    return EstadoMembresia.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<List<MiAsistencia>> misAsistencias() async {
    final resp = await _dio.get('/mi/asistencias');
    final lista =
        (resp.data['asistencias'] as List).cast<Map<String, dynamic>>();
    return lista.map(MiAsistencia.fromJson).toList();
  }

  Future<List<MiPago>> misPagos() async {
    final resp = await _dio.get('/mi/pagos');
    final lista = (resp.data['pagos'] as List).cast<Map<String, dynamic>>();
    return lista.map(MiPago.fromJson).toList();
  }
}

final miRepositoryProvider = Provider<MiRepository>((ref) {
  return MiRepository(ref.watch(dioProvider));
});

final miMembresiaProvider = FutureProvider<EstadoMembresia>((ref) {
  return ref.watch(miRepositoryProvider).miMembresia();
});

final misAsistenciasProvider = FutureProvider<List<MiAsistencia>>((ref) {
  return ref.watch(miRepositoryProvider).misAsistencias();
});

final misPagosProvider = FutureProvider<List<MiPago>>((ref) {
  return ref.watch(miRepositoryProvider).misPagos();
});
