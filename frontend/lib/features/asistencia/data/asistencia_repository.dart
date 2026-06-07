import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class ResultadoAcceso {
  final bool permitido;
  final String motivo;
  final String nombreCompleto;
  final String documento;
  final String codigo;
  final bool tieneMembresia;
  final String planNombre;
  final String fechaFin;
  final int diasRestantes;

  const ResultadoAcceso({
    required this.permitido,
    required this.motivo,
    required this.nombreCompleto,
    required this.documento,
    required this.codigo,
    required this.tieneMembresia,
    required this.planNombre,
    required this.fechaFin,
    required this.diasRestantes,
  });

  factory ResultadoAcceso.fromJson(Map<String, dynamic> json) {
    final socio = json['socio'] as Map<String, dynamic>? ?? {};
    final mem = json['membresia'] as Map<String, dynamic>? ?? {};
    final nombres = socio['nombres'] as String? ?? '';
    final apellidos = socio['apellidos'] as String? ?? '';
    return ResultadoAcceso(
      permitido: json['permitido'] as bool? ?? false,
      motivo: json['motivo'] as String? ?? '',
      nombreCompleto: '$nombres $apellidos'.trim(),
      documento: socio['documento'] as String? ?? '',
      codigo: socio['codigo'] as String? ?? '',
      tieneMembresia: mem['tiene'] as bool? ?? false,
      planNombre: mem['plan_nombre'] as String? ?? '',
      fechaFin: mem['fecha_fin'] as String? ?? '',
      diasRestantes: mem['dias_restantes'] as int? ?? 0,
    );
  }
}

class Asistencia {
  final DateTime fechaHora;
  final String nombres;
  final String apellidos;
  final String documento;
  final String codigo;

  const Asistencia({
    required this.fechaHora,
    required this.nombres,
    required this.apellidos,
    required this.documento,
    required this.codigo,
  });

  String get nombreCompleto => '$nombres $apellidos';
  String get hora =>
      '${fechaHora.hour.toString().padLeft(2, '0')}:${fechaHora.minute.toString().padLeft(2, '0')}';

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      fechaHora: DateTime.parse(json['fecha_hora'] as String).toLocal(),
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      documento: json['documento'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
    );
  }
}

class AsistenciaRepository {
  final Dio _dio;

  AsistenciaRepository(this._dio);

  Future<ResultadoAcceso> validar(String consulta) async {
    final resp = await _dio
        .post('/acceso/validar', data: {'consulta': consulta.trim()});
    return ResultadoAcceso.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<List<Asistencia>> listarDelDia() async {
    final resp = await _dio.get('/asistencias');
    final lista =
        (resp.data['asistencias'] as List).cast<Map<String, dynamic>>();
    return lista.map(Asistencia.fromJson).toList();
  }
}

final asistenciaRepositoryProvider = Provider<AsistenciaRepository>((ref) {
  return AsistenciaRepository(ref.watch(dioProvider));
});

final asistenciasDelDiaProvider = FutureProvider<List<Asistencia>>((ref) {
  return ref.watch(asistenciaRepositoryProvider).listarDelDia();
});
