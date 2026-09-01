import '../models/expediente.dart';

/// Arma el resumen de un expediente. Aparte porque lo usan el detalle
/// del teléfono y la ficha emergente del tablero; duplicarlo dejaría uno
/// de los dos atrás en cuanto se agregue un campo.

String tri(dynamic v) => switch (v) {
      'si' => 'Sí',
      'no' => 'No',
      'ns' => 'No sabe',
      _ => '—',
    };

/// Convierte pares (etiqueta, valor) en líneas, omitiendo los vacíos.
/// Así el detalle no se llena de guiones cuando faltan datos opcionales.
List<String> filas(List<(String, dynamic)> pares) {
  final out = <String>[];
  for (final (etiqueta, valor) in pares) {
    final v = (valor ?? '').toString().trim();
    if (v.isEmpty || v == '—') continue;
    out.add('$etiqueta: $v');
  }
  return out.isEmpty ? ['Sin datos registrados'] : out;
}

/// Ficha completa de una persona del censo, con los campos condicionales
/// (detalle de la dieta, descripción de la condición) que antes no se
/// mostraban aunque sí se capturaban.
List<String> filasPersona(Map<String, dynamic> p, {bool esJefe = false}) {
  final edad = edadViva(
      fechaNacimiento: p['fecha_nacimiento']?.toString(),
      edadGuardada: p['edad']);
  final dieta = (p['dieta'] ?? '').toString();

  return filas([
    if (!esJefe) ('Nombre', '${p['nombres'] ?? ''} ${p['apellidos'] ?? ''}'.trim()),
    ('Cédula', p['cedula']),
    ('Fecha de nacimiento', p['fecha_nacimiento']),
    ('Edad', edad == null ? '' : '$edad años'),
    ('Sexo', p['sexo']),
    if (!esJefe) ('Parentesco', p['parentesco']),
    ('Teléfono', p['telefono']),
    ('Correo', p['email'] ?? p['correo']),
    ('Ocupación', p['ocupacion']),
    ('Brazalete', p['brazalete']),
    ('Condición de salud', p['condicion_salud']),
    ('Detalle de la condición', p['condicion_desc']),
    ('Tipo de sangre', p['tipo_sangre']),
    ('Dieta especial', dieta.isEmpty ? '' : tri(dieta)),
    // El detalle de la dieta solo se muestra si respondió que sí.
    if (dieta == 'si') ('Detalle de la dieta', p['dieta_desc']),
    ('Estatura', p['estatura'] == null || '${p['estatura']}'.isEmpty
        ? ''
        : '${p['estatura']} m'),
    ('Talla de camisa', p['talla_camisa']),
    ('Talla de pantalón', p['talla_pantalon']),
    ('Calzado', p['calzado']),
    ('Gorra', p['gorra']),
    ('Observaciones', p['observaciones']),
  ]);
}


/// Secciones completas de un expediente, listas para mostrar.
/// Devuelve pares (título, líneas).
List<(String, List<String>)> fichaCompleta(Expediente e) {
  final c = e.censo;
  return [
    ('Censo del campamento', filas([
      ('Cubículo', c['apto']),
      ('Nº de familia', c['nro_familia']),
      ('Campamento', c['campamento']),
      ('Estado', c['estado_procedencia']),
      ('Parroquia', c['parroquia_procedencia']),
      ('Vivienda antes del sismo', c['condicion_vivienda']),
      ('Color de inspección', c['color_inspeccion']),
      ('Posee vehículo', tri(c['posee_vehiculo'])),
      if (c['posee_vehiculo'] == 'si') ...[
        ('Placa', c['placa']),
        ('Modelo', c['modelo']),
      ],
      ('Carnet de la patria', c['carnet_codigo']),
      ('Serial del carnet', c['carnet_serial']),
      ('Observaciones del censo', c['observaciones']),
    ])),
    ('Jefe/a de familia', filasPersona(e.responsable, esJefe: true)),
    ...e.acompanantes.map((a) => (
          '${a.nombres} ${a.apellidos}'.trim(),
          filasPersona(a.toJson()),
        )),
  ];
}
