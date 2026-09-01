import 'package:flutter/foundation.dart';

/// Aviso de que los datos cambiaron, para que las pantallas abiertas se
/// recarguen. `origen` evita que la pantalla que hizo el cambio se
/// recargue a sí misma: en Acceso el cambio ya se ve al instante y una
/// recarga por cada toque sobra.
class Datos {
  Datos._();

  /// Se incrementa con cada cambio. Las pantallas lo escuchan.
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  /// Patología por la que se está filtrando la lista de familias. Vive
  /// aquí y no en la tabla porque hay que limpiarla al cerrar sesión:
  /// de lo contrario reaparecía marcada en la sesión siguiente.
  static final ValueNotifier<String> filtroPatologia =
      ValueNotifier<String>('');

  /// Limpia el estado que no debe sobrevivir a un cambio de usuario.
  static void limpiarSesion() {
    filtroPatologia.value = '';
  }

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
