import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/app_dropdown.dart';
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
  final _direccion = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();

  String? _sexo;
  DateTime? _fechaNacimiento;

  bool _guardando = false;
  bool _buscandoDni = false;
  String? _dniConsultado;
  String? _error;

  @override
  void dispose() {
    _documento.dispose();
    _nombres.dispose();
    _apellidos.dispose();
    _direccion.dispose();
    _telefono.dispose();
    _email.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _buscarDni() async {
    final dni = _documento.text.trim();
    if (dni.length != 8 || dni == _dniConsultado) return;
    setState(() {
      _buscandoDni = true;
      _error = null;
    });
    try {
      final datos =
          await ref.read(documentoRepositoryProvider).consultarDni(dni);
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
            ? 'Sin datos para ese DNI. Complétalos a mano.'
            : 'No se pudo consultar el DNI. Complétalos a mano.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _buscandoDni = false);
    }
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final maxima = DateTime(hoy.year - 18, hoy.month, hoy.day);
    final f = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? maxima,
      firstDate: DateTime(1920),
      lastDate: maxima,
      helpText: 'Fecha de nacimiento (mayor de 18)',
    );
    if (f != null) setState(() => _fechaNacimiento = f);
  }

  Future<void> _guardar() async {
    final error = Validadores.dni(_documento.text) ??
        Validadores.nombre(_nombres.text, 'Nombres') ??
        Validadores.nombre(_apellidos.text, 'Apellidos') ??
        Validadores.requerido(_sexo ?? '', 'Sexo') ??
        Validadores.mayorDeEdad(_fechaNacimiento) ??
        Validadores.requerido(_direccion.text, 'Dirección') ??
        Validadores.telefono(_telefono.text) ??
        Validadores.email(_email.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final err = await ref.read(sociosControllerProvider.notifier).crear(
          nombres: _nombres.text.trim(),
          apellidos: _apellidos.text.trim(),
          documento: _documento.text.trim(),
          telefono: _telefono.text.trim(),
          email: _email.text.trim(),
          sexo: _sexo ?? '',
          direccion: _direccion.text.trim(),
          fechaNacimiento: _fmt(_fechaNacimiento!),
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
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Etiqueta('DNI'),
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
                  hintText: 'Número de DNI',
                  counterText: '',
                  suffixIcon: _buscandoDni
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              height: 18,
                              width: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.2)),
                        )
                      : (_dniConsultado != null
                          ? const Icon(Icons.check_circle,
                              color: AppColors.exito)
                          : const Icon(Icons.badge_outlined,
                              color: AppColors.textoSecundario)),
                ),
              ),
              const SizedBox(height: 16),
              const _Etiqueta('Nombres'),
              const SizedBox(height: 6),
              TextField(
                controller: _nombres,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ ]'))
                ],
                decoration: const InputDecoration(hintText: 'Nombres'),
              ),
              const SizedBox(height: 16),
              const _Etiqueta('Apellidos'),
              const SizedBox(height: 6),
              TextField(
                controller: _apellidos,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ ]'))
                ],
                decoration: const InputDecoration(hintText: 'Apellidos'),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Etiqueta('Sexo'),
                        const SizedBox(height: 6),
                        AppDropdown<String>(
                          value: _sexo,
                          hint: 'Seleccionar',
                          items: const [
                            DropdownMenuItem(
                                value: 'M', child: Text('Masculino')),
                            DropdownMenuItem(
                                value: 'F', child: Text('Femenino')),
                          ],
                          onChanged: (v) => setState(() => _sexo = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Etiqueta('Fecha nacimiento'),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _elegirFecha,
                          borderRadius: BorderRadius.circular(10),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                                suffixIcon: Icon(Icons.calendar_today_outlined,
                                    size: 18)),
                            child: Text(
                              _fechaNacimiento != null
                                  ? _fmt(_fechaNacimiento!)
                                  : 'dd/mm/aaaa',
                              style: TextStyle(
                                  color: _fechaNacimiento != null
                                      ? AppColors.textoPrincipal
                                      : AppColors.textoSecundario),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _Etiqueta('Dirección'),
              const SizedBox(height: 6),
              TextField(
                  controller: _direccion,
                  decoration: const InputDecoration(hintText: 'Dirección')),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Etiqueta('Teléfono'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _telefono,
                          keyboardType: TextInputType.phone,
                          maxLength: 15,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                              hintText: 'Teléfono', counterText: ''),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Etiqueta('Correo'),
                        const SizedBox(height: 6),
                        TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration:
                                const InputDecoration(hintText: 'Correo')),
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _guardando
                          ? null
                          : () => Navigator.of(context).pop(),
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
                          : const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
