import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════
/// PLATAFORMA
///
/// El mismo código compila para Android (APK del refugio) y para web
/// (tablero público en GitHub Pages). No es una app aparte: así el
/// tablero web nunca se desincroniza del de la tablet.
///
/// En web solo existe el perfil ADMINISTRADOR: el registro de personas y
/// el control de acceso se hacen en el teléfono, junto a la familia y con
/// cámara. Un recolector no tendría cómo tomar fotos ni marcar entradas
/// desde un navegador, y exponer esas operaciones en una URL pública
/// amplía la superficie de riesgo sin dar nada a cambio.
/// ═══════════════════════════════════════════════════════════
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
