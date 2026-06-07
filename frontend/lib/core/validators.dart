class Validadores {
  static final _soloLetras =
      RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ ]+$');
  static final _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final _soloDigitos = RegExp(r'^[0-9]+$');

  static String? nombre(String v, String campo) {
    final t = v.trim();
    if (t.isEmpty) return '$campo es obligatorio';
    if (t.length < 2) return '$campo es muy corto';
    if (!_soloLetras.hasMatch(t)) return '$campo solo debe contener letras';
    return null;
  }

  static String? dni(String v) {
    final t = v.trim();
    if (t.isEmpty) return 'El DNI es obligatorio';
    if (t.length != 8 || !_soloDigitos.hasMatch(t)) {
      return 'El DNI debe tener 8 dígitos';
    }
    return null;
  }

  static String? email(String v) {
    final t = v.trim();
    if (t.isEmpty) return 'El correo es obligatorio';
    if (!_email.hasMatch(t)) return 'Correo inválido';
    return null;
  }

  static String? telefono(String v) {
    final t = v.trim();
    if (t.isEmpty) return 'El teléfono es obligatorio';
    if (t.length != 9 || !_soloDigitos.hasMatch(t)) {
      return 'El teléfono debe tener 9 dígitos';
    }
    return null;
  }

  static String? requerido(String v, String campo) {
    if (v.trim().isEmpty) return '$campo es obligatorio';
    return null;
  }

  static String? mayorDeEdad(DateTime? fecha) {
    if (fecha == null) return 'La fecha de nacimiento es obligatoria';
    final hoy = DateTime.now();
    var edad = hoy.year - fecha.year;
    if (hoy.month < fecha.month ||
        (hoy.month == fecha.month && hoy.day < fecha.day)) {
      edad--;
    }
    if (edad < 18) return 'El socio debe ser mayor de 18 años';
    return null;
  }
}
