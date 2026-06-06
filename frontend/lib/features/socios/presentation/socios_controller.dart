import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/socios_repository.dart';

class SociosController extends AsyncNotifier<List<Socio>> {
  @override
  Future<List<Socio>> build() async {
    return ref.read(sociosRepositoryProvider).listar();
  }

  Future<String?> crear({
    required String nombres,
    required String apellidos,
    required String documento,
    String telefono = '',
    String email = '',
    String sexo = '',
    String direccion = '',
    String fechaNacimiento = '',
  }) async {
    try {
      await ref.read(sociosRepositoryProvider).crear(
            nombres: nombres,
            apellidos: apellidos,
            documento: documento,
            telefono: telefono,
            email: email,
            sexo: sexo,
            direccion: direccion,
            fechaNacimiento: fechaNacimiento,
          );
      ref.invalidateSelf();
      await future;
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return 'Ya existe un socio con ese documento';
      }
      return 'No se pudo registrar el socio';
    } catch (_) {
      return 'Ocurrió un error inesperado';
    }
  }
}

final sociosControllerProvider =
    AsyncNotifierProvider<SociosController, List<Socio>>(SociosController.new);
