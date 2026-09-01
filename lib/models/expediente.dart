import 'dart:math';

/// Valores tri-estado usados en toda la planilla.
/// 'si' / 'no' / 'ns' (no sabe).
bool esSi(dynamic v) => v == 'si';
bool esNo(dynamic v) => v == 'no';

/// Catálogos (listas desplegables) según la planilla maestra.
class Catalogos {
  Catalogos._();

  /// Estatus del expediente. 'Borrador' es el que asigna el botón
  /// "Guardar borrador": marca un registro incompleto que hay que volver
  /// a abrir para terminar.
  static const estatusBorrador = 'Borrador';

  static const estatus = [
    estatusBorrador,
    'Registro inicial',
    'Admitido temporalmente',
    'Documentos pendientes',
    'En evaluación social',
    'En evaluación técnica',
    'Aprobado para ayuda',
    'Rechazado motivado',
    'Egresado del refugio',
  ];

  static const prioridades = ['Normal', 'Alta', 'Urgente'];

  // ── Censo Campamento Monumental (estructura del Excel oficial) ──

  /// Condición de salud: base del tablero de patologías del dashboard.
  static const condicionesSalud = [
    'SANO', 'HIPERTENSO', 'DIABÉTICO', 'ASMÁTICO', 'CARDIÓPATA',
    'DISCAPACITADO', 'EMBARAZADA', 'LACTANTE', 'ONCOLÓGICO',
    'RENAL', 'EPILÉPTICO', 'OTRA',
  ];

  static const tiposSangre = [
    'O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'NO CONOCE',
  ];

  /// Condición de la vivienda ANTES del terremoto (métrica del dashboard).
  static const condicionVivienda = [
    'PROPIA', 'ALQUILADA', 'FAMILIAR', 'INVASIÓN', 'OTRA', 'SIN DATO',
  ];

  /// Color de la inspección oficial (semáforo de habitabilidad).
  static const coloresInspeccion = [
    'VERDE', 'AMARILLO', 'ROJO', 'NEGRO', 'SIN INSPECCIÓN',
  ];

  static const tallas = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'NO APLICA'];
  static const tallasGorra = ['UNICA', 'S', 'M', 'L', 'NO APLICA'];

  /// Roles de usuario del sistema.
  static const roles = ['admin', 'recolector', 'vigilante'];

  /// Lista de respaldo si el servidor no responde. La lista real se obtiene
  /// de GET /api/refugio/refugios (tabla rf_refugios) al abrir el asistente.
  static const refugios = [
    'Campamento Temporal Monumental',
    'Otros',
  ];

  /// Refugio preseleccionado al abrir un registro nuevo.
  static const refugioPorDefecto = 'Campamento Temporal Monumental';

  static const sexos = ['Masculino', 'Femenino', 'Otro', 'Prefiere no indicar'];
  static const nacionalidades = ['Venezolana', 'Extranjera'];

  /// Parentescos. IMPORTANTE: debe contener todos los valores que produce
  /// `parentesco()` en backend/importar_censo.js, o los expedientes
  /// importados mostrarían el campo vacío al editarlos.
  static const parentescos = [
    'Jefe/a', 'Cónyuge', 'Pareja', 'Hijo/a', 'Madre/Padre', 'Hermano/a',
    'Abuelo/a', 'Nieto/a', 'Tío/a', 'Sobrino/a', 'Primo/a', 'Yerno/Nuera',
    'Otro',
  ];

  static const condicionesEspeciales = [
    'Niño/a', 'Adulto mayor', 'Embarazada', 'Discapacidad', 'Enfermedad crónica'
  ];

  static const gruposSanguineos = ['A', 'B', 'AB', 'O', 'No sabe'];
  static const factoresRh = ['Positivo', 'Negativo', 'No sabe'];

  static const tiposDiscapacidad = [
    'Motora', 'Visual', 'Auditiva', 'Intelectual', 'Psicosocial', 'Otra'
  ];

  static const estadosVE = [
    'Amazonas', 'Anzoátegui', 'Apure', 'Aragua', 'Barinas', 'Bolívar',
    'Carabobo', 'Cojedes', 'Delta Amacuro', 'Distrito Capital', 'Falcón',
    'Guárico', 'La Guaira', 'Lara', 'Mérida', 'Miranda', 'Monagas',
    'Nueva Esparta', 'Portuguesa', 'Sucre', 'Táchira', 'Trujillo',
    'Yaracuy', 'Zulia',
  ];

  static const condicionesOcupacion = [
    'Propietario', 'Arrendatario', 'Familiar', 'Adjudicado', 'Otro'
  ];

  static const tiposVivienda = [
    'Casa', 'Apartamento', 'Quinta', 'Habitación', 'Vivienda improvisada', 'Otro'
  ];

  static const dictamenes = [
    'Habitable', 'Restringido', 'Inseguro', 'No tiene dictamen'
  ];

  static const danosGenerales = [
    'Leve', 'Moderado', 'Grave', 'Pérdida total', 'No sabe'
  ];

  static const severidades = ['Baja', 'Media', 'Alta'];

  static const motivosIngreso = [
    'Vivienda inhabitable', 'Riesgo estructural', 'Pérdida total',
    'Sin familiares de apoyo', 'Otro'
  ];

  static const tiemposEstimados = [
    '1 a 7 días', '8 a 15 días', '16 a 30 días', 'No sabe'
  ];

  static const tiposAyuda = [
    'Reparación mayor', 'Reparación menor', 'Artículos del hogar'
  ];

  static const estadosArticulo = ['Perdido', 'Dañado', 'Recuperable'];

  static const decisionesIniciales = [
    'Admitido',
    'Admitido con documentos pendientes',
    'En espera',
    'Referido a coordinación',
  ];

  /// Documentos anexos del expediente (sección 11).
  static const documentos = [
    'Cédula del trabajador',
    'Cédulas del grupo familiar',
    'Constancia de trabajo o recibo de pago',
    'Documento de propiedad o posesión',
    'Acta de Protección Civil / Bomberos',
    'Registro fotográfico de daños',
    'Formulario de solicitud de ayuda social',
    'Declaración jurada',
    'Acuerdo de responsabilidad compartida',
    'Lineamiento de uso temporal aceptado',
  ];
}

/// Edad calculada al día de hoy a partir de la fecha de nacimiento.
/// La edad guardada en el censo es una foto del día en que se levantó el
/// dato: si solo se usara ese número, un niño de 17 seguiría contando como
/// menor para siempre. Cuando hay fecha se recalcula; el número guardado
/// queda de respaldo para quienes no la tienen registrada.
int? edadViva({String? fechaNacimiento, dynamic edadGuardada}) {
  final f = fechaNacimiento;
  if (f != null && f.isNotEmpty) {
    final d = DateTime.tryParse(f);
    if (d != null) {
      final hoy = DateTime.now();
      var e = hoy.year - d.year;
      if (hoy.month < d.month || (hoy.month == d.month && hoy.day < d.day)) {
        e--;
      }
      if (e >= 0 && e < 130) return e;
    }
  }
  if (edadGuardada is int) return edadGuardada;
  return int.tryParse('${edadGuardada ?? ''}');
}

/// Clase de alerta del expediente.
///  · atencion  → necesidad de cuidado de la familia (azul)
///  · pendiente → falta algo por cargar en el expediente (ámbar)
enum TipoAlerta { atencion, pendiente }

/// Cada alerta tiene su propio icono para distinguirla de un vistazo:
/// un niño no es lo mismo que un adulto mayor, aunque ambas sean de
/// "atención".
enum ClaseAlerta {
  ninos,
  adultoMayor,
  discapacidad,
  embarazo,
  condicionMedica,
  sinCedula,
  sinFotoFamilia,
}

class Alerta {
  final ClaseAlerta clase;
  final String texto;
  final TipoAlerta tipo;
  const Alerta(this.clase, this.texto, this.tipo);

  const Alerta.atencion(this.clase, this.texto) : tipo = TipoAlerta.atencion;
  const Alerta.pendiente(this.clase, this.texto)
      : tipo = TipoAlerta.pendiente;

  bool get esPendiente => tipo == TipoAlerta.pendiente;

  @override
  String toString() => texto;
}

/// Acompañante del grupo familiar (bloque repetible, sección 3.1).
class Acompanante {
  String nombres;
  String apellidos;
  String cedula;
  String? fechaNacimiento; // ISO yyyy-MM-dd
  int? edad;
  String parentesco;
  String cargaFamiliar; // si / no / ns
  String telefono;
  List<String> condiciones; // condiciones especiales
  bool documentoCargado;
  String? documentoImagen; // foto de cédula/documento en base64
  // ── Censo Monumental (por persona) ──
  String sexo;
  String condicionSalud;
  String tipoSangre;
  String brazalete;
  String ocupacion;
  String dieta; // 'si'/'no'
  String estatura;
  String tallaCamisa;
  String tallaPantalon;
  String calzado;
  String gorra;
  String observaciones;

  Acompanante({
    this.nombres = '',
    this.apellidos = '',
    this.cedula = '',
    this.fechaNacimiento,
    this.edad,
    this.parentesco = 'Hijo/a',
    this.cargaFamiliar = 'ns',
    this.telefono = '',
    List<String>? condiciones,
    this.documentoCargado = false,
    this.documentoImagen,
    this.sexo = '',
    this.condicionSalud = 'SANO',
    this.tipoSangre = 'NO CONOCE',
    this.brazalete = '',
    this.ocupacion = '',
    this.dieta = 'no',
    this.estatura = '',
    this.tallaCamisa = '',
    this.tallaPantalon = '',
    this.calzado = '',
    this.gorra = '',
    this.observaciones = '',
  }) : condiciones = condiciones ?? [];

  /// Edad recalculada a hoy (ver `edadViva`).
  int? get edadHoy =>
      edadViva(fechaNacimiento: fechaNacimiento, edadGuardada: edad);

  Map<String, dynamic> toJson() => {
        'nombres': nombres,
        'apellidos': apellidos,
        'cedula': cedula,
        'fecha_nacimiento': fechaNacimiento,
        'edad': edad,
        'parentesco': parentesco,
        'carga_familiar': cargaFamiliar,
        'telefono': telefono,
        'condiciones': condiciones,
        'documento_cargado': documentoCargado,
        'documento_imagen': documentoImagen,
        'sexo': sexo,
        'condicion_salud': condicionSalud,
        'tipo_sangre': tipoSangre,
        'brazalete': brazalete,
        'ocupacion': ocupacion,
        'dieta': dieta,
        'estatura': estatura,
        'talla_camisa': tallaCamisa,
        'talla_pantalon': tallaPantalon,
        'calzado': calzado,
        'gorra': gorra,
        'observaciones': observaciones,
      };

  factory Acompanante.fromJson(Map<String, dynamic> j) => Acompanante(
        nombres: j['nombres'] ?? '',
        apellidos: j['apellidos'] ?? '',
        cedula: j['cedula'] ?? '',
        fechaNacimiento: j['fecha_nacimiento'],
        edad: j['edad'] is int ? j['edad'] : int.tryParse('${j['edad'] ?? ''}'),
        parentesco: j['parentesco'] ?? 'Otro',
        cargaFamiliar: j['carga_familiar'] ?? 'ns',
        telefono: j['telefono'] ?? '',
        condiciones: (j['condiciones'] as List?)?.cast<String>() ?? [],
        documentoCargado: j['documento_cargado'] == true,
        documentoImagen: j['documento_imagen'],
        sexo: j['sexo'] ?? '',
        condicionSalud: j['condicion_salud'] ?? 'SANO',
        tipoSangre: j['tipo_sangre'] ?? 'NO CONOCE',
        brazalete: j['brazalete'] ?? '',
        ocupacion: j['ocupacion'] ?? '',
        dieta: j['dieta'] ?? 'no',
        estatura: j['estatura'] ?? '',
        tallaCamisa: j['talla_camisa'] ?? '',
        tallaPantalon: j['talla_pantalon'] ?? '',
        calzado: j['calzado'] ?? '',
        gorra: j['gorra'] ?? '',
        observaciones: j['observaciones'] ?? '',
      );
}

/// Artículo del hogar perdido o dañado (bloque repetible, sección 10).
class ArticuloDanado {
  int cantidad;
  String descripcion;
  String estado; // Perdido / Dañado / Recuperable
  double? valorUsd;
  String? fotoBase64;
  String observaciones;

  ArticuloDanado({
    this.cantidad = 1,
    this.descripcion = '',
    this.estado = 'Dañado',
    this.valorUsd,
    this.fotoBase64,
    this.observaciones = '',
  });

  Map<String, dynamic> toJson() => {
        'cantidad': cantidad,
        'descripcion': descripcion,
        'estado': estado,
        'valor_usd': valorUsd,
        'foto': fotoBase64,
        'observaciones': observaciones,
      };

  factory ArticuloDanado.fromJson(Map<String, dynamic> j) => ArticuloDanado(
        cantidad: j['cantidad'] is int
            ? j['cantidad']
            : int.tryParse('${j['cantidad'] ?? 1}') ?? 1,
        descripcion: j['descripcion'] ?? '',
        estado: j['estado'] ?? 'Dañado',
        valorUsd: j['valor_usd'] == null
            ? null
            : double.tryParse('${j['valor_usd']}'),
        fotoBase64: j['foto'],
        observaciones: j['observaciones'] ?? '',
      );
}

/// Expediente completo del grupo familiar.
class Expediente {
  int? id;
  String codigo;
  String fechaIngreso; // ISO
  String refugio;
  String ubicacionInterna;
  String operador;
  String estatus;
  String prioridad;

  // 2. Responsable principal
  Map<String, dynamic> responsable;

  // 3. Grupo familiar
  int totalPersonas;
  String poblacionPrioritaria; // si/no
  List<Acompanante> acompanantes;

  // 4–13. Secciones flexibles (clave → valor)
  Map<String, dynamic> salud;
  Map<String, dynamic> vivienda;
  Map<String, dynamic> dano;
  Map<String, dynamic> necesidad;
  Map<String, dynamic> bienes;
  Map<String, dynamic> ayuda;
  List<ArticuloDanado> articulos;
  /// Flag de UI (no se guarda): el refugio fue escrito manualmente ("Otros").
  bool refugioEsOtro = false;

  Map<String, String> documentos; // nombre → 'cargado'/'pendiente'
  Map<String, List<String>> documentosImagenes; // nombre → fotos base64
  Map<String, dynamic> aceptaciones;
  Map<String, dynamic> evaluacion;

  /// Datos del censo Campamento Monumental (apartamento/cubículo, campamento
  /// de origen, brazalete, tallas, vehículo, carnet de la patria, foto
  /// familiar). Estructura alineada al Excel oficial del refugio.
  Map<String, dynamic> censo;

  Expediente({
    this.id,
    String? codigo,
    String? fechaIngreso,
    this.refugio = '',
    this.ubicacionInterna = '',
    this.operador = '',
    this.estatus = 'Registro inicial',
    this.prioridad = 'Normal',
    Map<String, dynamic>? responsable,
    this.totalPersonas = 1,
    this.poblacionPrioritaria = 'no',
    List<Acompanante>? acompanantes,
    Map<String, dynamic>? salud,
    Map<String, dynamic>? vivienda,
    Map<String, dynamic>? dano,
    Map<String, dynamic>? necesidad,
    Map<String, dynamic>? bienes,
    Map<String, dynamic>? ayuda,
    List<ArticuloDanado>? articulos,
    Map<String, String>? documentos,
    Map<String, List<String>>? documentosImagenes,
    Map<String, dynamic>? aceptaciones,
    Map<String, dynamic>? evaluacion,
    Map<String, dynamic>? censo,
  })  : codigo = codigo ?? _generarCodigo(),
        fechaIngreso = fechaIngreso ?? DateTime.now().toIso8601String(),
        responsable = responsable ?? {},
        acompanantes = acompanantes ?? [],
        salud = salud ?? {},
        vivienda = vivienda ?? {},
        dano = dano ?? {},
        necesidad = necesidad ?? {},
        bienes = bienes ?? {},
        ayuda = ayuda ?? {},
        articulos = articulos ?? [],
        documentos = documentos ??
            {for (final d in Catalogos.documentos) d: 'pendiente'},
        documentosImagenes = documentosImagenes ?? {},
        aceptaciones = aceptaciones ?? {},
        evaluacion = evaluacion ?? {},
        censo = censo ?? {};

  static String _generarCodigo() {
    final now = DateTime.now();
    final r = Random().nextInt(9000) + 1000;
    return 'RP-${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}-$r';
  }

  int get cantidadAcompanantes => acompanantes.length;

  String get nombreResponsable =>
      '${responsable['nombres'] ?? ''} ${responsable['apellidos'] ?? ''}'
          .trim();

  /// Alertas automáticas del expediente.
  /// Se dividen en dos familias para que no se confundan entre sí:
  ///  · ATENCIÓN (azul): quién es esta familia y qué cuidados requiere
  ///    — niños, adultos mayores, discapacidad, enfermedad. NO es un
  ///    problema del expediente: es información para el refugio.
  ///  · PENDIENTE (ámbar): qué le falta al expediente y hay que completar
  ///    — foto de cédula, foto familiar.
  List<Alerta> get alertas {
    final a = <Alerta>[];

    // Se cuentan PERSONAS (jefe/a incluido), no solo si existe alguna:
    // una familia con 1 niño y 1 adulto mayor muestra "1 niño" y
    // "1 adulto mayor", no "2 alertas".
    final edadJefe = edadViva(
        fechaNacimiento: responsable['fecha_nacimiento']?.toString(),
        edadGuardada: responsable['edad']);

    var nNinos = 0, nMayores = 0;
    if (edadJefe != null) {
      if (edadJefe < 18) nNinos++;
      if (edadJefe >= 60) nMayores++;
    }
    for (final x in acompanantes) {
      final e = x.edadHoy;
      final esNino =
          x.condiciones.contains('Niño/a') || (e != null && e < 18);
      final esMayor =
          x.condiciones.contains('Adulto mayor') || (e != null && e >= 60);
      if (esNino) nNinos++;
      if (esMayor) nMayores++;
    }
    final tieneNinos = nNinos > 0;
    final tieneMayores = nMayores > 0;

    String cond(dynamic v) => (v ?? '').toString().toUpperCase();
    final discapacidad = esSi(salud['discapacidad']) ||
        cond(responsable['condicion_salud']).contains('DISCAPA') ||
        acompanantes.any((x) =>
            x.condiciones.contains('Discapacidad') ||
            x.condicionSalud.toUpperCase().contains('DISCAPA'));
    final enfermos = <String>{
      if (cond(responsable['condicion_salud']) != 'SANO' &&
          cond(responsable['condicion_salud']).isNotEmpty)
        cond(responsable['condicion_salud']),
      for (final x in acompanantes)
        if (x.condicionSalud.toUpperCase() != 'SANO' &&
            x.condicionSalud.isNotEmpty)
          x.condicionSalud.toUpperCase(),
    };

    // Documentos faltantes.
    final sinCedula = (responsable['documento_imagen'] ?? '') == '';
    final sinFotoFamilia = (censo['foto_familia'] ?? '') == '';

    final embarazo = enfermos.any((e) => e.contains('EMBARAZ'));
    // Las condiciones médicas se listan aparte de discapacidad y embarazo,
    // que ya tienen su propia alerta.
    final medicas = enfermos.where((e) =>
        !e.contains('DISCAPA') && !e.contains('EMBARAZ'));

    if (tieneNinos) {
      a.add(Alerta.atencion(ClaseAlerta.ninos,
          nNinos == 1 ? '1 niño' : '$nNinos niños'));
    }
    if (tieneMayores) {
      a.add(Alerta.atencion(ClaseAlerta.adultoMayor,
          nMayores == 1 ? '1 adulto mayor' : '$nMayores adultos mayores'));
    }
    if (discapacidad) {
      a.add(Alerta.atencion(ClaseAlerta.discapacidad, 'Discapacidad'));
    }
    if (embarazo) a.add(Alerta.atencion(ClaseAlerta.embarazo, 'Embarazada'));
    if (medicas.isNotEmpty) {
      a.add(Alerta.atencion(ClaseAlerta.condicionMedica,
          medicas.length == 1 ? medicas.first : 'Condiciones médicas'));
    }
    if (sinCedula) {
      a.add(Alerta.pendiente(ClaseAlerta.sinCedula, 'Sin foto de cédula'));
    }
    if (sinFotoFamilia) {
      a.add(Alerta.pendiente(
          ClaseAlerta.sinFotoFamilia, 'Sin foto familiar'));
    }
    return a;
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'codigo': codigo,
        'fecha_ingreso': fechaIngreso,
        'refugio': refugio,
        'ubicacion_interna': ubicacionInterna,
        'operador': operador,
        'estatus': estatus,
        'prioridad': prioridad,
        'responsable': responsable,
        'total_personas': totalPersonas,
        'poblacion_prioritaria': poblacionPrioritaria,
        'acompanantes': acompanantes.map((x) => x.toJson()).toList(),
        'salud': salud,
        'vivienda': vivienda,
        'dano': dano,
        'necesidad': necesidad,
        'bienes': bienes,
        'ayuda': ayuda,
        'articulos': articulos.map((x) => x.toJson()).toList(),
        'documentos': documentos,
        'documentos_imagenes': documentosImagenes,
        'aceptaciones': aceptaciones,
        'evaluacion': evaluacion,
        'censo': censo,
      };

  factory Expediente.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> m(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : {};
    return Expediente(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id'] ?? ''}'),
      codigo: j['codigo'],
      fechaIngreso: j['fecha_ingreso'] ?? DateTime.now().toIso8601String(),
      refugio: j['refugio'] ?? '',
      ubicacionInterna: j['ubicacion_interna'] ?? '',
      operador: j['operador'] ?? '',
      estatus: j['estatus'] ?? 'Registro inicial',
      prioridad: j['prioridad'] ?? 'Normal',
      responsable: m(j['responsable']),
      totalPersonas: j['total_personas'] is int
          ? j['total_personas']
          : int.tryParse('${j['total_personas'] ?? 1}') ?? 1,
      poblacionPrioritaria: j['poblacion_prioritaria'] ?? 'no',
      acompanantes: (j['acompanantes'] as List? ?? [])
          .map((x) => Acompanante.fromJson(Map<String, dynamic>.from(x)))
          .toList(),
      salud: m(j['salud']),
      vivienda: m(j['vivienda']),
      dano: m(j['dano']),
      necesidad: m(j['necesidad']),
      bienes: m(j['bienes']),
      ayuda: m(j['ayuda']),
      articulos: (j['articulos'] as List? ?? [])
          .map((x) => ArticuloDanado.fromJson(Map<String, dynamic>.from(x)))
          .toList(),
      documentosImagenes: j['documentos_imagenes'] is Map
          ? (j['documentos_imagenes'] as Map).map((k, v) =>
              MapEntry('$k', (v as List?)?.cast<String>() ?? <String>[]))
          : {},
      documentos: j['documentos'] is Map
          ? Map<String, String>.from(
              (j['documentos'] as Map).map((k, v) => MapEntry('$k', '$v')))
          : null,
      aceptaciones: m(j['aceptaciones']),
      evaluacion: m(j['evaluacion']),
      censo: m(j['censo']),
    );
  }
}
