/// ═══════════════════════════════════════════════════════════
/// FORMATO DEL FORMULARIO
///
/// El refugio pasó de levantar la "Planilla de ingreso de damnificados"
/// (13 secciones sobre el daño de la vivienda, ayuda social y firmas) a
/// levantar el CENSO DEL CAMPAMENTO MONUMENTAL, que es una fila por
/// persona con datos de dotación y salud.
///
/// El censo es ahora el formato vigente. La planilla anterior queda en el
/// código y se puede volver a activar cambiando `planillaDamnificados` a
/// true: aparecería como pasos adicionales al final del asistente.
/// ═══════════════════════════════════════════════════════════
class Modulos {
  Modulos._();

  /// Formato vigente: censo del Campamento Monumental (Excel oficial).
  static const bool censoMonumental = true;

  /// Formato anterior: planilla de damnificados (daño, ayuda, firmas).
  /// Ponlo en true si vuelve a hacer falta levantar solicitudes de ayuda.
  static const bool planillaDamnificados = false;
}
