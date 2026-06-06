import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class DatosPersona {
  final String nombres;
  final String apellidos;
  final String nombreCompleto;

  const DatosPersona({
    required this.nombres,
    required this.apellidos,
    required this.nombreCompleto,
  });
}

class DocumentoRepository {
  final Dio _dio;

  DocumentoRepository(this._dio);

  Future<DatosPersona> consultarDni(String dni) async {
    final resp = await _dio.get('/documento/$dni');
    final data = resp.data as Map<String, dynamic>;
    final paterno = (data['apellido_paterno'] as String? ?? '').trim();
    final materno = (data['apellido_materno'] as String? ?? '').trim();
    return DatosPersona(
      nombres: (data['nombres'] as String? ?? '').trim(),
      apellidos: '$paterno $materno'.trim(),
      nombreCompleto: (data['nombre_completo'] as String? ?? '').trim(),
    );
  }
}

final documentoRepositoryProvider = Provider<DocumentoRepository>((ref) {
  return DocumentoRepository(ref.watch(dioProvider));
});
