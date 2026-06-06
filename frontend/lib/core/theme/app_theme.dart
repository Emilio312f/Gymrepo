import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const fondo = Color(0xFFF8FAFC);
  static const superficie = Color(0xFFFFFFFF);
  static const borde = Color(0xFFE2E8F0);
  static const acento = Color(0xFF2563EB);
  static const acentoSuave = Color(0xFFEFF4FF);
  static const peligro = Color(0xFFDC2626);
  static const advertencia = Color(0xFFD97706);
  static const exito = Color(0xFF16A34A);
  static const textoPrincipal = Color(0xFF0F172A);
  static const textoSecundario = Color(0xFF64748B);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.fondo,
      colorScheme: const ColorScheme.light(
        primary: AppColors.acento,
        onPrimary: Colors.white,
        surface: AppColors.superficie,
        onSurface: AppColors.textoPrincipal,
        error: AppColors.peligro,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textoPrincipal,
        displayColor: AppColors.textoPrincipal,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.superficie,
        hintStyle: const TextStyle(color: AppColors.textoSecundario),
        labelStyle: const TextStyle(color: AppColors.textoSecundario),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.acento, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.acento,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.superficie,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borde),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.superficie,
        surfaceTintColor: AppColors.superficie,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        headerBackgroundColor: AppColors.acento,
        headerForegroundColor: Colors.white,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.superficie),
          surfaceTintColor: WidgetStatePropertyAll(AppColors.superficie),
        ),
      ),
    );
  }
}
