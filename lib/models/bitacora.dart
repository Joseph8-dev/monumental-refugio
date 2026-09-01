/// Lo que el vigilante registra en su turno: actividades del refugio,
/// incidencias y novedades de ayudas socioeconómicas. Comparten forma
/// para que el tablero las liste juntas en orden cronológico.
library;

class TipoBitacora {
  static const actividad = 'actividad';
  static const incidencia = 'incidencia';
  static const ayuda = 'ayuda';

  static String etiqueta(String t) => switch (t) {
        actividad => 'Actividad',
        incidencia => 'Incidencia / Novedad',
        ayuda => 'Ayuda socioeconómica',
        _ => t,
      };
}

class CatalogosBitacora {
  CatalogosBitacora._();

  /// Siempre se agrega 'Otros' al final: si la realidad del refugio no
  /// encaja en la lista, el vigilante escribe la suya en vez de forzar
  /// una categoría que no corresponde.
  static const otros = 'Otros';

  static const actividades = [
    'Actividades de recreación',
    'Actividades de educación',
    'Actividades deportivas',
    'Actividades religiosas',
    'Jornada de salud',
    'Jornada de vacunación',
    'Entrega de alimentos',
    'Entrega de insumos y dotación',
    'Limpieza y mantenimiento',
    'Charla o taller',
    'Visita institucional',
    otros,
  ];

  static const incidencias = [
    'Riña o conflicto entre refugiados',
    'Emergencia médica',
    'Falla de servicios (agua, luz, gas)',
    'Daño a instalaciones',
    'Pérdida o extravío de objetos',
    'Ingreso de persona no autorizada',
    'Salida no reportada',
    'Falta de insumos',
    'Situación con menores de edad',
    'Novedad de seguridad',
    otros,
  ];

  /// Provisionales: aún no hay lista oficial del ministerio. Cambiarlas
  /// es editar solo esta lista; el servidor acepta cualquier texto.
  static const ayudas = [
    'Solicitud de ayuda registrada',
    'Entrega de ayuda económica',
    'Entrega de bono',
    'Ayuda para reparación de vivienda',
    'Ayuda para alquiler temporal',
    'Entrega de enseres del hogar',
    'Gestión de documentos de identidad',
    'Referencia a institución',
    'Ayuda médica o medicamentos',
    'Ayuda rechazada o suspendida',
    otros,
  ];

  static List<String> deTipo(String tipo) => switch (tipo) {
        TipoBitacora.actividad => actividades,
        TipoBitacora.incidencia => incidencias,
        TipoBitacora.ayuda => ayudas,
        _ => const [otros],
      };
}

class RegistroBitacora {
  final int? id;
  final String tipo;
  final String categoria;
  final String? categoriaOtra;
  final String descripcion;
  final String? observacion;
  final int? expedienteId;
  final String? familia;
  final String? apto;
  final DateTime ocurrido;
  final String? operador;

  RegistroBitacora({
    this.id,
    required this.tipo,
    required this.categoria,
    this.categoriaOtra,
    required this.descripcion,
    this.observacion,
    this.expedienteId,
    this.familia,
    this.apto,
    required this.ocurrido,
    this.operador,
  });

  /// Categoría a mostrar: si eligió "Otros", lo que escribió.
  String get categoriaVisible =>
      categoria == CatalogosBitacora.otros && (categoriaOtra ?? '').isNotEmpty
          ? categoriaOtra!
          : categoria;

  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        'categoria': categoria,
        'categoria_otra': categoriaOtra,
        'descripcion': descripcion,
        'observacion': observacion,
        'expediente_id': expedienteId,
        'ocurrido': ocurrido.toUtc().toIso8601String(),
      };

  factory RegistroBitacora.fromJson(Map<String, dynamic> j) =>
      RegistroBitacora(
        id: j['id'] is int ? j['id'] : int.tryParse('${j['id'] ?? ''}'),
        tipo: j['tipo'] ?? TipoBitacora.actividad,
        categoria: j['categoria'] ?? '',
        categoriaOtra: j['categoria_otra'],
        descripcion: j['descripcion'] ?? '',
        observacion: j['observacion'],
        expedienteId: j['expediente_id'] is int
            ? j['expediente_id']
            : int.tryParse('${j['expediente_id'] ?? ''}'),
        familia: j['familia'],
        apto: j['apto'],
        ocurrido:
            DateTime.tryParse('${j['ocurrido']}')?.toLocal() ?? DateTime.now(),
        operador: j['operador'],
      );
}
