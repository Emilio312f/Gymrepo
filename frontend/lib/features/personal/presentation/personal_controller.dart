import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/personal_repository.dart';

class PersonalController extends AsyncNotifier<List<UsuarioStaff>> {
  @override
  Future<List<UsuarioStaff>> build() async {
    return ref.read(personalRepositoryProvider).listar();
  }

  Future<String?> crear({
    required String nombre,
    required String email,
    required String password,
    required String rol,
  }) async {
    try {
      await ref.read(personalRepositoryProvider).crear(
            nombre: nombre,
            email: email,
            password: password,
            rol: rol,
          );
      ref.invalidateSelf();
      await future;
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return 'Ese email ya está registrado';
      }
      return 'No se pudo crear el usuario';
    } catch (_) {
      return 'Ocurrió un error inesperado';
    }
  }
}

final personalControllerProvider =
    AsyncNotifierProvider<PersonalController, List<UsuarioStaff>>(
        PersonalController.new);
