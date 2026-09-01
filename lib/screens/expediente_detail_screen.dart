import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../datos.dart';
import '../models/expediente.dart';
import '../modulos.dart';
import '../permisos.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/ficha.dart';
import '../widgets/form_widgets.dart';
import 'wizard/wizard_screen.dart';

class ExpedienteDetailScreen extends StatefulWidget {
  final int id;
  final String operador;
  const ExpedienteDetailScreen(
      {super.key, required this.id, required this.operador});

  @override
  State<ExpedienteDetailScreen> createState() =>
      _ExpedienteDetailScreenState();
}

class _ExpedienteDetailScreenState extends State<ExpedienteDetailScreen> {
  Expediente? exp;
  String? _error;
  bool _changed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final e = await ApiService.instance.obtener(widget.id);
      if (mounted) setState(() => exp = e);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _editar() async {
    final res = await Navigator.push<Expediente>(
      context,
      MaterialPageRoute(
          builder: (_) =>
              WizardScreen(existente: exp, operador: widget.operador)),
    );
    if (res != null && mounted) {
      _changed = true;
      setState(() => exp = res);
    }
  }

  Future<void> _cambiarEstatus(String nuevo) async {
    final e = exp!;
    final prev = e.estatus;
    setState(() {
      e.estatus = nuevo;
      _busy = true;
    });
    try {
      exp = await ApiService.instance.actualizar(e);
      Datos.cambiaron(origen: 'detalle');
      _changed = true;
    } catch (err) {
      e.estatus = prev;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('No se pudo actualizar: $err'),
            backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _eliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar expediente'),
        content: Text(
            'El expediente ${exp!.codigo} se marcará como eliminado. ¿Continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ApiService.instance.eliminar(exp!.id!);
      Datos.cambiaron(origen: 'detalle');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('No se pudo eliminar: $e'),
            backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(exp?.codigo ?? 'Expediente'),
          actions: [
            if (exp != null && Permisos.puede(Permiso.registrar))
              IconButton(
                  onPressed: _busy ? null : _editar,
                  icon: const Icon(Icons.edit_outlined)),
            if (exp != null && Permisos.puede(Permiso.administrar))
              IconButton(
                  onPressed: _busy ? null : _eliminar,
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.danger)),
          ],
        ),
        body: _error != null
            ? Center(
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.gray)))
            : exp == null
                ? const Center(child: CircularProgressIndicator())
                : _body(exp!),
      ),
    );
  }

  Widget _body(Expediente e) {
    final f = DateTime.tryParse(e.fechaIngreso);
    final fecha = f == null
        ? e.fechaIngreso
        : DateFormat('dd/MM/yyyy · hh:mm a').format(f.toLocal());
    final alertas = e.alertas;
    final foto = e.aceptaciones['foto_responsable'] as String?;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (foto != null && foto.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: CircleAvatar(
                            radius: 26,
                            backgroundImage:
                                MemoryImage(base64Decode(foto))),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.nombreResponsable,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17)),
                          const SizedBox(height: 2),
                          Text(
                              'C.I. ${e.responsable['cedula'] ?? '—'} · Tel. ${e.responsable['telefono'] ?? '—'}',
                              style: const TextStyle(
                                  color: AppColors.gray, fontSize: 13)),
                        ],
                      ),
                    ),
                    Badge2(e.prioridad, color: prioridadColor(e.prioridad)),
                  ],
                ),
                const Divider(height: 24),
                _row('Refugio', e.refugio),
                _row('Área asignada',
                    e.ubicacionInterna.isEmpty ? '—' : e.ubicacionInterna),
                _row('Ingreso', fecha),
                _row('Operador', e.operador),
                _row('Grupo',
                    '${e.totalPersonas} persona${e.totalPersonas == 1 ? '' : 's'} (${e.cantidadAcompanantes} acompañantes)'),
                const SizedBox(height: 10),
                AppDropdown(
                  label: 'Estatus del expediente',
                  value: e.estatus,
                  items: Catalogos.estatus,
                  onChanged: _busy
                      ? (_) {}
                      : (v) {
                          if (v != null && v != e.estatus) {
                            _cambiarEstatus(v);
                          }
                        },
                ),
              ],
            ),
          ),
        ),
        if (alertas.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: alertas.map((a) => AlertaChip(a)).toList(),
          ),
        ],
        const SizedBox(height: 14),
        // Fotos cargadas del expediente: cédula del jefe/a y grupo familiar.
        _Fotos(exp: e),
        // ── Formato vigente: censo del Campamento Monumental ──
        if (Modulos.censoMonumental) ...[
          _resumen('Censo del campamento', Icons.apartment_outlined, filas([
            ('Cubículo', e.censo['apto']),
            ('Nº de familia', e.censo['nro_familia']),
            ('Campamento', e.censo['campamento']),
            ('Estado', e.censo['estado_procedencia']),
            ('Parroquia', e.censo['parroquia_procedencia']),
            ('Vivienda antes del sismo', e.censo['condicion_vivienda']),
            ('Color de inspección', e.censo['color_inspeccion']),
            ('Posee vehículo', tri(e.censo['posee_vehiculo'])),
            if (e.censo['posee_vehiculo'] == 'si') ...[
              ('Placa', e.censo['placa']),
              ('Modelo', e.censo['modelo']),
            ],
            ('Carnet de la patria', e.censo['carnet_codigo']),
            ('Serial del carnet', e.censo['carnet_serial']),
            ('Observaciones del censo', e.censo['observaciones']),
          ])),
          _resumen('Jefe/a de familia', Icons.person_outline,
              filasPersona(e.responsable, esJefe: true)),
        ],
        // Cada integrante con su ficha completa, no solo una línea.
        if (e.acompanantes.isEmpty)
          _resumen('Integrantes', Icons.groups_outlined,
              const ['Sin otros integrantes'])
        else
          ...e.acompanantes.map((a) => _resumen(
                '${a.nombres} ${a.apellidos}'.trim(),
                Icons.person_outline,
                filasPersona(a.toJson()),
              )),
        // ── Formato anterior: planilla de damnificados ──
        if (Modulos.planillaDamnificados) ...[
        _resumen('Salud', Icons.medical_services_outlined, [
          'Patología: ${tri(e.salud['patologia'])}${esSi(e.salud['patologia']) ? ' — ${e.salud['patologia_desc'] ?? ''}' : ''}',
          'Medicamentos: ${tri(e.salud['medicamentos'])}',
          'Discapacidad: ${tri(e.salud['discapacidad'])}',
          'Equipo médico: ${tri(e.salud['equipo_medico'])}',
        ]),
        _resumen('Vivienda afectada', Icons.home_outlined, [
          e.vivienda['direccion'] ?? '—',
          'Daño general: ${e.dano['general'] ?? '—'}',
          'Dictamen: ${e.vivienda['dictamen'] ?? '—'}',
          'Riesgo de caída: ${tri(e.dano['riesgo_caida'])} · Desalojo: ${tri(e.dano['desalojo'])}',
        ]),
        _resumen('Refugio y ayuda', Icons.volunteer_activism_outlined, [
          'Motivo: ${e.necesidad['motivo'] ?? '—'}',
          'Tiempo estimado: ${e.necesidad['tiempo'] ?? '—'}',
          'Solicita ayuda: ${tri(e.ayuda['solicita'])}',
          'Ayuda previa: ${tri(e.ayuda['ayuda_previa'])}',
          'Artículos declarados: ${e.articulos.length}',
        ]),
        _resumen('Documentos', Icons.folder_open_outlined, [
          ...e.documentos.entries.map((d) =>
              '${d.value == 'cargado' ? '✓' : '○'} ${d.key} — ${d.value}'),
        ]),
        _resumen('Evaluación', Icons.rule_outlined, [
          'Decisión inicial: ${e.evaluacion['decision'] ?? '—'}',
          'Atención médica inmediata: ${tri(e.evaluacion['medica'])}',
          'Escalar a coordinación: ${tri(e.evaluacion['escalar'])}',
          if ((e.evaluacion['observaciones'] ?? '').toString().isNotEmpty)
            'Obs.: ${e.evaluacion['observaciones']}',
        ]),
        ],
      ],
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 110,
                child: Text(k,
                    style: const TextStyle(
                        color: AppColors.gray, fontSize: 13))),
            Expanded(
                child: Text(v,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w500))),
          ],
        ),
      );

  Widget _resumen(String title, IconData icon, List<String> lines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(icon, color: AppColors.blueDark, size: 20),
            title: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14.5)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            children: lines
                .map((l) => Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(l,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.ink)),
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}


/// Sí / No / No sabe legibles. A nivel superior porque lo usan tanto la
/// pantalla como las funciones que arman las fichas.
/// Fotos del expediente: cédula del jefe/a de familia y foto del grupo.
/// Se abren a pantalla completa al tocarlas, para poder leer la cédula.
class _Fotos extends StatelessWidget {
  final Expediente exp;
  const _Fotos({required this.exp});

  void _ver(BuildContext context, String b64, String titulo) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Flexible(
              // InteractiveViewer permite acercar para leer el documento.
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(base64Decode(b64)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(titulo,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cedula = (exp.responsable['documento_imagen'] ?? '').toString();
    final familia = (exp.censo['foto_familia'] ?? '').toString();
    if (cedula.isEmpty && familia.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library_outlined,
                  size: 18, color: AppColors.blue),
              const SizedBox(width: 8),
              const Text('Fotos del expediente',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cedula.isNotEmpty)
                Expanded(
                  child: _Miniatura(
                    b64: cedula,
                    titulo: 'Cédula del jefe/a',
                    onTap: () => _ver(context, cedula, 'Cédula del jefe/a'),
                  ),
                ),
              if (cedula.isNotEmpty && familia.isNotEmpty)
                const SizedBox(width: 12),
              if (familia.isNotEmpty)
                Expanded(
                  child: _Miniatura(
                    b64: familia,
                    titulo: 'Grupo familiar',
                    onTap: () => _ver(context, familia, 'Grupo familiar'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  final String b64, titulo;
  final VoidCallback onTap;
  const _Miniatura(
      {required this.b64, required this.titulo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              base64Decode(b64),
              height: 116,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(titulo,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.gray)),
              ),
              const Icon(Icons.zoom_in, size: 14, color: AppColors.grayLight),
            ],
          ),
        ],
      ),
    );
  }
}
