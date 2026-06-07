import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../theme/app_theme.dart';
import 'app_dropdown.dart';

Future<DateTime?> seleccionarFecha(
  BuildContext context, {
  DateTime? inicial,
  required DateTime primera,
  required DateTime ultima,
  String titulo = 'Selecciona la fecha',
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _SelectorFecha(
      inicial: inicial,
      primera: primera,
      ultima: ultima,
      titulo: titulo,
    ),
  );
}

const _meses = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

class _SelectorFecha extends StatefulWidget {
  final DateTime? inicial;
  final DateTime primera;
  final DateTime ultima;
  final String titulo;

  const _SelectorFecha({
    required this.inicial,
    required this.primera,
    required this.ultima,
    required this.titulo,
  });

  @override
  State<_SelectorFecha> createState() => _SelectorFechaState();
}

class _SelectorFechaState extends State<_SelectorFecha> {
  late DateTime _focused;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.inicial;
    _focused = _clamp(widget.inicial ?? widget.ultima);
  }

  DateTime _clamp(DateTime d) {
    if (d.isBefore(widget.primera)) return widget.primera;
    if (d.isAfter(widget.ultima)) return widget.ultima;
    return d;
  }

  void _irA(int anio, int mes) {
    setState(() => _focused = _clamp(DateTime(anio, mes, 1)));
  }

  @override
  Widget build(BuildContext context) {
    final anios = [
      for (var a = widget.ultima.year; a >= widget.primera.year; a--) a
    ];

    return AlertDialog(
      backgroundColor: AppColors.superficie,
      surfaceTintColor: AppColors.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.titulo,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AppDropdown<int>(
                    value: _focused.month,
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(value: m, child: Text(_meses[m - 1])),
                    ],
                    onChanged: (m) => _irA(_focused.year, m ?? _focused.month),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: AppDropdown<int>(
                    value: _focused.year,
                    items: [
                      for (final a in anios)
                        DropdownMenuItem(value: a, child: Text('$a')),
                    ],
                    onChanged: (a) => _irA(a ?? _focused.year, _focused.month),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TableCalendar(
              firstDay: widget.primera,
              lastDay: widget.ultima,
              focusedDay: _focused,
              headerVisible: false,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableGestures: AvailableGestures.horizontalSwipe,
              selectedDayPredicate: (d) =>
                  _selected != null && isSameDay(d, _selected),
              onDaySelected: (sel, foc) {
                setState(() {
                  _selected = sel;
                  _focused = foc;
                });
              },
              onPageChanged: (foc) => _focused = foc,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                isTodayHighlighted: false,
                selectedDecoration: const BoxDecoration(
                    color: AppColors.acento, shape: BoxShape.circle),
                selectedTextStyle: const TextStyle(color: Colors.white),
                defaultTextStyle:
                    const TextStyle(color: AppColors.textoPrincipal),
                weekendTextStyle:
                    const TextStyle(color: AppColors.textoPrincipal),
                disabledTextStyle:
                    const TextStyle(color: AppColors.borde),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                    color: AppColors.textoSecundario,
                    fontWeight: FontWeight.w600),
                weekendStyle: TextStyle(
                    color: AppColors.textoSecundario,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
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
                    onPressed: _selected == null
                        ? null
                        : () => Navigator.pop(context, _selected),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44)),
                    child: const Text('Aceptar'),
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
