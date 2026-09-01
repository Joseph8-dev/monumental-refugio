import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/expediente.dart';
import '../../theme.dart';
import '../../widgets/form_widgets.dart';
import 'persona_form.dart';

const _pad = EdgeInsets.fromLTRB(16, 8, 16, 100);

// PASO 1 · Familia y ubicación
// Datos que en el Excel son iguales para todas las filas de la familia.
class CensoPaso1Familia extends StatelessWidget {
  final Expediente exp;
  final List<String> refugios;
  final VoidCallback onChanged;
  const CensoPaso1Familia(
      {super.key,
      required this.exp,
      required this.refugios,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = exp.censo;

    return ListView(
      padding: _pad,
      children: [
        SectionCard(
          title: 'Ubicación en el refugio',
          subtitle: 'Dónde queda alojada la familia',
          icon: Icons.apartment_outlined,
          children: [
            AppDropdown(
              label: 'Refugio',
              required: true,
              value: exp.refugioEsOtro
                  ? 'Otros'
                  : (exp.refugio.isEmpty ? null : exp.refugio),
              items: refugios,
              onChanged: (v) {
                if (v == 'Otros') {
                  exp.refugioEsOtro = true;
                  exp.refugio = '';
                } else {
                  exp.refugioEsOtro = false;
                  exp.refugio = v ?? '';
                }
                onChanged();
              },
            ),
            Conditional(
              show: exp.refugioEsOtro,
              child: AppTextField(
                label: 'Nombre del refugio',
                required: true,
                value: exp.refugio,
                onChanged: (v) => exp.refugio = v,
              ),
            ),
            AppTextField(
              label: 'Apartamento / cubículo',
              required: true,
              value: c['apto'] ?? '',
              hint: 'Ej: A01-12',
              onChanged: (v) {
                c['apto'] = v.toUpperCase();
                exp.ubicacionInterna = v.toUpperCase();
              },
            ),
            AppTextField(
              label: 'Nº de familia en el censo',
              value: c['nro_familia'] ?? '',
              keyboard: TextInputType.number,
              onChanged: (v) => c['nro_familia'] = v,
            ),
            AppTextField(
              label: 'Campamento de procedencia',
              value: c['campamento'] ?? '',
              hint: 'Ej: UE JESÚS ENRIQUE LOSSADA',
              onChanged: (v) => c['campamento'] = v.toUpperCase(),
            ),
          ],
        ),
        SectionCard(
          title: 'Procedencia',
          subtitle: 'De dónde viene la familia',
          icon: Icons.place_outlined,
          children: [
            AppDropdown(
              label: 'Estado de procedencia',
              required: true,
              value: (c['estado_procedencia'] ?? '').toString().isEmpty
                  ? null
                  : c['estado_procedencia'],
              items: Catalogos.estadosVE,
              onChanged: (v) {
                c['estado_procedencia'] = v;
                onChanged();
              },
            ),
            AppTextField(
              label: 'Parroquia de procedencia',
              value: c['parroquia_procedencia'] ?? '',
              onChanged: (v) => c['parroquia_procedencia'] = v.toUpperCase(),
            ),
          ],
        ),
        SectionCard(
          title: 'Vivienda antes del terremoto',
          subtitle: 'Tenencia e inspección oficial',
          icon: Icons.home_outlined,
          children: [
            AppDropdown(
              label: 'Condición de la vivienda',
              required: true,
              value: (c['condicion_vivienda'] ?? '').toString().isEmpty
                  ? null
                  : c['condicion_vivienda'],
              items: Catalogos.condicionVivienda,
              onChanged: (v) {
                c['condicion_vivienda'] = v;
                onChanged();
              },
            ),
            AppDropdown(
              label: 'Color de la inspección',
              value: (c['color_inspeccion'] ?? '').toString().isEmpty
                  ? null
                  : c['color_inspeccion'],
              items: Catalogos.coloresInspeccion,
              onChanged: (v) {
                c['color_inspeccion'] = v;
                onChanged();
              },
            ),
          ],
        ),
        SectionCard(
          title: 'Vehículo y carnet de la patria',
          subtitle: 'Datos complementarios del censo',
          icon: Icons.directions_car_outlined,
          children: [
            TriChoice(
              label: '¿Posee vehículo?',
              value: c['posee_vehiculo'],
              onChanged: (v) {
                c['posee_vehiculo'] = v;
                onChanged();
              },
            ),
            Conditional(
              show: c['posee_vehiculo'] == 'si',
              child: Column(
                children: [
                  AppTextField(
                    label: 'Placa',
                    value: c['placa'] ?? '',
                    onChanged: (v) => c['placa'] = v.toUpperCase(),
                  ),
                  AppTextField(
                    label: 'Modelo',
                    value: c['modelo'] ?? '',
                    onChanged: (v) => c['modelo'] = v.toUpperCase(),
                  ),
                ],
              ),
            ),
            AppTextField(
              label: 'Código del carnet de la patria',
              value: c['carnet_codigo'] ?? '',
              keyboard: TextInputType.number,
              onChanged: (v) => c['carnet_codigo'] = v,
            ),
            AppTextField(
              label: 'Serial del carnet de la patria',
              value: c['carnet_serial'] ?? '',
              keyboard: TextInputType.number,
              onChanged: (v) => c['carnet_serial'] = v,
            ),
          ],
        ),
      ],
    );
  }
}

// PASO 2 · Jefe/a de familia (una fila del Excel)
class CensoPaso2Jefe extends StatelessWidget {
  final Expediente exp;
  final VoidCallback onChanged;
  const CensoPaso2Jefe({super.key, required this.exp, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _pad,
      children: [
        const _Aviso(
          icono: Icons.person_pin_circle_outlined,
          texto: 'Los datos de esta persona identifican a la familia en el '
              'censo y en las búsquedas.',
        ),
        PersonaForm(p: exp.responsable, onChanged: onChanged, esJefe: true),
      ],
    );
  }
}

// PASO 3 · Integrantes del grupo familiar
class CensoPaso3Integrantes extends StatelessWidget {
  final Expediente exp;
  final VoidCallback onChanged;
  const CensoPaso3Integrantes(
      {super.key, required this.exp, required this.onChanged});

  Future<void> _editar(BuildContext context, int? i) async {
    final actual = i == null
        ? <String, dynamic>{'dieta': 'no', 'condicion_salud': 'SANO',
            'tipo_sangre': 'NO CONOCE', 'parentesco': 'Hijo/a'}
        : Map<String, dynamic>.from(exp.acompanantes[i].toJson());

    final r = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _IntegranteSheet(datos: actual, nuevo: i == null),
    );
    if (r == null) return;

    final a = Acompanante.fromJson(r);
    if (i == null) {
      exp.acompanantes.add(a);
    } else {
      exp.acompanantes[i] = a;
    }
    exp.totalPersonas = exp.acompanantes.length + 1;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _pad,
      children: [
        _Aviso(
          icono: Icons.groups_outlined,
          texto: 'La familia tiene ${exp.totalPersonas} persona(s): '
              'el jefe/a más ${exp.acompanantes.length} integrante(s).',
        ),
        const SizedBox(height: 4),
        if (exp.acompanantes.isEmpty)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: const Center(
              child: Text('El jefe/a de familia ingresa solo.\n'
                  'Agregue integrantes si aplica.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.gray)),
            ),
          ),
        ...exp.acompanantes.asMap().entries.map((e) {
          final a = e.value;
          final etiquetas = [
            a.parentesco,
            if (a.condicionSalud.isNotEmpty && a.condicionSalud != 'SANO')
              a.condicionSalud,
            if (a.brazalete.isNotEmpty) 'Braz. ${a.brazalete}',
          ];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                onTap: () => _editar(context, e.key),
                leading: CircleAvatar(
                  backgroundColor: AppColors.blueSoft,
                  child: Text('${a.edadHoy ?? '—'}',
                      style: const TextStyle(
                          color: AppColors.blueDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
                title: Text('${a.nombres} ${a.apellidos}'.trim(),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(etiquetas.join(' · '),
                    style: const TextStyle(fontSize: 12.5)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.danger, size: 20),
                  onPressed: () {
                    exp.acompanantes.removeAt(e.key);
                    exp.totalPersonas = exp.acompanantes.length + 1;
                    onChanged();
                  },
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () => _editar(context, null),
          icon: const Icon(Icons.person_add_alt, size: 18),
          label: const Text('Agregar integrante'),
        ),
      ],
    );
  }
}

class _IntegranteSheet extends StatefulWidget {
  final Map<String, dynamic> datos;
  final bool nuevo;
  const _IntegranteSheet({required this.datos, required this.nuevo});

  @override
  State<_IntegranteSheet> createState() => _IntegranteSheetState();
}

class _IntegranteSheetState extends State<_IntegranteSheet> {
  late Map<String, dynamic> p = Map<String, dynamic>.from(widget.datos);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.96,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                  widget.nuevo ? 'Nuevo integrante' : 'Editar integrante',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 17)),
            ),
            const SizedBox(height: 8),
            PersonaForm(p: p, onChanged: () => setState(() {})),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                onPressed: () {
                  final err = validarPersona(p);
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(err),
                        backgroundColor: AppColors.danger));
                    return;
                  }
                  Navigator.pop(context, p);
                },
                child: const Text('Guardar integrante'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PASO 4 · Foto familiar y cierre
class CensoPaso4Cierre extends StatelessWidget {
  final Expediente exp;
  final VoidCallback onChanged;
  const CensoPaso4Cierre(
      {super.key, required this.exp, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = exp.censo;
    final r = exp.responsable;
    final personas = exp.acompanantes.length + 1;

    // Alertas del expediente: azul = atención requerida (niños, mayores,
    // discapacidad, condición médica); ámbar = falta cargar una foto.
    final alertas = exp.alertas;

    return ListView(
      padding: _pad,
      children: [
        SectionCard(
          title: 'Foto del grupo familiar',
          subtitle: 'Se ve al abrir el expediente',
          icon: Icons.photo_camera_outlined,
          children: [
            if ((c['foto_familia'] ?? '') != '')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    base64Decode(c['foto_familia']),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: () async {
                final b64 = await pickImageB64(context,
                    maxWidth: 1280, title: 'Foto del grupo familiar');
                if (b64 == null) return;
                c['foto_familia'] = b64;
                onChanged();
              },
              icon: const Icon(Icons.groups_outlined, size: 18),
              label: Text((c['foto_familia'] ?? '') == ''
                  ? 'Tomar foto de la familia'
                  : 'Reemplazar foto'),
            ),
          ],
        ),
        SectionCard(
          title: 'Clasificación',
          subtitle: 'Cómo entra el expediente al sistema',
          icon: Icons.flag_outlined,
          children: [
            AppDropdown(
              label: 'Estatus del expediente',
              required: true,
              value: exp.estatus,
              // 'Borrador' no se elige a mano: lo pone el botón
              // "Guardar borrador" y se quita al registrar en firme.
              items: Catalogos.estatus
                  .where((e) => e != Catalogos.estatusBorrador)
                  .toList(),
              onChanged: (v) {
                exp.estatus = v ?? exp.estatus;
                onChanged();
              },
            ),
            AppDropdown(
              label: 'Prioridad de atención',
              required: true,
              value: exp.prioridad,
              items: Catalogos.prioridades,
              onChanged: (v) {
                exp.prioridad = v ?? 'Normal';
                onChanged();
              },
            ),
            AppTextField(
              label: 'Observaciones del censo',
              value: c['observaciones'] ?? '',
              maxLines: 3,
              onChanged: (v) => c['observaciones'] = v,
            ),
          ],
        ),
        SectionCard(
          title: 'Resumen',
          subtitle: 'Revise antes de guardar',
          icon: Icons.fact_check_outlined,
          children: [
            _Fila('Cubículo', c['apto'] ?? '—'),
            _Fila('Jefe/a de familia',
                '${r['nombres'] ?? ''} ${r['apellidos'] ?? ''}'.trim()),
            _Fila('Cédula', r['cedula'] ?? '—'),
            _Fila('Personas', '$personas'),
            _Fila('Procedencia',
                '${c['estado_procedencia'] ?? '—'} · ${c['parroquia_procedencia'] ?? ''}'),
            _Fila('Vivienda antes', c['condicion_vivienda'] ?? '—'),
            if (alertas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: alertas.map((a) => AlertaChip(a)).toList(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  final String k, v;
  const _Fila(this.k, this.v);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 128,
              child: Text(k,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.gray)),
            ),
            Expanded(
              child: Text(v.isEmpty ? '—' : v,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

class _Aviso extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _Aviso({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.blueSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icono, size: 19, color: AppColors.blueDark),
            const SizedBox(width: 10),
            Expanded(
              child: Text(texto,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.blueDark)),
            ),
          ],
        ),
      );
}
