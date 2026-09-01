import 'package:flutter/foundation.dart';

/// El mismo código compila para Android y para web, así que el tablero
/// del navegador nunca se desincroniza del de la tablet.
///
/// En web solo entra el administrador: registrar personas y marcar
/// accesos se hace en el teléfono, con cámara y junto a la familia.
class Plataforma {
  Plataforma._();

  /// true cuando corre en navegador.
  static const bool esWeb = kIsWeb;

  /// En web solo se muestra el tablero de reportes.
  static bool get soloTablero => esWeb;

  /// Roles que pueden entrar desde el navegador.
  static const rolesWeb = ['admin'];

  static bool rolPermitido(String rol) =>
      !esWeb || rolesWeb.contains(rol);
}
