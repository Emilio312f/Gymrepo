import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      hint: hint != null
          ? Text(hint!, style: const TextStyle(color: AppColors.textoSecundario))
          : null,
      dropdownColor: AppColors.superficie,
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.textoSecundario),
      style: const TextStyle(color: AppColors.textoPrincipal, fontSize: 15),
      decoration: const InputDecoration(),
      items: items,
      onChanged: onChanged,
    );
  }
}
