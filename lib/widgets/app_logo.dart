import 'package:flutter/material.dart';
import '../config.dart';
import '../theme.dart';

/// Logo institucional (Estadio Monumental).
///
/// El archivo es blanco con fondo transparente, por lo que SIEMPRE se
/// muestra sobre Azul Medianoche (#041941), como exige el manual de
/// identidad. Para cambiar el logo basta reemplazar assets/logo.png.
class AppLogo extends StatelessWidget {
  final double size;

  /// Muestra solo el emblema, sin el nombre del refugio.
  final bool compact;

  /// Sin la placa azul (úsese solo sobre fondos ya oscuros).
  final bool plano;

  /// Emblema ARRIBA y nombre debajo, centrados (forma de pirámide).
  /// Es el que se usa en el splash: en horizontal, a tamaño grande, el
  /// texto empuja la placa fuera de la pantalla.
  final bool vertical;

  const AppLogo({
    super.key,
    this.size = 40,
    this.compact = false,
    this.plano = false,
    this.vertical = false,
  });

  static const String logoAsset = 'assets/logo.png';

  @override
  Widget build(BuildContext context) {
    final emblema = Image.asset(logoAsset, height: size, fit: BoxFit.contain);

    // Placa azul medianoche: garantiza contraste del logo blanco.
    final placa = plano
        ? emblema
        : Container(
            padding: EdgeInsets.symmetric(
                horizontal: size * 0.22, vertical: size * 0.16),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(size * 0.30),
            ),
            child: emblema,
          );

    if (compact) return placa;

    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          placa,
          SizedBox(height: size * 0.42),
          Text(
            AppConfig.appName.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size * 0.26,
              height: 1.25,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppColors.navy,
            ),
          ),
          SizedBox(height: size * 0.10),
          Text(
            'Registro y control de damnificados',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size * 0.17,
              letterSpacing: 0.2,
              color: AppColors.gray,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        placa,
        SizedBox(width: size * 0.32),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConfig.appName.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: size * 0.30,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: AppColors.navy,
                ),
              ),
              Text(
                'Registro y control de damnificados',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: size * 0.20,
                  color: AppColors.gray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
