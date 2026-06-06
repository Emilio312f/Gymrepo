import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/planes_repository.dart';

class PlanesController extends AsyncNotifier<List<Plan>> {
  @override
  Future<List<Plan>> build() async {
    return ref.read(planesRepositoryProvider).listar();
  }

  Future<String?> crear({
    required String nombre,
    required String descripcion,
    required double precio,
    required int duracionDias,
  }) async {
    try {
      await ref.read(planesRepositoryProvider).crear(
            nombre: nombre,
            descripcion: descripcion,
            precio: precio,
            duracionDias: duracionDias,
          );
      ref.invalidateSelf();
      await future;
      return null;
    } catch (_) {
      return 'No se pudo crear el plan';
    }
  }
}

final planesControllerProvider =
    AsyncNotifierProvider<PlanesController, List<Plan>>(PlanesController.new);

final planesActivosProvider = FutureProvider<List<Plan>>((ref) {
  return ref.watch(planesRepositoryProvider).listar(soloActivos: true);
});
