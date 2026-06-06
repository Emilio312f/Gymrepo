import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../membresias/data/membresias_repository.dart';
import '../../membresias/presentation/registrar_pago_dialog.dart';
import '../data/socios_repository.dart';
import 'socios_controller.dart';
import 'editar_socio_dialog.dart';

class SocioDetalleScreen extends ConsumerWidget {
  final String socioId;

  const SocioDetalleScreen({super.key, required this.socioId});

  Future<void> _cambiarEstado(
      BuildContext context, WidgetRef ref, Socio socio) async {
    final desactivar = socio.activo;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.superficie,
        title: Text(desactivar ? 'Deshabilitar socio' : 'Activar socio'),
        content: Text(desactivar
            ? '${socio.nombreCompleto} no podrá acceder, pero su historial se conserva.'
            : '${socio.nombreCompleto} podrá volver a acceder.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmar != true) return;

    await ref.read(sociosRepositoryProvider).cambiarEstado(socio.id, !socio.activo);
    ref.invalidate(socioDetalleProvider(socio.id));
    ref.invalidate(sociosControllerProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(socioDetalleProvider(socioId));

    return estado.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.textoSecundario, size: 40),
            const SizedBox(height: 12),
            const Text('No se pudo cargar el socio',
                style: TextStyle(color: AppColors.textoSecundario)),
            const SizedBox(height: 12),
            FilledButton.tonal(
                onPressed: () => context.go('/socios'),
                child: const Text('Volver a socios')),
          ],
        ),
      ),
      data: (socio) => SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/socios'),
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.textoSecundario,
                  ),
                  const SizedBox(width: 4),
                  Text('Detalle del socio',
                      style: const TextStyle(
                          color: AppColors.textoSecundario, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.acentoSuave,
                    child: Text(socio.iniciales,
                        style: const TextStyle(
                            color: AppColors.acento,
                            fontWeight: FontWeight.w700,
                            fontSize: 20)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(socio.nombreCompleto,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('${socio.codigo} · DNI ${socio.documento}',
                                style: const TextStyle(
                                    color: AppColors.textoSecundario)),
                            const SizedBox(width: 10),
                            _EstadoChip(activo: socio.activo),
                          ],
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => mostrarEditarSocioDialog(context, socio),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.acento,
                      side: const BorderSide(color: AppColors.borde),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => _cambiarEstado(context, ref, socio),
                    icon: Icon(
                        socio.activo
                            ? Icons.block
                            : Icons.check_circle_outline,
                        size: 18),
                    label: Text(socio.activo ? 'Deshabilitar' : 'Activar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          socio.activo ? AppColors.peligro : AppColors.exito,
                      side: const BorderSide(color: AppColors.borde),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _Seccion(
                titulo: 'Datos personales',
                filas: [
                  ('Documento', 'DNI ${socio.documento}'),
                  ('Sexo', _sexoTexto(socio.sexo)),
                  ('Fecha de nacimiento',
                      socio.fechaNacimiento.isEmpty ? '—' : socio.fechaNacimiento),
                  ('Teléfono', socio.telefono.isEmpty ? '—' : socio.telefono),
                  ('Correo', socio.email.isEmpty ? '—' : socio.email),
                  ('Dirección', socio.direccion.isEmpty ? '—' : socio.direccion),
                ],
              ),
              const SizedBox(height: 16),
              _MembresiaSeccion(socioId: socio.id),
            ],
          ),
        ),
      ),
    );
  }

  String _sexoTexto(String s) {
    if (s == 'M') return 'Masculino';
    if (s == 'F') return 'Femenino';
    return '—';
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final List<(String, String)> filas;

  const _Seccion({required this.titulo, required this.filas});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          for (final f in filas) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 180,
                    child: Text(f.$1,
                        style: const TextStyle(
                            color: AppColors.textoSecundario, fontSize: 14)),
                  ),
                  Expanded(
                    child: Text(f.$2,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            if (f != filas.last)
              const Divider(height: 1, color: AppColors.borde),
          ],
        ],
      ),
    );
  }
}

class _MembresiaSeccion extends ConsumerWidget {
  final String socioId;

  const _MembresiaSeccion({required this.socioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(estadoMembresiaProvider(socioId));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Membresía',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              FilledButton.icon(
                onPressed: () => mostrarRegistrarPagoDialog(context, socioId),
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text('Registrar pago'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          estado.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => const Text('No se pudo cargar la membresía',
                style: TextStyle(color: AppColors.textoSecundario)),
            data: (m) {
              if (!m.tieneMembresia) {
                return const Text(
                    'Sin membresía. Registra un pago para activarla.',
                    style: TextStyle(color: AppColors.textoSecundario));
              }
              final color = m.alDia ? AppColors.exito : AppColors.peligro;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(m.alDia ? 'AL DÍA' : 'VENCIDO',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                      const SizedBox(width: 12),
                      Text(m.planNombre,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _fila('Vence el', m.fechaFin),
                  _fila(
                      m.alDia ? 'Días restantes' : 'Vencida hace',
                      m.alDia
                          ? '${m.diasRestantes} días'
                          : '${-m.diasRestantes} días'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _fila(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
              width: 180,
              child: Text(k,
                  style: const TextStyle(
                      color: AppColors.textoSecundario, fontSize: 14))),
          Text(v,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final bool activo;

  const _EstadoChip({required this.activo});

  @override
  Widget build(BuildContext context) {
    final color = activo ? AppColors.exito : AppColors.peligro;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(activo ? 'Activo' : 'Inactivo',
          style:
              TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
