import 'package:flutter/material.dart';
import '../../datos.dart';
import '../../models/expediente.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../modulos.dart';
import 'persona_form.dart';
import 'steps.dart';
import 'steps_censo.dart';

/// Asistente por pasos.
/// Formato vigente (Modulos.censoMonumental): el CENSO DEL CAMPAMENTO,
/// que es una fila por persona en el Excel oficial:
///   1 Familia y ubicación · 2 Jefe/a de familia · 3 Integrantes ·
///   4 Foto y cierre.
/// Formato anterior (Modulos.planillaDamnificados): la planilla de
/// damnificados de 13 secciones. Se conserva y puede reactivarse desde
/// lib/modulos.dart; entonces sus pasos se agregan al final.
class WizardScreen extends StatefulWidget {
  final Expediente? existente;
  final String operador;
  const WizardScreen({super.key, this.existente, required this.operador});

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  late final Expediente exp;
  final _page = PageController();
  int _step = 0;
  bool _saving = false;

  static const _titlesCenso = [
    'Familia y ubicación',
    'Jefe/a de familia',
    'Integrantes',
    'Foto y cierre',
  ];

  static const _titlesPlanilla = [
    'Ingreso rápido',
    'Grupo familiar',
    'Salud y prioridad',
    'Vivienda afectada',
    'Necesidad de refugio',
    'Ayuda y documentos',
    'Firma y admisión',
  ];

  /// Títulos efectivos según el formato activo (ver lib/modulos.dart).
  static final List<String> _titles = [
    if (Modulos.censoMonumental) ..._titlesCenso,
    if (Modulos.planillaDamnificados) ..._titlesPlanilla,
  ];

  /// Cantidad de pasos del censo (offset para la planilla, si está activa).
  static final int _nCenso = Modulos.censoMonumental ? _titlesCenso.length : 0;

  @override
  void initState() {
    super.initState();
    // Hoy solo opera un refugio: viene preseleccionado y el operador solo
    // lo cambia si registra en otro ("Otros").
    exp = widget.existente ??
        Expediente(
            operador: widget.operador,
            refugio: Catalogos.refugioPorDefecto);
    if (exp.operador.isEmpty) exp.operador = widget.operador;
    _cargarRefugios();
  }

  /// Lista de refugios: viene del servidor; respaldo local si falla.
  List<String> _refugios = List.of(Catalogos.refugios);

  Future<void> _cargarRefugios() async {
    try {
      final lista = await ApiService.instance.refugios();
      if (lista.isNotEmpty && mounted) {
        setState(() => _refugios = lista);
      }
    } catch (_) {
      // Sin conexión o sesión vencida: se mantiene el respaldo local.
    }
    // Si el expediente trae un refugio que no está en la lista (fue escrito
    // a mano con "Otros"), activamos el modo manual para poder editarlo.
    if (exp.refugio.isNotEmpty && !_refugios.contains(exp.refugio)) {
      exp.refugioEsOtro = true;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  /// true si el valor de un TriChoice fue respondido (si/no/ns).
  bool _resp(dynamic v) => v == 'si' || v == 'no' || v == 'ns';

  /// true si el texto está vacío.
  bool _vacio(dynamic v) => (v ?? '').toString().trim().isEmpty;

  /// Valida los campos marcados como obligatorios en el instrumento,
  /// paso por paso. Devuelve el primer error o null si el paso está completo.
  String? _validateStep(int paso) {
    final r = exp.responsable;

    // ── Formato vigente: censo del Campamento Monumental ──
    if (Modulos.censoMonumental && paso < _nCenso) {
      final c = exp.censo;

      // Paso 1 · Familia y ubicación
      if (paso == 0) {
        if (exp.refugio.trim().isEmpty) {
          return exp.refugioEsOtro
              ? 'Escriba el nombre del refugio.'
              : 'Seleccione el refugio.';
        }
        if (_vacio(c['apto'])) {
          return 'Indique el apartamento o cubículo asignado.';
        }
        if (_vacio(c['estado_procedencia'])) {
          return 'Indique el estado de procedencia.';
        }
        if (_vacio(c['condicion_vivienda'])) {
          return 'Indique la condición de la vivienda antes del terremoto.';
        }
        if (!_resp(c['posee_vehiculo'])) {
          return 'Indique si la familia posee vehículo.';
        }
      }

      // Paso 2 · Jefe/a de familia
      if (paso == 1) return validarPersona(r, esJefe: true);

      // Paso 3 · Integrantes
      if (paso == 2) {
        for (final a in exp.acompanantes) {
          final err = validarPersona(a.toJson());
          if (err != null) return err;
        }
      }

      // Paso 4 · Cierre
      if (paso == 3) {
        if (_vacio(exp.estatus)) return 'Seleccione el estatus del expediente.';
        if (_vacio(exp.prioridad)) return 'Seleccione la prioridad.';
      }
      return null;
    }

    // ── Formato anterior: planilla de damnificados ──
    if (!Modulos.planillaDamnificados) return null;
    final i = paso - _nCenso;

    // Paso 1 · Ingreso rápido (secciones 1 y 2)
    if (i == 0) {
      if (_vacio(r['nombres']) || _vacio(r['apellidos'])) {
        return 'Nombres y apellidos del responsable son obligatorios.';
      }
      if (_vacio(r['cedula'])) return 'La cédula es obligatoria.';
      if (_vacio(r['fecha_nacimiento'])) {
        return 'La fecha de nacimiento es obligatoria.';
      }
      if (_vacio(r['sexo'])) return 'Seleccione el sexo.';
      if (_vacio(r['telefono'])) return 'El teléfono es obligatorio.';
      if (exp.refugio.isEmpty) {
        return exp.refugioEsOtro
            ? 'Escriba el nombre del refugio.'
            : 'Seleccione el refugio asignado.';
      }
      if (exp.ubicacionInterna.trim().isEmpty) {
        return 'Indique la ubicación interna / área asignada.';
      }
      if (!_resp(r['trabajador'])) {
        return 'Indique si es trabajador activo de Corpoelec.';
      }
      if (r['trabajador'] == 'si') {
        if (_vacio(r['codigo_trabajador'])) {
          return 'El código de trabajador es obligatorio.';
        }
        if (_vacio(r['cargo'])) return 'El cargo actual es obligatorio.';
        if (_vacio(r['gerencia'])) {
          return 'La gerencia / departamento es obligatoria.';
        }
      }
    }

    // Paso 3 · Grupo familiar (sección 3)
    if (i == 1) {
      if (exp.totalPersonas < 1) {
        return 'El total de personas debe ser al menos 1.';
      }
      final esperados = exp.totalPersonas - 1;
      if (exp.acompanantes.length != esperados) {
        return 'Indicó ${exp.totalPersonas} personas: registre '
            '$esperados acompañante(s) (lleva ${exp.acompanantes.length}).';
      }
      for (final a in exp.acompanantes) {
        if (a.edad == null) {
          return 'Falta la edad de ${a.nombres} ${a.apellidos}.';
        }
      }
    }

    // Paso 4 · Salud (sección 4)
    if (i == 2) {
      final s = exp.salud;
      if (!_resp(s['patologia'])) {
        return 'Indique si tiene alguna enfermedad o patología.';
      }
      if (s['patologia'] == 'si' && _vacio(s['patologia_desc'])) {
        return 'Describa la patología.';
      }
      if (!_resp(s['medicamentos'])) {
        return 'Indique si toma medicamentos.';
      }
      if (s['medicamentos'] == 'si' && _vacio(s['medicamentos_desc'])) {
        return 'Indique qué medicamentos necesita.';
      }
      if (!_resp(s['alergias'])) return 'Indique si tiene alergias.';
      if (s['alergias'] == 'si' && _vacio(s['alergias_desc'])) {
        return 'Indique a qué es alérgico.';
      }
      if (!_resp(s['discapacidad'])) {
        return 'Indique si tiene alguna discapacidad.';
      }
      if (s['discapacidad'] == 'si' && _vacio(s['discapacidad_tipo'])) {
        return 'Indique el tipo de discapacidad.';
      }
      if (!_resp(s['equipo_medico'])) {
        return 'Indique si requiere equipo médico especial.';
      }
      if (s['equipo_medico'] == 'si' && _vacio(s['equipo_medico_desc'])) {
        return 'Indique qué equipo médico requiere.';
      }
    }

    // Paso 5 · Vivienda y daño (secciones 5 y 6)
    if (i == 3) {
      final v = exp.vivienda;
      final d = exp.dano;
      if (_vacio(v['direccion'])) {
        return 'La dirección de la vivienda afectada es obligatoria.';
      }
      if (_vacio(v['estado'])) return 'Seleccione el estado.';
      if (_vacio(v['municipio'])) return 'Indique el municipio.';
      if (_vacio(v['parroquia'])) return 'Indique la parroquia o sector.';
      if (!_resp(v['residencia_principal'])) {
        return 'Indique si era su residencia principal y habitual.';
      }
      if (_vacio(v['ocupacion'])) {
        return 'Seleccione la condición de ocupación.';
      }
      if (_vacio(v['tipo'])) return 'Seleccione el tipo de vivienda.';
      if (!_resp(v['inspeccionada'])) {
        return 'Indique si fue inspeccionada por autoridad oficial.';
      }
      if (v['inspeccionada'] == 'si') {
        if (_vacio(v['organismo'])) {
          return 'Indique el organismo que inspeccionó.';
        }
        if (_vacio(v['dictamen'])) {
          return 'Seleccione el dictamen de habitabilidad.';
        }
      }
      if (_vacio(d['general'])) {
        return 'Seleccione el daño general reportado.';
      }
      if (!_resp(d['grietas'])) {
        return 'Indique si hay grietas en paredes o techos.';
      }
      if (d['grietas'] == 'si' && _vacio(d['grietas_severidad'])) {
        return 'Indique la severidad de las grietas.';
      }
      if (!_resp(d['estructura'])) {
        return 'Indique si hay estructura afectada.';
      }
      if (!_resp(d['riesgo_caida'])) {
        return 'Indique si hay riesgo de caída.';
      }
      if (!_resp(d['electricas'])) {
        return 'Indique si hay instalaciones eléctricas dañadas.';
      }
      if (!_resp(d['gas'])) return 'Indique si hay fuga de gas.';
      if (!_resp(d['agua'])) {
        return 'Indique si hay fuga de agua o aguas servidas.';
      }
      if (!_resp(d['bloqueada'])) {
        return 'Indique si la entrada o salida está bloqueada.';
      }
      if (!_resp(d['desalojo'])) {
        return 'Indique si recomendaron desalojo.';
      }
    }

    // Paso 6 · Necesidad de refugio y bienes (secciones 7 y 8)
    if (i == 4) {
      final n = exp.necesidad;
      final b = exp.bienes;
      if (!_resp(n['inhabitable'])) {
        return 'Indique si la vivienda quedó inhabitable.';
      }
      if (!_resp(n['alternativa'])) {
        return 'Indique si tiene otra opción habitacional segura.';
      }
      if (n['alternativa'] == 'si' && _vacio(n['alternativa_lugar'])) {
        return 'Indique dónde podría quedarse.';
      }
      if (_vacio(n['motivo'])) {
        return 'Seleccione el motivo de ingreso al refugio.';
      }
      if (n['acepta_temporal'] != true ||
          n['acepta_normas'] != true ||
          n['acepta_acuerdo'] != true) {
        return 'Debe aceptar la temporalidad, las normas y el acuerdo '
            'de responsabilidad para continuar.';
      }
      if (_vacio(b['bolsos'])) {
        return 'Indique la cantidad de bolsos o maletas del grupo.';
      }
      if (!_resp(b['documentos'])) {
        return 'Indique si trae documentos personales.';
      }
      if (!_resp(b['medicamentos'])) {
        return 'Indique si trae medicamentos.';
      }
      if (!_resp(b['equipo_medico'])) {
        return 'Indique si trae equipo médico autorizado.';
      }
      if (b['equipo_medico'] == 'si' && _vacio(b['equipo_medico_desc'])) {
        return 'Describa el equipo médico que trae.';
      }
      if (!_resp(b['no_permitidos'])) {
        return 'Indique si trae objetos no permitidos.';
      }
    }

    // Paso 7 · Ayuda social, artículos y documentos (secciones 9–11)
    if (i == 5) {
      final y = exp.ayuda;
      if (!_resp(y['solicita'])) {
        return 'Indique si desea solicitar ayuda social o económica.';
      }
      if (y['solicita'] == 'si' &&
          (y['tipos'] is! List || (y['tipos'] as List).isEmpty)) {
        return 'Seleccione el tipo de ayuda solicitada.';
      }
      if (!_resp(y['ayuda_previa'])) {
        return 'Indique si ha recibido otra ayuda por este evento.';
      }
      if (y['ayuda_previa'] == 'si') {
        if (_vacio(y['institucion'])) {
          return 'Indique la institución que otorgó la ayuda.';
        }
        if (_vacio(y['monto_recibido'])) {
          return 'Indique el monto recibido.';
        }
      }
    }

    // Paso 8 · Declaraciones, firmas y evaluación (secciones 12 y 13)
    if (i == 6) {
      final a = exp.aceptaciones;
      final ev = exp.evaluacion;
      final checks = [
        'decl_verdad',
        'decl_afectada',
        'decl_principal',
        'decl_ayuda',
        'autoriza_datos'
      ];
      if (checks.any((k) => a[k] != true)) {
        return 'Debe marcar todas las declaraciones antes de guardar.';
      }
      if ((a['firma_responsable'] ?? '') == '') {
        return 'Falta la firma del responsable.';
      }
      if ((a['firma_operador'] ?? '') == '') {
        return 'Falta la firma del operador.';
      }
      if (!_resp(ev['completo'])) {
        return 'Indique si el expediente mínimo está completo.';
      }
      if (!_resp(ev['medica'])) {
        return 'Indique si requiere atención médica inmediata.';
      }
      if (!_resp(ev['ninos_mayores'])) {
        return 'Indique si el grupo incluye niños o adultos mayores.';
      }
      if (!_resp(ev['escalar'])) {
        return 'Indique si el caso debe escalarse a coordinación.';
      }
      if (_vacio(ev['decision'])) {
        return 'Seleccione la decisión inicial.';
      }
    }
    return null;
  }

  void _go(int i) {
    setState(() => _step = i);
    _page.animateToPage(i,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic);
  }

  void _next() {
    final err = _validateStep(_step);
    if (err != null) {
      _snack(err, error: true);
      return;
    }
    if (_step < _titles.length - 1) _go(_step + 1);
  }

  Future<void> _save({bool borrador = false}) async {
    if (!borrador) {
      // Registro definitivo: valida TODOS los pasos y navega al primero
      // que tenga un campo obligatorio pendiente.
      for (var i = 0; i < _titles.length; i++) {
        final err = _validateStep(i);
        if (err != null) {
          _go(i);
          _snack(err, error: true);
          return;
        }
      }
    } else {
      // Borrador: mínimo para poder encontrar el registro después
      // (nombre, cédula y cubículo). No frena el censo en campo.
      final r = exp.responsable;
      if (_vacio(r['nombres']) || _vacio(r['apellidos'])) {
        _snack('Escriba al menos nombres y apellidos del jefe/a de familia.',
            error: true);
        return;
      }
      if (_vacio(r['cedula']) && _vacio(exp.censo['apto'])) {
        _snack('Indique la cédula o el cubículo para poder ubicar el registro.',
            error: true);
        return;
      }
    }

    // El borrador se marca como tal para distinguirlo en la lista; al
    // registrar en firme se le quita la marca.
    if (borrador) {
      exp.estatus = Catalogos.estatusBorrador;
    } else if (exp.estatus == Catalogos.estatusBorrador) {
      exp.estatus = 'Registro inicial';
    }

    setState(() => _saving = true);
    try {
      final api = ApiService.instance;
      final saved = exp.id == null
          ? await api.crear(exp)
          : await api.actualizar(exp);
      Datos.cambiaron(origen: 'wizard');
      if (!mounted) return;
      Navigator.pop(context, saved);
    } catch (e) {
      _snack('No se pudo guardar: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.ink,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_step + 1) / _titles.length;
    final last = _step == _titles.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('¿Salir sin guardar?'),
            content:
                const Text('Los cambios de este expediente se perderán.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Continuar editando')),
              FilledButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('Salir')),
            ],
          ),
        );
        if (leave == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(exp.id == null ? 'Nuevo expediente' : exp.codigo,
                  style: const TextStyle(fontSize: 16)),
              Text('Paso ${_step + 1} de ${_titles.length} · ${_titles[_step]}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: _saving ? null : () => _save(borrador: true),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Borrador'),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 4,
                backgroundColor: AppColors.line,
                color: AppColors.blue,
              ),
            ),
          ),
        ),
        body: PageView(
          controller: _page,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => setState(() => _step = i),
          children: [
            // ── Formato vigente: censo del Campamento Monumental ──
            if (Modulos.censoMonumental) ...[
              CensoPaso1Familia(
                  exp: exp, refugios: _refugios, onChanged: _refresh),
              CensoPaso2Jefe(exp: exp, onChanged: _refresh),
              CensoPaso3Integrantes(exp: exp, onChanged: _refresh),
              CensoPaso4Cierre(exp: exp, onChanged: _refresh),
            ],
            // ── Formato anterior: planilla de damnificados ──
            if (Modulos.planillaDamnificados) ...[
              Step1Ingreso(exp: exp, refugios: _refugios, onChanged: _refresh),
              Step2Grupo(exp: exp, onChanged: _refresh),
              Step3Salud(exp: exp, onChanged: _refresh),
              Step4Vivienda(exp: exp, onChanged: _refresh),
              Step5Necesidad(exp: exp, onChanged: _refresh),
              Step6Ayuda(exp: exp, onChanged: _refresh),
              Step7Firma(exp: exp, onChanged: _refresh),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _go(_step - 1),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Atrás'),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : (last ? _save : _next),
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(last ? Icons.check_circle_outline
                            : Icons.arrow_forward, size: 18),
                    label: Text(last
                        ? (exp.id == null
                            ? 'Registrar ingreso'
                            : 'Guardar cambios')
                        : 'Siguiente'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
