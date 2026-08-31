import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════
/// SEÑAL DE REFRESCO
///
/// Cada pantalla cargaba sus datos una sola vez y no se enteraba de lo
/// que hacían las demás: al cambiar el estatus dentro de un expediente,
/// la lista y el tablero seguían mostrando lo viejo hasta recargarlos a
/// mano.
///
/// `Datos.cambiaron()` avisa a las pantallas abiertas de que hay que
/// volver a consultar. Es a propósito simple: un contador que escuchan.
///
/// El parámetro `origen` evita que la pantalla que hizo el cambio se
/// recargue a sí misma. Importa en Acceso: allí cada marca de comida ya
/// se refleja al instante en pantalla, y una recarga completa por cada
/// toque sería un viaje a la red innecesario y un parpadeo en la lista.
/// ═══════════════════════════════════════════════════════════
class Datos {
  Datos._();

  /// Se incrementa con cada cambio. Las pantallas lo escuchan.
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  /// Quién hizo el último cambio ('lista', 'detalle', 'acceso', 'wizard').
  static String ultimoOrigen = '';

  /// Llamar después de CUALQUIER escritura: crear, editar, cambiar
  /// estatus, eliminar, marcar entrada/salida o comida.
  static void cambiaron({String origen = ''}) {
    ultimoOrigen = origen;
    version.value++;
  }

  /// Suscribe una recarga que se omite si el cambio lo hizo esta misma
  /// pantalla. Devuelve el listener para poder quitarlo en dispose().
  static VoidCallback escuchar(String pantalla, VoidCallback recargar) {
    void listener() {
      if (ultimoOrigen == pantalla) return;
      recargar();
    }

    version.addListener(listener);
    return listener;
  }

  static void dejarDeEscuchar(VoidCallback listener) =>
      version.removeListener(listener);
}
