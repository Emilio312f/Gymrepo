import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class Pago {
  final String id;
  final String socioNombre;
  final String documento;
  final String planNombre;
  final double monto;
  final String metodo;
  final DateTime fechaPago;

  const Pago({
    required this.id,
    required this.socioNombre,
    required this.documento,
    required this.planNombre,
    required this.monto,
    required this.metodo,
    required this.fechaPago,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      id: json['id'] as String? ?? '',
      socioNombre: json['socio_nombre'] as String? ?? '',
      documento: json['documento'] as String? ?? '',
      planNombre: json['plan_nombre'] as String? ?? '',
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      metodo: json['metodo'] as String? ?? '',
      fechaPago: DateTime.parse(json['fecha_pago'] as String).toLocal(),
    );
  }
}

class ResultadoPagos {
  final List<Pago> pagos;
  final double total;

  const ResultadoPagos({required this.pagos, required this.total});
}

class PagosRepository {
  final Dio _dio;

  PagosRepository(this._dio);

  Future<ResultadoPagos> listar({String desde = '', String hasta = ''}) async {
    final resp = await _dio.get('/pagos', queryParameters: {
      if (desde.isNotEmpty) 'desde': desde,
      if (hasta.isNotEmpty) 'hasta': hasta,
    });
    final lista = (resp.data['pagos'] as List).cast<Map<String, dynamic>>();
    return ResultadoPagos(
      pagos: lista.map(Pago.fromJson).toList(),
      total: (resp.data['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

final pagosRepositoryProvider = Provider<PagosRepository>((ref) {
  return PagosRepository(ref.watch(dioProvider));
});

final filtroPagosProvider = StateProvider<(String, String)>((ref) => ('', ''));

final pagosProvider = FutureProvider<ResultadoPagos>((ref) {
  final (desde, hasta) = ref.watch(filtroPagosProvider);
  return ref.watch(pagosRepositoryProvider).listar(desde: desde, hasta: hasta);
});
