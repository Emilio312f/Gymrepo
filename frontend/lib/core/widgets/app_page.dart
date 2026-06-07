import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

const double _maxAncho = 1100;

class AppPage extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Widget? accion;
  final Widget child;

  const AppPage({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.child,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 18),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxAncho),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(subtitulo,
                            style: const TextStyle(
                                color: AppColors.textoSecundario)),
                      ],
                    ),
                  ),
                  ?accion,
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxAncho),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ColumnaTabla {
  final String titulo;
  final int flex;

  const ColumnaTabla(this.titulo, {this.flex = 1});
}

class FilaTabla {
  final List<Widget> celdas;
  final VoidCallback? onTap;

  const FilaTabla({required this.celdas, this.onTap});
}

class AppTabla extends StatelessWidget {
  final List<ColumnaTabla> columnas;
  final List<FilaTabla> filas;

  const AppTabla({super.key, required this.columnas, required this.filas});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borde)),
            ),
            child: Row(
              children: [
                for (final c in columnas)
                  Expanded(
                    flex: c.flex,
                    child: Text(c.titulo,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.textoSecundario)),
                  ),
                const SizedBox(width: 24),
              ],
            ),
          ),
          for (var i = 0; i < filas.length; i++)
            _Fila(
              fila: filas[i],
              columnas: columnas,
              ultima: i == filas.length - 1,
            ).animate().fadeIn(duration: 200.ms, delay: (i * 30).ms),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final FilaTabla fila;
  final List<ColumnaTabla> columnas;
  final bool ultima;

  const _Fila(
      {required this.fila, required this.columnas, required this.ultima});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: fila.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: ultima
                ? null
                : const Border(bottom: BorderSide(color: AppColors.borde)),
          ),
          child: Row(
            children: [
              for (var j = 0; j < columnas.length; j++)
                Expanded(
                  flex: columnas[j].flex,
                  child: j < fila.celdas.length
                      ? fila.celdas[j]
                      : const SizedBox.shrink(),
                ),
              SizedBox(
                width: 24,
                child: fila.onTap != null
                    ? const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textoSecundario)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
