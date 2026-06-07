import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/selector_fecha.dart';
import '../data/pagos_repository.dart';

const _metodos = {
  'efectivo': 'Efectivo',
  'tarjeta': 'Tarjeta',
  'transferencia': 'Transferencia',
  'yape_plin': 'Yape / Plin',
};

class PagosScreen extends ConsumerWidget {
  const PagosScreen({super.key});

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _elegir(BuildContext context, WidgetRef ref, bool esDesde) async {
    final (desde, hasta) = ref.read(filtroPagosProvider);
    final f = await seleccionarFecha(
      context,
      primera: DateTime(2020),
      ultima: DateTime.now(),
      titulo: esDesde ? 'Desde' : 'Hasta',
    );
    if (f == null) return;
    ref.read(filtroPagosProvider.notifier).state =
        esDesde ? (_fmt(f), hasta) : (desde, _fmt(f));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(pagosProvider);
    final (desde, hasta) = ref.watch(filtroPagosProvider);

    return AppPage(
      titulo: 'Pagos',
      subtitulo: 'Historial de ingresos del gimnasio',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _FiltroFecha(
                  etiqueta: 'Desde',
                  valor: desde,
                  onTap: () => _elegir(context, ref, true)),
              const SizedBox(width: 12),
              _FiltroFecha(
                  etiqueta: 'Hasta',
                  valor: hasta,
                  onTap: () => _elegir(context, ref, false)),
              const SizedBox(width: 12),
              if (desde.isNotEmpty || hasta.isNotEmpty)
                TextButton.icon(
                  onPressed: () =>
                      ref.read(filtroPagosProvider.notifier).state = ('', ''),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Limpiar'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.textoSecundario),
                ),
              const Spacer(),
              estado.maybeWhen(
                data: (r) => _TotalChip(total: r.total),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          estado.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => const Text('No se pudieron cargar los pagos',
                style: TextStyle(color: AppColors.textoSecundario)),
            data: (r) {
              if (r.pagos.isEmpty) {
                return const Text('No hay pagos en este periodo.',
                    style: TextStyle(color: AppColors.textoSecundario));
              }
              return AppTabla(
                columnas: const [
                  ColumnaTabla('SOCIO', flex: 3),
                  ColumnaTabla('PLAN', flex: 2),
                  ColumnaTabla('MÉTODO', flex: 2),
                  ColumnaTabla('FECHA', flex: 2),
                  ColumnaTabla('MONTO', flex: 1),
                ],
                filas: [
                  for (final p in r.pagos)
                    FilaTabla(celdas: [
                      Text(p.socioNombre,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(p.planNombre,
                          style: const TextStyle(
                              color: AppColors.textoSecundario)),
                      Text(_metodos[p.metodo] ?? p.metodo,
                          style: const TextStyle(
                              color: AppColors.textoSecundario)),
                      Text(
                          '${p.fechaPago.year}-${p.fechaPago.month.toString().padLeft(2, '0')}-${p.fechaPago.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              color: AppColors.textoSecundario)),
                      Text('S/ ${p.monto.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.exito)),
                    ]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FiltroFecha extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final VoidCallback onTap;

  const _FiltroFecha(
      {required this.etiqueta, required this.valor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today_outlined, size: 16),
      label: Text(valor.isEmpty ? etiqueta : '$etiqueta: $valor'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: AppColors.textoPrincipal,
        side: const BorderSide(color: AppColors.borde),
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  final double total;

  const _TotalChip({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.exito.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('Total: ',
              style: TextStyle(color: AppColors.textoSecundario)),
          Text('S/ ${total.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.exito)),
        ],
      ),
    );
  }
}
