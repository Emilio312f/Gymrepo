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
    String accesoEmail = '',
    String accesoPassword = '',
  }) async {
    final repo = ref.read(sociosRepositoryProvider);
    Socio socio;
    try {
      socio = await repo.crear(
        nombres: nombres,
        apellidos: apellidos,
        documento: documento,
        telefono: telefono,
        email: email,
        sexo: sexo,
        direccion: direccion,
        fechaNacimiento: fechaNacimiento,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return 'Ya existe un socio con ese documento';
      }
      return 'No se pudo registrar el socio';
    } catch (_) {
      return 'Ocurrió un error inesperado';
    }

    String? aviso;
    if (accesoPassword.isNotEmpty) {
      try {
        await repo.crearAcceso(socio.id, accesoEmail, accesoPassword);
      } on DioException catch (e) {
        aviso = e.response?.statusCode == 409
            ? 'Socio creado, pero ese correo ya tiene acceso. Genera el acceso desde su ficha.'
            : 'Socio creado, pero no se pudo crear el acceso. Genéralo desde su ficha.';
      } catch (_) {
        aviso = 'Socio creado, pero no se pudo crear el acceso. Genéralo desde su ficha.';
      }
    }

    ref.invalidateSelf();
    await future;
    return aviso;
  }
}

final sociosControllerProvider =
    AsyncNotifierProvider<SociosController, List<Socio>>(SociosController.new);

final socioDetalleProvider = FutureProvider.family<Socio, String>((ref, id) {
  return ref.watch(sociosRepositoryProvider).obtener(id);
});
