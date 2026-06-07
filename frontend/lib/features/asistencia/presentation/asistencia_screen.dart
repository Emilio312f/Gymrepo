import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../data/asistencia_repository.dart';

class AsistenciaScreen extends ConsumerStatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  ConsumerState<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends ConsumerState<AsistenciaScreen> {
  final _consulta = TextEditingController();
  ResultadoAcceso? _resultado;
  bool _buscando = false;
  String? _error;

  @override
  void dispose() {
    _consulta.dispose();
    super.dispose();
  }

  Future<void> _validar() async {
    final q = _consulta.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _buscando = true;
      _error = null;
      _resultado = null;
    });
    try {
      final r = await ref.read(asistenciaRepositoryProvider).validar(q);
      ref.invalidate(asistenciasDelDiaProvider);
      if (!mounted) return;
      setState(() {
        _resultado = r;
        _buscando = false;
      });
      _consulta.clear();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _buscando = false;
        _error = e.response?.statusCode == 404
            ? 'No se encontró un socio con ese DNI o código.'
            : 'No se pudo validar el acceso.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final asistencias = ref.watch(asistenciasDelDiaProvider);

    return AppPage(
      titulo: 'Control de acceso',
      subtitulo: 'Valida el ingreso de los socios por DNI o código',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _consulta,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z]'))
                  ],
                  onSubmitted: (_) => _validar(),
                  decoration: const InputDecoration(
                    hintText: 'DNI o código del socio',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _buscando ? null : _validar,
                style: FilledButton.styleFrom(
                    minimumSize: const Size(140, 52)),
                child: _buscando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white))
                    : const Text('Validar'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(color: AppColors.peligro)),
          ],
          if (_resultado != null) ...[
            const SizedBox(height: 20),
            _TarjetaResultado(resultado: _resultado!)
                .animate()
                .fadeIn(duration: 250.ms)
                .scaleXY(begin: 0.98, end: 1),
          ],
          const SizedBox(height: 32),
          const Text('Ingresos de hoy',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          asistencias.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => const Text('No se pudo cargar la asistencia',
                style: TextStyle(color: AppColors.textoSecundario)),
            data: (lista) {
              if (lista.isEmpty) {
                return const Text('Aún no hay ingresos registrados hoy.',
                    style: TextStyle(color: AppColors.textoSecundario));
              }
              return AppTabla(
                columnas: const [
                  ColumnaTabla('SOCIO', flex: 3),
                  ColumnaTabla('DOCUMENTO', flex: 2),
                  ColumnaTabla('HORA', flex: 1),
                ],
                filas: [
                  for (final a in lista)
                    FilaTabla(celdas: [
                      Text(a.nombreCompleto,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('DNI ${a.documento}',
                          style: const TextStyle(
                              color: AppColors.textoSecundario)),
                      Text(a.hora,
                          style: const TextStyle(
                              color: AppColors.textoSecundario)),
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

class _TarjetaResultado extends StatelessWidget {
  final ResultadoAcceso resultado;

  const _TarjetaResultado({required this.resultado});

  @override
  Widget build(BuildContext context) {
    final permitido = resultado.permitido;
    final color = permitido ? AppColors.exito : AppColors.peligro;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(permitido ? Icons.check_rounded : Icons.close_rounded,
                color: Colors.white, size: 38),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(permitido ? 'ACCESO PERMITIDO' : 'ACCESO DENEGADO',
                    style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(resultado.nombreCompleto,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${resultado.codigo} · DNI ${resultado.documento}',
                    style: const TextStyle(
                        color: AppColors.textoSecundario, fontSize: 13)),
                const SizedBox(height: 10),
                if (permitido)
                  Text(
                      '${resultado.planNombre} · vence el ${resultado.fechaFin} (${resultado.diasRestantes} días)',
                      style: const TextStyle(
                          color: AppColors.textoPrincipal, fontSize: 14))
                else
                  Text(resultado.motivo,
                      style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
