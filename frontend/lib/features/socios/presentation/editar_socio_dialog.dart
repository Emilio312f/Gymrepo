import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../data/socios_repository.dart';
import 'socios_controller.dart';

Future<void> mostrarEditarSocioDialog(BuildContext context, Socio socio) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _EditarSocioDialog(socio: socio),
  );
}

class _EditarSocioDialog extends ConsumerStatefulWidget {
  final Socio socio;

  const _EditarSocioDialog({required this.socio});

  @override
  ConsumerState<_EditarSocioDialog> createState() => _EditarSocioDialogState();
}

class _EditarSocioDialogState extends ConsumerState<_EditarSocioDialog> {
  late final TextEditingController _documento;
  late final TextEditingController _nombres;
  late final TextEditingController _apellidos;
  late final TextEditingController _direccion;
  late final TextEditingController _telefono;
  late final TextEditingController _email;

  String? _sexo;
  DateTime? _fechaNacimiento;

  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.socio;
    _documento = TextEditingController(text: s.documento);
    _nombres = TextEditingController(text: s.nombres);
    _apellidos = TextEditingController(text: s.apellidos);
    _direccion = TextEditingController(text: s.direccion);
    _telefono = TextEditingController(text: s.telefono);
    _email = TextEditingController(text: s.email);
    _sexo = s.sexo.isNotEmpty ? s.sexo : null;
    _fechaNacimiento = DateTime.tryParse(s.fechaNacimiento);
  }

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
    try {
      await ref.read(sociosRepositoryProvider).actualizar(
            id: widget.socio.id,
            nombres: _nombres.text.trim(),
            apellidos: _apellidos.text.trim(),
            documento: _documento.text.trim(),
            telefono: _telefono.text.trim(),
            email: _email.text.trim(),
            sexo: _sexo ?? '',
            direccion: _direccion.text.trim(),
            fechaNacimiento:
                _fechaNacimiento != null ? _fmt(_fechaNacimiento!) : '',
          );
      ref.invalidate(socioDetalleProvider(widget.socio.id));
      ref.invalidate(sociosControllerProvider);
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.response?.statusCode == 409
            ? 'Ya existe un socio con ese documento'
            : 'No se pudo guardar';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.superficie,
      surfaceTintColor: AppColors.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Editar socio',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _campo('DNI', _documento,
                  teclado: TextInputType.number,
                  formatos: [FilteringTextInputFormatter.digitsOnly],
                  maxLen: 8),
              const SizedBox(height: 14),
              _campo('Nombres', _nombres),
              const SizedBox(height: 14),
              _campo('Apellidos', _apellidos),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Lbl('Sexo'),
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
                        const _Lbl('Fecha nacimiento'),
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
              const SizedBox(height: 14),
              _campo('Dirección', _direccion),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _campo('Teléfono', _telefono)),
                  const SizedBox(width: 12),
                  Expanded(child: _campo('Correo', _email)),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.peligro, fontSize: 13)),
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

  Widget _campo(String etiqueta, TextEditingController c,
      {TextInputType? teclado,
      List<TextInputFormatter>? formatos,
      int? maxLen}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Lbl(etiqueta),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: teclado,
          inputFormatters: formatos,
          maxLength: maxLen,
          decoration: const InputDecoration(counterText: ''),
        ),
      ],
    );
  }
}

class _Lbl extends StatelessWidget {
  final String texto;

  const _Lbl(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(texto,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600));
  }
}
