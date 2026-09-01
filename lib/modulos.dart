/// Qué formulario usa el asistente.
///
/// El refugio dejó la planilla de damnificados (13 secciones sobre daños,
/// ayuda y firmas) y pasó al censo del campamento, que es una ficha por
/// persona. La planilla sigue en el código por si vuelve a hacer falta:
/// se reactiva con `planillaDamnificados` y aparece como pasos extra.
class Modulos {
  Modulos._();

  /// Formato vigente: censo del Campamento Monumental (Excel oficial).
  static const bool censoMonumental = true;

  /// Formato anterior: planilla de damnificados (daño, ayuda, firmas).
  /// Ponlo en true si vuelve a hacer falta levantar solicitudes de ayuda.
  static const bool planillaDamnificados = false;
}
