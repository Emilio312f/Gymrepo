import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/socios_repository.dart';
import 'socios_controller.dart';

Future<void> mostrarCrearAccesoDialog(BuildContext context, Socio socio) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CrearAccesoDialog(socio: socio),
  );
}

class _CrearAccesoDialog extends ConsumerStatefulWidget {
  final Socio socio;

  const _CrearAccesoDialog({required this.socio});

  @override
  ConsumerState<_CrearAccesoDialog> createState() => _CrearAccesoDialogState();
}

class _CrearAccesoDialogState extends ConsumerState<_CrearAccesoDialog> {
  late final TextEditingController _email =
      TextEditingController(text: widget.socio.email);
  final _password = TextEditingController();

  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Ingresa un correo válido');
      return;
    }
    if (_password.text.trim().length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(sociosRepositoryProvider)
          .crearAcceso(widget.socio.id, email, _password.text.trim());
      ref.invalidate(socioDetalleProvider(widget.socio.id));
      ref.invalidate(sociosControllerProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger
          .showSnackBar(const SnackBar(content: Text('Acceso creado')));
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.response?.statusCode == 409
            ? 'Ese correo ya tiene acceso en este gimnasio'
            : 'No se pudo crear el acceso';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'Ocurrió un error inesperado';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.superficie,
      surfaceTintColor: AppColors.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Crear acceso a la app',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
                '${widget.socio.nombreCompleto} podrá iniciar sesión y ver su membresía, asistencias y pagos.',
                style: const TextStyle(color: AppColors.textoSecundario)),
            const SizedBox(height: 18),
            const _Etiqueta('Correo'),
            const SizedBox(height: 6),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'correo@ejemplo.com'),
            ),
            const SizedBox(height: 16),
            const _Etiqueta('Contraseña'),
            const SizedBox(height: 6),
            TextField(
              controller: _password,
              obscureText: true,
              decoration:
                  const InputDecoration(hintText: 'Mínimo 6 caracteres'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  style:
                      const TextStyle(color: AppColors.peligro, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _guardando ? null : () => Navigator.of(context).pop(),
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
                    onPressed: _guardando ? null : _guardar,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46)),
                    child: _guardando
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: Colors.white))
                        : const Text('Crear acceso'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;

  const _Etiqueta(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(texto,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600));
  }
}
