const _dias = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo'
];

const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic'
];

String _dos(int n) => n.toString().padLeft(2, '0');

String fechaLarga(DateTime d) =>
    '${_dias[d.weekday - 1]} ${d.day} ${_meses[d.month - 1]} ${d.year}';

String fechaCorta(DateTime d) => '${d.day} ${_meses[d.month - 1]} ${d.year}';

String hora(DateTime d) => '${_dos(d.hour)}:${_dos(d.minute)}';
