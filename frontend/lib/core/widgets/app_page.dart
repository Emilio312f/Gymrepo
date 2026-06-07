import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

const double _maxAncho = 1100;
const double _breakpoint = 700;

bool esAngosta(BuildContext context) =>
    MediaQuery.of(context).size.width < _breakpoint;

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
    final angosta = esAngosta(context);
    final padH = angosta ? 16.0 : 32.0;

    final tituloBloque = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: TextStyle(
                fontSize: angosta ? 21 : 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(subtitulo,
            style: const TextStyle(color: AppColors.textoSecundario)),
      ],
    );

    final encabezado = angosta
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tituloBloque,
              if (accion != null) ...[
                const SizedBox(height: 14),
                accion!,
              ],
            ],
          )
        : Row(
            children: [
              Expanded(child: tituloBloque),
              ?accion,
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padH, angosta ? 20 : 28, padH, 16),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxAncho),
              child: encabezado,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(padH, 0, padH, 40),
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
    if (esAngosta(context)) return _Tarjetas(filas: filas);

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

class _Tarjetas extends StatelessWidget {
  final List<FilaTabla> filas;

  const _Tarjetas({required this.filas});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < filas.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: AppColors.superficie,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: filas[i].onTap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borde),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var j = 0; j < filas[i].celdas.length; j++)
                              Padding(
                                padding: EdgeInsets.only(top: j == 0 ? 0 : 6),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: filas[i].celdas[j],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (filas[i].onTap != null)
                        const Icon(Icons.chevron_right,
                            size: 18, color: AppColors.textoSecundario),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 200.ms, delay: (i * 30).ms),
      ],
    );
  }
}
