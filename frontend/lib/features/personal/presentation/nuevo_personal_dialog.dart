import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'personal_controller.dart';

Future<void> mostrarNuevoPersonalDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _NuevoPersonalDialog(),
  );
}

class _NuevoPersonalDialog extends ConsumerStatefulWidget {
  const _NuevoPersonalDialog();

  @override
  ConsumerState<_NuevoPersonalDialog> createState() =>
      _NuevoPersonalDialogState();
}

class _NuevoPersonalDialogState extends ConsumerState<_NuevoPersonalDialog> {
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _rol = 'recepcion';

  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.trim().length < 6) {
      setState(() =>
          _error = 'Nombre, email y contraseña (mínimo 6) son obligatorios');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    final err = await ref.read(personalControllerProvider.notifier).crear(
          nombre: _nombre.text.trim(),
          email: _email.text.trim(),
          password: _password.text.trim(),
          rol: _rol,
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
      title: const Text('Nuevo usuario',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _lbl('Nombre'),
              const SizedBox(height: 6),
              TextField(
                  controller: _nombre,
                  decoration: const InputDecoration(hintText: 'Nombre y apellido')),
              const SizedBox(height: 16),
              _lbl('Correo'),
              const SizedBox(height: 6),
              TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'correo@gimnasio.com')),
              const SizedBox(height: 16),
              _lbl('Contraseña'),
              const SizedBox(height: 6),
              TextField(
                  controller: _password,
                  decoration:
                      const InputDecoration(hintText: 'Mínimo 6 caracteres')),
              const SizedBox(height: 16),
              _lbl('Rol'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _rol,
                isExpanded: true,
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(
                      value: 'recepcion', child: Text('Recepción')),
                  DropdownMenuItem(
                      value: 'admin', child: Text('Administrador')),
                ],
                onChanged: (v) => setState(() => _rol = v ?? 'recepcion'),
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
                          : const Text('Crear'),
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

  Widget _lbl(String t) => Text(t,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600));
}
