import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../membresias/data/membresias_repository.dart';
import '../../membresias/presentation/registrar_pago_dialog.dart';
import '../../membresias/presentation/asignar_plan_dialog.dart';
import '../data/socios_repository.dart';
import 'socios_controller.dart';
import 'crear_acceso_dialog.dart';
import 'editar_socio_dialog.dart';

class SocioDetalleScreen extends ConsumerWidget {
  final String socioId;

  const SocioDetalleScreen({super.key, required this.socioId});

  Future<void> _cambiarEstado(
      BuildContext context, WidgetRef ref, Socio socio) async {
    final desactivar = socio.activo;
    final messenger = ScaffoldMessenger.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.superficie,
        surfaceTintColor: AppColors.superficie,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(desactivar ? 'Deshabilitar socio' : 'Activar socio',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                desactivar
                    ? '${socio.nombreCompleto} no podrá acceder, pero su historial se conserva.'
                    : '${socio.nombreCompleto} podrá volver a acceder.',
                style: const TextStyle(color: AppColors.textoSecundario),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        foregroundColor: AppColors.textoSecundario,
                        side: const BorderSide(color: AppColors.borde),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        backgroundColor:
                            desactivar ? AppColors.peligro : AppColors.exito,
                      ),
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmar != true) return;

    try {
      await ref
          .read(sociosRepositoryProvider)
          .cambiarEstado(socio.id, !socio.activo);
      ref.invalidate(socioDetalleProvider(socio.id));
      ref.invalidate(sociosControllerProvider);
      messenger.showSnackBar(SnackBar(
          content: Text(
              desactivar ? 'Socio deshabilitado' : 'Socio activado')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('No se pudo cambiar el estado del socio')));
    }
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
      data: (socio) {
        final angosta = esAngosta(context);
        final info = Row(
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
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      Text('${socio.codigo} · DNI ${socio.documento}',
                          style: const TextStyle(
                              color: AppColors.textoSecundario)),
                      _EstadoChip(activo: socio.activo),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

        final btnEditar = OutlinedButton.icon(
          onPressed: () => mostrarEditarSocioDialog(context, socio),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Editar'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            foregroundColor: AppColors.acento,
            side: const BorderSide(color: AppColors.borde),
          ),
        );
        final btnEstado = OutlinedButton.icon(
          onPressed: () => _cambiarEstado(context, ref, socio),
          icon: Icon(
              socio.activo ? Icons.block : Icons.check_circle_outline,
              size: 18),
          label: Text(socio.activo ? 'Deshabilitar' : 'Activar'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            foregroundColor:
                socio.activo ? AppColors.peligro : AppColors.exito,
            side: const BorderSide(color: AppColors.borde),
          ),
        );

        return SingleChildScrollView(
          padding: EdgeInsets.all(angosta ? 16 : 28),
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
                    const Text('Detalle del socio',
                        style: TextStyle(
                            color: AppColors.textoSecundario, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                if (angosta) ...[
                  info,
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: btnEditar),
                      const SizedBox(width: 10),
                      Expanded(child: btnEstado),
                    ],
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(child: info),
                      btnEditar,
                      const SizedBox(width: 10),
                      btnEstado,
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
              const SizedBox(height: 16),
              _PendienteSeccion(socioId: socio.id),
              const SizedBox(height: 16),
              _AccesoSeccion(socio: socio),
            ],
          ),
        ),
      );
      },
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
    final angosta = esAngosta(context);
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
              child: angosta
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.$1,
                            style: const TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(f.$2,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 180,
                          child: Text(f.$1,
                              style: const TextStyle(
                                  color: AppColors.textoSecundario,
                                  fontSize: 14)),
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

class _PendienteSeccion extends ConsumerWidget {
  final String socioId;

  const _PendienteSeccion({required this.socioId});

  Future<void> _accion(
      BuildContext context, WidgetRef ref, Future<void> Function() op,
      String ok) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await op();
      ref.invalidate(pendienteAdminProvider(socioId));
      ref.invalidate(estadoMembresiaProvider(socioId));
      ref.invalidate(sociosControllerProvider);
      messenger.showSnackBar(SnackBar(content: Text(ok)));
    } catch (_) {
      messenger
          .showSnackBar(const SnackBar(content: Text('No se pudo completar')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendiente = ref.watch(pendienteAdminProvider(socioId));
    final repo = ref.read(membresiasRepositoryProvider);

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
                child: Text('Pago pendiente',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              pendiente.maybeWhen(
                data: (p) => p.tienePendiente
                    ? const SizedBox.shrink()
                    : OutlinedButton.icon(
                        onPressed: () =>
                            mostrarAsignarPlanDialog(context, socioId),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Asignar plan'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          foregroundColor: AppColors.acento,
                          side: const BorderSide(color: AppColors.borde),
                        ),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          pendiente.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => const Text('No se pudo cargar el pago pendiente',
                style: TextStyle(color: AppColors.textoSecundario)),
            data: (p) {
              if (!p.tienePendiente) {
                return const Text(
                    'Sin plan pendiente. Asigna un plan para que el socio lo pague desde su app.',
                    style: TextStyle(color: AppColors.textoSecundario));
              }
              final enRevision = p.enRevision;
              final color =
                  enRevision ? AppColors.advertencia : AppColors.textoSecundario;
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
                        child: Text(
                            enRevision ? 'EN REVISIÓN' : 'PENDIENTE DE PAGO',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                            '${p.planNombre} · S/ ${p.precio.toStringAsFixed(2)}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  if (enRevision) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const SizedBox(
                            width: 160,
                            child: Text('N° de operación Yape',
                                style: TextStyle(
                                    color: AppColors.textoSecundario,
                                    fontSize: 14))),
                        Text(p.operacion,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _accion(context, ref,
                                () => repo.rechazarPago(p.membresiaId),
                                'Pago rechazado'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              foregroundColor: AppColors.peligro,
                              side: const BorderSide(color: AppColors.borde),
                            ),
                            child: const Text('Rechazar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _accion(context, ref,
                                () => repo.confirmarPago(p.membresiaId),
                                'Pago confirmado, membresía activada'),
                            style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                backgroundColor: AppColors.exito),
                            child: const Text('Confirmar pago'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    const Text(
                        'Esperando que el socio pague desde su app.',
                        style: TextStyle(color: AppColors.textoSecundario)),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        onPressed: () => _accion(context, ref,
                            () => repo.cancelarPendiente(p.membresiaId),
                            'Asignación cancelada'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          foregroundColor: AppColors.peligro,
                          side: const BorderSide(color: AppColors.borde),
                        ),
                        child: const Text('Cancelar asignación'),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AccesoSeccion extends StatelessWidget {
  final Socio socio;

  const _AccesoSeccion({required this.socio});

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
          const Text('Acceso a la app',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 14),
          if (socio.tieneAcceso)
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.exito, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    socio.email.isEmpty
                        ? 'El socio ya puede iniciar sesión.'
                        : 'El socio inicia sesión con ${socio.email}.',
                    style: const TextStyle(color: AppColors.textoSecundario),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    socio.activo
                        ? 'Este socio aún no tiene cuenta para ver su membresía y asistencias.'
                        : 'Activa al socio para poder darle acceso.',
                    style: const TextStyle(color: AppColors.textoSecundario),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: socio.activo
                      ? () => mostrarCrearAccesoDialog(context, socio)
                      : null,
                  icon: const Icon(Icons.key_outlined, size: 18),
                  label: const Text('Crear acceso'),
                  style:
                      FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                ),
              ],
            ),
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
