import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/documento_repository.dart';
import 'socios_controller.dart';

Future<void> mostrarNuevoSocioDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _NuevoSocioDialog(),
  );
}

class _NuevoSocioDialog extends ConsumerStatefulWidget {
  const _NuevoSocioDialog();

  @override
  ConsumerState<_NuevoSocioDialog> createState() => _NuevoSocioDialogState();
}

class _NuevoSocioDialogState extends ConsumerState<_NuevoSocioDialog> {
  final _documento = TextEditingController();
  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();

  bool _guardando = false;
  bool _buscandoDni = false;
  String? _dniConsultado;
  String? _error;

  @override
  void dispose() {
    _documento.dispose();
    _nombres.dispose();
    _apellidos.dispose();
    _telefono.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _buscarDni() async {
    final dni = _documento.text.trim();
    if (dni.length != 8 || dni == _dniConsultado) return;

    setState(() {
      _buscandoDni = true;
      _error = null;
    });

    try {
      final datos = await ref.read(documentoRepositoryProvider).consultarDni(dni);
      if (!mounted) return;
      setState(() {
        _nombres.text = datos.nombres;
        _apellidos.text = datos.apellidos;
        _dniConsultado = dni;
        _buscandoDni = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _buscandoDni = false;
        _error = e.response?.statusCode == 404
            ? 'No se encontraron datos para ese DNI. Complétalos manualmente.'
            : 'No se pudo consultar el DNI. Complétalos manualmente.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _buscandoDni = false);
    }
  }

  Future<void> _guardar() async {
    if (_documento.text.trim().isEmpty ||
        _nombres.text.trim().isEmpty ||
        _apellidos.text.trim().isEmpty) {
      setState(() => _error = 'Documento, nombres y apellidos son obligatorios');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final err = await ref.read(sociosControllerProvider.notifier).crear(
          codigo: '',
          nombres: _nombres.text.trim(),
          apellidos: _apellidos.text.trim(),
          documento: _documento.text.trim(),
          telefono: _telefono.text.trim(),
          email: _email.text.trim(),
        );

    if (!mounted) return;

    if (err == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _guardando = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.superficie,
      surfaceTintColor: AppColors.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Nuevo socio',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Etiqueta('DNI'),
              const SizedBox(height: 6),
              TextField(
                controller: _documento,
                keyboardType: TextInputType.number,
                maxLength: 8,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) {
                  if (v.length == 8) _buscarDni();
                },
                decoration: InputDecoration(
                  hintText: 'Escribe el DNI y se autocompletan los datos',
                  counterText: '',
                  suffixIcon: _buscandoDni
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                        )
                      : (_dniConsultado != null
                          ? const Icon(Icons.check_circle,
                              color: AppColors.exito)
                          : const Icon(Icons.badge_outlined,
                              color: AppColors.textoSecundario)),
                ),
              ),
              const SizedBox(height: 16),
              _Etiqueta('Nombres'),
              const SizedBox(height: 6),
              TextField(
                controller: _nombres,
                decoration: const InputDecoration(hintText: 'Nombres'),
              ),
              const SizedBox(height: 16),
              _Etiqueta('Apellidos'),
              const SizedBox(height: 6),
              TextField(
                controller: _apellidos,
                decoration: const InputDecoration(hintText: 'Apellidos'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Etiqueta('Teléfono'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _telefono,
                          keyboardType: TextInputType.phone,
                          decoration:
                              const InputDecoration(hintText: 'Opcional'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Etiqueta('Correo'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration:
                              const InputDecoration(hintText: 'Opcional'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.peligro, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.textoSecundario)),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: Colors.white))
              : const Text('Guardar'),
        ),
      ],
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
