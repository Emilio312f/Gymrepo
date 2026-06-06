import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class DashboardStats {
  final int sociosActivos;
  final int sociosTotal;
  final double ingresosMes;
  final int vencenSemana;
  final int vencidas;

  const DashboardStats({
    required this.sociosActivos,
    required this.sociosTotal,
    required this.ingresosMes,
    required this.vencenSemana,
    required this.vencidas,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      sociosActivos: json['socios_activos'] as int? ?? 0,
      sociosTotal: json['socios_total'] as int? ?? 0,
      ingresosMes: (json['ingresos_mes'] as num?)?.toDouble() ?? 0,
      vencenSemana: json['vencen_semana'] as int? ?? 0,
      vencidas: json['vencidas'] as int? ?? 0,
    );
  }
}

class StatsRepository {
  final Dio _dio;

  StatsRepository(this._dio);

  Future<DashboardStats> dashboard() async {
    final resp = await _dio.get('/stats/dashboard');
    return DashboardStats.fromJson(resp.data as Map<String, dynamic>);
  }
}

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.watch(dioProvider));
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) {
  return ref.watch(statsRepositoryProvider).dashboard();
});
