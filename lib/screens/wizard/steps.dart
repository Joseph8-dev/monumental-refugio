import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/expediente.dart';
import '../../theme.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/signature_pad.dart';

const _pad = EdgeInsets.fromLTRB(16, 16, 16, 24);
const _gap = SizedBox(height: 14);

int? _edadDesde(String? iso) {
  final d = DateTime.tryParse(iso ?? '');
  if (d == null) return null;
  final now = DateTime.now();
  var edad = now.year - d.year;
  if (now.month < d.month || (now.month == d.month && now.day < d.day)) {
    edad--;
  }
  return edad;
}

// ─────────────────────────────────────────────────────────────
// PASO 1 · Ingreso rápido (secciones 1 y 2)
// ─────────────────────────────────────────────────────────────
class Step1Ingreso extends StatelessWidget {
  final Expediente exp;
  final List<String> refugios;
  final VoidCallback onChanged;
  const Step1Ingreso(
      {super.key,
      required this.exp,
      required this.refugios,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final r = exp.responsable;
    final esTrabajador = esSi(r['trabajador']);
    final edad = _edadDesde(r['fecha_nacimiento']);

    return ListView(
      padding: _pad,
      children: [
        SectionCard(
          title: 'Datos administrativos',
          icon: Icons.assignment_outlined,
          children: [
            AppTextField(
              label: 'Código de expediente',
              value: exp.codigo,
              onChanged: (v) => exp.codigo = v,
              hint: 'Generado automáticamente',
            ),
            AppDropdown(
              label: 'Refugio temporal asignado',
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
                hint: 'Escriba el nombre del refugio',
                onChanged: (v) => exp.refugio = v,
              ),
            ),
            AppTextField(
              label: 'Ubicación interna / área asignada',
              value: exp.ubicacionInterna,
              onChanged: (v) => exp.ubicacionInterna = v,
              hint: 'Módulo, carpa o espacio',
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
              label: 'Operador que registra',
              value: exp.operador,
              onChanged: (v) => exp.operador = v,
            ),
          ],
        ),
        _gap,
        SectionCard(
          title: 'Responsable principal',
          icon: Icons.person_outline,
          children: [
            AppTextField(
                label: 'Nombres',
                required: true,
                value: r['nombres'],
                onChanged: (v) => r['nombres'] = v),
            AppTextField(
                label: 'Apellidos',
                required: true,
                value: r['apellidos'],
                onChanged: (v) => r['apellidos'] = v),
            AppTextField(
                label: 'Cédula de identidad',
                required: true,
                value: r['cedula'],
                keyboard: TextInputType.text,
                hint: 'V-12345678',
                onChanged: (v) => r['cedula'] = v),
            DateField(
              label: 'Fecha de nacimiento',
              value: r['fecha_nacimiento'],
              onChanged: (v) {
                r['fecha_nacimiento'] = v;
                onChanged();
              },
            ),
            if (edad != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Edad calculada: $edad años',
                    style: const TextStyle(
                        color: AppColors.blueDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            AppDropdown(
                label: 'Nacionalidad',
                value: r['nacionalidad'],
                items: Catalogos.nacionalidades,
                onChanged: (v) {
                  r['nacionalidad'] = v;
                  onChanged();
                }),
            AppDropdown(
                label: 'Sexo',
                value: r['sexo'],
                items: Catalogos.sexos,
                onChanged: (v) {
                  r['sexo'] = v;
                  onChanged();
                }),
            AppTextField(
                label: 'Teléfono celular',
                required: true,
                value: r['telefono'],
                keyboard: TextInputType.phone,
                onChanged: (v) => r['telefono'] = v),
            AppTextField(
                label: 'Teléfono alternativo',
                value: r['telefono_alt'],
                keyboard: TextInputType.phone,
                onChanged: (v) => r['telefono_alt'] = v),
            AppTextField(
                label: 'Correo electrónico',
                value: r['email'],
                keyboard: TextInputType.emailAddress,
                onChanged: (v) => r['email'] = v),
          ],
        ),
        _gap,
        SectionCard(
          title: 'Vínculo laboral',
          icon: Icons.badge_outlined,
          children: [
            TriChoice(
              label: '¿Es trabajador activo de Corpoelec?',
              value: r['trabajador'],
              onChanged: (v) {
                r['trabajador'] = v;
                onChanged();
              },
            ),
            Conditional(
              show: esTrabajador,
              child: Column(children: [
                AppTextField(
                    label: 'Código de trabajador',
                    value: r['codigo_trabajador'],
                    onChanged: (v) => r['codigo_trabajador'] = v),
                AppTextField(
                    label: 'Cargo actual',
                    value: r['cargo'],
                    onChanged: (v) => r['cargo'] = v),
                AppTextField(
                    label: 'Gerencia / División / Departamento',
                    value: r['gerencia'],
                    onChanged: (v) => r['gerencia'] = v),
                AppTextField(
                    label: 'Antigüedad (años)',
                    value: r['antiguedad'],
                    keyboard: TextInputType.number,
                    onChanged: (v) => r['antiguedad'] = v),
                AppTextField(
                    label: 'Dirección de trabajo',
                    value: r['direccion_trabajo'],
                    onChanged: (v) => r['direccion_trabajo'] = v),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PASO 2 · Grupo familiar (sección 3, bloque repetible)
// ─────────────────────────────────────────────────────────────
class Step2Grupo extends StatelessWidget {
  final Expediente exp;
  final VoidCallback onChanged;
  const Step2Grupo({super.key, required this.exp, required this.onChanged});

  Future<void> _editar(BuildContext context, [int? index]) async {
    final res = await showModalBottomSheet<Acompanante>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AcompananteSheet(
          original: index == null ? null : exp.acompanantes[index]),
    );
    if (res != null) {
      if (index == null) {
        exp.acompanantes.add(res);
      } else {
        exp.acompanantes[index] = res;
      }
      exp.totalPersonas = exp.acompanantes.length + 1;
      final prioritaria = res.condiciones.isNotEmpty ||
          exp.acompanantes.any((a) => a.condiciones.isNotEmpty);
      if (prioritaria) exp.poblacionPrioritaria = 'si';
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _pad,
      children: [
        SectionCard(
          title: 'Composición del grupo',
          icon: Icons.groups_outlined,
          children: [
            AppTextField(
              label: 'Cantidad total de personas que ingresan',
              required: true,
              value: '${exp.totalPersonas}',
              keyboard: TextInputType.number,
              onChanged: (v) => exp.totalPersonas = int.tryParse(v) ?? 1,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Acompañantes registrados: ${exp.cantidadAcompanantes}',
                style: const TextStyle(
                    color: AppColors.blueDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
            TriChoice(
              label:
                  '¿Viene con niños, adultos mayores, embarazadas o personas con discapacidad?',
              value: exp.poblacionPrioritaria,
              onChanged: (v) {
                exp.poblacionPrioritaria = v;
                onChanged();
              },
            ),
          ],
        ),
        _gap,
        Row(
          children: [
            const Expanded(
              child: Text('Acompañantes',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _editar(context),
              icon: const Icon(Icons.person_add_alt, size: 18),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (exp.acompanantes.isEmpty)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: const Center(
              child: Text('El responsable ingresa solo.\nAgrega acompañantes si aplica.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.gray)),
            ),
          ),
        ...exp.acompanantes.asMap().entries.map((e) {
          final a = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                onTap: () => _editar(context, e.key),
                leading: CircleAvatar(
                  backgroundColor: AppColors.blueSoft,
                  child: Text('${a.edad ?? '—'}',
                      style: const TextStyle(
                          color: AppColors.blueDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
                title: Text('${a.nombres} ${a.apellidos}'.trim(),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  [
                    a.parentesco,
                    if (a.condicionSalud.isNotEmpty &&
                        a.condicionSalud != 'SANO')
                      a.condicionSalud,
                    ...a.condiciones,
                    if (a.brazalete.isNotEmpty) 'Braz. ${a.brazalete}',
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12.5),
                ),
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
      ],
    );
  }
}

class _AcompananteSheet extends StatefulWidget {
  final Acompanante? original;
  const _AcompananteSheet({this.original});

  @override
  State<_AcompananteSheet> createState() => _AcompananteSheetState();
}

class _AcompananteSheetState extends State<_AcompananteSheet> {
  late Acompanante a;

  @override
  void initState() {
    super.initState();
    final o = widget.original;
    a = o == null
        ? Acompanante()
        : Acompanante.fromJson(o.toJson()); // copia editable
  }

  @override
  Widget build(BuildContext context) {
    // Sugerencia, no imposición: escribirla en cada rebuild borraba la
    // edad que el operador corrigiera a mano.
    final edadAuto = _edadDesde(a.fechaNacimiento);
    if (edadAuto != null && a.edad == null) a.edad = edadAuto;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
                widget.original == null
                    ? 'Nuevo acompañante'
                    : 'Editar acompañante',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Nombres',
                required: true,
                value: a.nombres,
                onChanged: (v) => a.nombres = v),
            AppTextField(
                label: 'Apellidos',
                required: true,
                value: a.apellidos,
                onChanged: (v) => a.apellidos = v),
            AppTextField(
                label: 'Cédula (si tiene)',
                value: a.cedula,
                onChanged: (v) => a.cedula = v),
            DateField(
                label: 'Fecha de nacimiento',
                value: a.fechaNacimiento,
                onChanged: (v) => setState(() => a.fechaNacimiento = v)),
            AppTextField(
                label: 'Edad',
                required: true,
                value: a.edad?.toString() ?? '',
                keyboard: TextInputType.number,
                onChanged: (v) => a.edad = int.tryParse(v)),
            AppDropdown(
                label: 'Parentesco con el responsable',
                required: true,
                value: a.parentesco,
                items: Catalogos.parentescos,
                onChanged: (v) =>
                    setState(() => a.parentesco = v ?? 'Otro')),
            AppDropdown(
                label: 'Sexo',
                value: a.sexo.isEmpty ? null : a.sexo,
                items: Catalogos.sexos,
                onChanged: (v) => setState(() => a.sexo = v ?? '')),
            TriChoice(
              label: '¿Está en la carga familiar declarada?',
              value: a.cargaFamiliar,
              allowNs: true,
              onChanged: (v) => setState(() => a.cargaFamiliar = v),
            ),
            AppTextField(
                label: 'Teléfono (si tiene)',
                value: a.telefono,
                keyboard: TextInputType.phone,
                onChanged: (v) => a.telefono = v),
            MultiChips(
              label: 'Condición especial',
              options: Catalogos.condicionesEspeciales,
              selected: a.condiciones,
              onChanged: (v) => setState(() => a.condiciones = v),
            ),

            // ── Censo Monumental (por persona) ──
            const Divider(height: 28),
            const Text('Datos del censo',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.gray)),
            const SizedBox(height: 10),
            AppDropdown(
                label: 'Condición de salud',
                value: a.condicionSalud.isEmpty ? null : a.condicionSalud,
                items: Catalogos.condicionesSalud,
                onChanged: (v) =>
                    setState(() => a.condicionSalud = v ?? 'SANO')),
            Conditional(
              show: a.condicionSalud == 'OTRA',
              child: AppTextField(
                  label: 'Especifique la condición',
                  value: a.observaciones,
                  onChanged: (v) => a.observaciones = v),
            ),
            Row(
              children: [
                Expanded(
                  child: AppDropdown(
                      label: 'Tipo de sangre',
                      value: a.tipoSangre.isEmpty ? null : a.tipoSangre,
                      items: Catalogos.tiposSangre,
                      onChanged: (v) =>
                          setState(() => a.tipoSangre = v ?? 'NO CONOCE')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                      label: 'Brazalete',
                      value: a.brazalete,
                      onChanged: (v) => a.brazalete = v),
                ),
              ],
            ),
            AppTextField(
                label: 'Ocupación',
                value: a.ocupacion,
                onChanged: (v) => a.ocupacion = v.toUpperCase()),
            TriChoice(
              label: '¿Requiere dieta alimenticia?',
              value: a.dieta,
              onChanged: (v) => setState(() => a.dieta = v),
            ),

            // Tallas: se pliegan para no alargar el formulario.
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text('Tallas y dotación',
                    style: TextStyle(fontSize: 14)),
                subtitle: Text(
                  [a.tallaCamisa, a.tallaPantalon, a.calzado]
                          .where((x) => x.isNotEmpty)
                          .isEmpty
                      ? 'Sin registrar'
                      : 'Camisa ${a.tallaCamisa} · Pantalón ${a.tallaPantalon} · Calzado ${a.calzado}',
                  style: const TextStyle(fontSize: 11.5),
                ),
                children: [
                  AppTextField(
                      label: 'Estatura (m)',
                      value: a.estatura,
                      keyboard: TextInputType.number,
                      onChanged: (v) => a.estatura = v),
                  Row(
                    children: [
                      Expanded(
                        child: AppDropdown(
                            label: 'Talla camisa',
                            value: a.tallaCamisa.isEmpty
                                ? null
                                : a.tallaCamisa,
                            items: Catalogos.tallas,
                            onChanged: (v) =>
                                setState(() => a.tallaCamisa = v ?? '')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppDropdown(
                            label: 'Talla pantalón',
                            value: a.tallaPantalon.isEmpty
                                ? null
                                : a.tallaPantalon,
                            items: Catalogos.tallas,
                            onChanged: (v) =>
                                setState(() => a.tallaPantalon = v ?? '')),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                            label: 'Calzado',
                            value: a.calzado,
                            keyboard: TextInputType.number,
                            onChanged: (v) => a.calzado = v),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppDropdown(
                            label: 'Gorra',
                            value: a.gorra.isEmpty ? null : a.gorra,
                            items: Catalogos.tallasGorra,
                            onChanged: (v) =>
                                setState(() => a.gorra = v ?? '')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            CheckTile(
              label: 'Documento de identidad cargado',
              value: a.documentoCargado,
              onChanged: (v) {
                if (v && a.documentoImagen == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Adjunte la foto del documento para marcarlo como cargado.'),
                      backgroundColor: AppColors.warning));
                  return;
                }
                setState(() => a.documentoCargado = v);
              },
            ),
            Row(
              children: [
                if (a.documentoImagen != null) ...[
                  B64Thumb(
                    b64: a.documentoImagen!,
                    onRemove: () => setState(() {
                      a.documentoImagen = null;
                      a.documentoCargado = false;
                    }),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final b64 = await pickImageB64(context,
                          maxWidth: 900,
                          title: 'Documento de identidad');
                      if (b64 == null) return;
                      setState(() {
                        a.documentoImagen = b64;
                        a.documentoCargado = true;
                      });
                    },
                    icon: const Icon(Icons.add_a_photo_outlined, size: 17),
                    label: Text(a.documentoImagen == null
                        ? 'Adjuntar foto del documento'
                        : 'Reemplazar foto'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                if (a.nombres.trim().isEmpty || a.apellidos.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Nombre y apellido son obligatorios'),
                      backgroundColor: AppColors.danger));
                  return;
                }
                if (a.edad == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'La edad es obligatoria (fecha de nacimiento o edad manual)'),
                      backgroundColor: AppColors.danger));
                  return;
                }
                Navigator.pop(context, a);
              },
              child: const Text('Guardar acompañante'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PASO 3 · Salud y atención prioritaria (sección 4)
// ─────────────────────────────────────────────────────────────
class Step3Salud extends StatelessWidget {
  final Expediente exp;
  final VoidCallback onChanged;
  const Step3Salud({super.key, required this.exp, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = exp.salud;
    return ListView(
      padding: _pad,
      children: [
        SectionCard(
          title: 'Condición médica',
          icon: Icons.medical_services_outlined,
          children: [
            TriChoice(
                label: '¿Tiene alguna enfermedad o patología?',
                value: s['patologia'],
                onChanged: (v) {
                  s['patologia'] = v;
                  onChanged();
                }),
            Conditional(
              show: esSi(s['patologia']),
              child: AppTextField(
                  label: 'Descripción de patología',
                  value: s['patologia_desc'],
                  maxLines: 2,
                  onChanged: (v) => s['patologia_desc'] = v),
            ),
            TriChoice(
                label: '¿Toma medicamentos?',
                value: s['medicamentos'],
                onChanged: (v) {
                  s['medicamentos'] = v;
                  onChanged();
                }),
            Conditional(
              show: esSi(s['medicamentos']),
              child: AppTextField(
                  label: 'Medicamentos requeridos',
                  value: s['medicamentos_desc'],
                  maxLines: 2,
                  onChanged: (v) => s['medicamentos_desc'] = v),
            ),
            TriChoice(
                label: '¿Tiene alergias?',
                value: s['alergias'],
                onChanged: (v) {
                  s['alergias'] = v;
                  onChanged();
                }),
            Conditional(
              show: esSi(s['alergias']),
              child: AppTextField(
                  label: '¿A qué es alérgico?',
                  value: s['alergias_desc'],
                  onChanged: (v) => s['alergias_desc'] = v),
            ),
            AppDropdown(
                label: 'Grupo sanguíneo',
                value: s['grupo_sanguineo'],
                items: Catalogos.gruposSanguineos,
                onChanged: (v) {
                  s['grupo_sanguineo'] = v;
                  onChanged();
                }),
            AppDropdown(
                label: 'Factor RH',
                value: s['factor_rh'],
                items: Catalogos.factoresRh,
                onChanged: (v) {
                  s['factor_rh'] = v;
                  onChanged();
                }),
          ],
        ),
        _gap,
        SectionCard(
          title: 'Discapacidad y equipo médico',
          icon: Icons.accessible_outlined,
          children: [
            TriChoice(
                label: '¿Tiene discapacidad?',
                value: s['discapacidad'],
                onChanged: (v) {
                  s['discapacidad'] = v;
                  onChanged();
                }),
            Conditional(
              show: esSi(s['discapacidad']),
              child: AppDropdown(
                  label: 'Tipo de discapacidad',
                  value: s['discapacidad_tipo'],
                  items: Catalogos.tiposDiscapacidad,
                  onChanged: (v) {
                    s['discapacidad_tipo'] = v;
                    onChanged();
                  }),
            ),
            TriChoice(
                label: '¿Requiere equipo médico especial?',
                value: s['equipo_medico'],
                onChanged: (v) {
                  s['equipo_medico'] = v;
                  onChanged();
                }),
            Conditional(
              show: esSi(s['equipo_medico']),
              child: AppTextField(
                  label: 'Equipo médico requerido',
                  value: s['equipo_medico_desc'],
                  onChanged: (v) => s['equipo_medico_desc'] = v),
            ),
            TriChoice(
                label: '¿Requiere dieta especial?',
                value: s['dieta'],
                onChanged: (v) {
                  s['dieta'] = v;
                  onChanged();
                }),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PASO 4 · Vivienda afectada y daño (secciones 5 y 6)
// ─────────────────────────────────────────────────────────────
class Step4Vivienda extends StatelessWidget {
  final Expediente exp;
  final VoidCallback onChanged;
  const Step4Vivienda(
      {super.key, required this.exp, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final v = exp.vivienda;
    final d = exp.dano;
    return ListView(
      padding: _pad,
      children: [
        SectionCard(
          title: 'Vivienda afectada',
          icon: Icons.home_outlined,
          children: [
            AppTextField(
                label: 'Dirección completa',
                required: true,
                value: v['direccion'],
                maxLines: 2,
                onChanged: (x) => v['direccion'] = x),
            AppDropdown(
                label: 'Estado',
                required: true,
                value: v['estado'],
                items: Catalogos.estadosVE,
                onChanged: (x) {
                  v['estado'] = x;
                  onChanged();
                }),
            AppTextField(
                label: 'Municipio',
                required: true,
                value: v['municipio'],
                onChanged: (x) => v['municipio'] = x),
            AppTextField(
                label: 'Parroquia / sector',
                required: true,
                value: v['parroquia'],
                onChanged: (x) => v['parroquia'] = x),
            AppTextField(
                label: 'Punto de referencia',
                value: v['referencia'],
                onChanged: (x) => v['referencia'] = x),
            TriChoice(
                label: '¿Era su residencia principal y habitual?',
                value: v['residencia_principal'],
                onChanged: (x) {
                  v['residencia_principal'] = x;
                  onChanged();
                }),
            AppDropdown(
                label: 'Condición de ocupación',
                value: v['ocupacion'],
                items: Catalogos.condicionesOcupacion,
                onChanged: (x) {
                  v['ocupacion'] = x;
                  onChanged();
                }),
            AppDropdown(
                label: 'Tipo de vivienda',
                value: v['tipo'],
                items: Catalogos.tiposVivienda,
                onChanged: (x) {
                  v['tipo'] = x;
                  onChanged();
                }),
            AppTextField(
                label: 'Número de pisos',
                value: v['pisos'],
                keyboard: TextInputType.number,
                onChanged: (x) => v['pisos'] = x),
            AppTextField(
                label: 'Material predominante de paredes',
                value: v['material_paredes'],
                hint: 'Bloque, ladrillo, bahareque…',
                onChanged: (x) => v['material_paredes'] = x),
            AppTextField(
                label: 'Material predominante de techo',
                value: v['material_techo'],
                hint: 'Platabanda, zinc, teja…',
                onChanged: (x) => v['material_techo'] = x),
            TriChoice(
                label: '¿Fue inspeccionada por autoridad oficial?',
                value: v['inspeccionada'],
                onChanged: (x) {
                  v['inspeccionada'] = x;
                  onChanged();
                }),
            Conditional(
              show: esSi(v['inspeccionada']),
              child: Column(children: [
                AppTextField(
                    label: 'Organismo que inspeccionó',
                    value: v['organismo'],
                    onChanged: (x) => v['organismo'] = x),
                AppTextField(
                    label: 'Número de acta u oficio',
                    value: v['acta'],
                    onChanged: (x) => v['acta'] = x),
                AppDropdown(
                    label: 'Dictamen de habitabilidad',
                    value: v['dictamen'],
                    items: Catalogos.dictamenes,
                    onChanged: (x) {
                      v['dictamen'] = x;
                      onChanged();
                    }),
              ]),
            ),
          ],
        ),
        _gap,
        SectionCard(
          title: 'Condición del daño',
          icon: Icons.report_problem_outlined,
          children: [
            AppDropdown(
                label: 'Daño general reportado',
                required: true,
                value: d['general'],
                items: Catalogos.danosGenerales,
                onChanged: (x) {
                  d['general'] = x;
                  onChanged();
                }),
            TriChoice(
                label: '¿Hay grietas en paredes o techos?',
                value: d['grietas'],
                onChanged: (x) {
                  d['grietas'] = x;
                  onChanged();
                }),
            Conditional(
              show: esSi(d['grietas']),
              child: AppDropdown(
                  label: 'Severidad de grietas',
                  value: d['grietas_severidad'],
                  items: Catalogos.severidades,
                  onChanged: (x) {
                    d['grietas_severidad'] = x;
                    onChanged();
                  }),
            ),
            TriChoice(
                label: '¿Columnas, vigas o estructura afectada?',
                value: d['estructura'],
                allowNs: true,
                onChanged: (x) {
                  d['estructura'] = x;
                  onChanged();
                }),
            TriChoice(
                label: '¿Hay riesgo de caída?',
                value: d['riesgo_caida'],
                allowNs: true,
                onChanged: (x) {
                  d['riesgo_caida'] = x;
                  onChanged();
                }),
            TriChoice(
                label: '¿Instalaciones eléctricas dañadas?',
                value: d['electricas'],
                allowNs: true,
                onChanged: (x) {
                  d['electricas'] = x;
                  onChanged();
                }),
            TriChoice(
                label: '¿Hay fuga de gas?',
                value: d['gas'],
                allowNs: true,
                onChanged: (x) {
                  d['gas'] = x;
                  onChanged();
                }),
            TriChoice(
                label: '¿Fuga de agua o aguas servidas?',
                value: d['agua'],
                allowNs: true,
                onChanged: (x) {
                  d['agua'] = x;
                  onChanged();
                }),
            TriChoice(
                label: '¿La entrada o salida está bloqueada?',
                value: d['bloqueada'],
                onChanged: (x) {
                  d['bloqueada'] = x;
                  onChanged();
                }),
            TriChoice(
                label: '¿Recomendaron desalojo?',
                value: d['desalojo'],
                allowNs: true,
                onChanged: (x) {
                  d['desalojo'] = x;
                  onChanged();
                }),
            AppTextField(
                label: 'Observaciones del daño',
                value: d['observaciones'],
                maxLines: 3,
                onChanged: (x) => d['observaciones'] = x),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PASO 5 · Necesidad de refugio y bienes (secciones 7 y 8)
// ─────────────────────────────────────────────────────────────
class Step5Necesidad extends StatelessWidget {
  final Expediente exp;
  final VoidCallback onChanged;
  const Step5Necesidad(
      {super.key, required this.exp, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final n = exp.necesidad;
    final b = exp.bienes;
    return ListView(
      padding: _pad,
      children: [
        SectionCard(
          title: 'Necesidad de refugio temporal',
          icon: Icons.night_shelter_outlined,
          children: [
            TriChoice(
                label: '¿La vivienda quedó inhabitable?',
                value: n['inhabitable'],
                allowNs: true,
                onChanged: (x) {
                  n['inhabitable'] = x;
                  onChanged();
                }),
            TriChoice(
                label: '¿Tiene otra opción habitacional segura?',
                value: n['alternativa'],
                onChanged: (x) {
                  n['alternativa'] = x;
                  onChanged();
                }),
            Conditional(
              show: esSi(n['alternativa']),
              child: AppTextField(
                  label: 'Lugar alternativo disponible',
                  value: n['alternativa_lugar'],
                  onChanged: (x) => n['alternativa_lugar'] = x),
            ),
            AppDropdown(
                label: 'Motivo de ingreso al refugio',
                required: true,
                value: n['motivo'],
                items: Catalogos.motivosIngreso,
                onChanged: (x) {
                  n['motivo'] = x;
                  onChanged();
                }),
            AppDropdown(
                label: 'Tiempo estimado requerido',
                value: n['tiempo'],
                items: Catalogos.tiemposEstimados,
                onChanged: (x) {
                  n['tiempo'] = x;
                  onChanged();
                }),
            const Divider(height: 24),
            CheckTile(
                label: 'Acepta que el refugio es temporal',
                value: n['acepta_temporal'] == true,
                onChanged: (x) {
                  n['acepta_temporal'] = x;
                  onChanged();
                }),
            CheckTile(
                label: 'Acepta normas de convivencia',
                value: n['acepta_normas'] == true,
                onChanged: (x) {
                  n['acepta_normas'] = x;
                  onChanged();
                }),
            CheckTile(
                label: 'Acepta acuerdo de responsabilidad compartida',
                value: n['acepta_acuerdo'] == true,
                onChanged: (x) {
                  n['acepta_acuerdo'] = x;
                  onChanged();
                }),
          ],
        ),
        _gap,
        SectionCard(
          title: 'Bienes permitidos al ingreso',
          icon: Icons.luggage_outlined,
          children: [
            AppTextField(
                label: 'Cantidad de bolsos o maletas del grupo',
                required: true,
                value: b['bolsos'],
                keyboard: TextInputType.number,
                onChanged: (x) => b['bolsos'] = x),
            TriChoice(
                label: '¿Trae documentos personales?',
                value: b['documentos'],
                onChanged: (x) {
                  b['documentos'] = x;
                  onChanged();
                }),
            TriChoice(
                label: '¿Trae medicamentos?',
                value: b['medicamentos'],
                onChanged: (x) {
                  b['medicamentos'] = x;
                  onChanged();
                }),
            TriChoice(
                label: '¿Trae dispositivos móviles?',
                value: b['dispositivos'],
                onChanged: (x) {
                  b['dispositivos'] = x;
                  onChanged();
                }),
            TriChoice(
                label: '¿Trae artículos de aseo?',
                value: b['aseo'],
                onChanged: (x) {
                  b['aseo'] = x;
                  onChanged();
                }),
            TriChoice(
                label: '¿Trae equipo médico autorizado?',
                value: b['equipo_medico'],
                onChanged: (x) {
                  b['equipo_medico'] = x;
                  onChanged();
                }),
            Conditional(
              show: esSi(b['equipo_medico']),
              child: AppTextField(
                  label: 'Descripción del equipo médico',
                  value: b['equipo_medico_desc'],
                  onChanged: (x) => b['equipo_medico_desc'] = x),
            ),
            TriChoice(
                label: '¿Trae objetos no permitidos?',
                value: b['no_permitidos'],
                onChanged: (x) {
                  b['no_permitidos'] = x;
                  onChanged();
                }),
            Conditional(
              show: esSi(b['no_permitidos']),
              child: AppTextField(
                  label: 'Observación de objetos retenidos',
                  value: b['no_permitidos_obs'],
                  maxLines: 2,
                  onChanged: (x) => b['no_permitidos_obs'] = x),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PASO 6 · Ayuda social, artículos y documentos (secciones 9–11)
// ─────────────────────────────────────────────────────────────
class Step6Ayuda extends StatelessWidget {
  final Expediente exp;
  final VoidCallback onChanged;
  const Step6Ayuda({super.key, required this.exp, required this.onChanged});

  Future<void> _editarArticulo(BuildContext context, [int? index]) async {
    final res = await showModalBottomSheet<ArticuloDanado>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ArticuloSheet(
          original: index == null ? null : exp.articulos[index]),
    );
    if (res != null) {
      if (index == null) {
        exp.articulos.add(res);
      } else {
        exp.articulos[index] = res;
      }
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final y = exp.ayuda;
    final quiere = esSi(y['solicita']);
    final tipos = (y['tipos'] as List?)?.cast<String>() ?? <String>[];

    return ListView(
      padding: _pad,
      children: [
        SectionCard(
          title: 'Solicitud de ayuda social o económica',
          icon: Icons.volunteer_activism_outlined,
          children: [
            TriChoice(
                label: '¿Desea solicitar ayuda social o económica?',
                value: y['solicita'],
                onChanged: (x) {
                  y['solicita'] = x;
                  onChanged();
                }),
            Conditional(
              show: quiere,
              child: Column(children: [
                MultiChips(
                  label: 'Tipo de ayuda solicitada',
                  options: Catalogos.tiposAyuda,
                  selected: tipos,
                  onChanged: (v) {
                    y['tipos'] = v;
                    onChanged();
                  },
                ),
                AppTextField(
                    label: 'Monto estimado de necesidad',
                    value: y['monto_estimado'],
                    keyboard: TextInputType.number,
                    onChanged: (x) => y['monto_estimado'] = x),
                TriChoice(
                    label: '¿Tiene presupuestos o facturas?',
                    value: y['facturas'],
                    onChanged: (x) {
                      y['facturas'] = x;
                      onChanged();
                    }),
              ]),
            ),
            TriChoice(
                label: '¿Ha recibido otra ayuda por este evento?',
                value: y['ayuda_previa'],
                onChanged: (x) {
                  y['ayuda_previa'] = x;
                  onChanged();
                }),
            Conditional(
              show: esSi(y['ayuda_previa']),
              child: Column(children: [
                AppTextField(
                    label: 'Institución que otorgó ayuda',
                    value: y['institucion'],
                    onChanged: (x) => y['institucion'] = x),
                AppTextField(
                    label: 'Monto recibido',
                    value: y['monto_recibido'],
                    keyboard: TextInputType.number,
                    onChanged: (x) => y['monto_recibido'] = x),
              ]),
            ),
          ],
        ),
        _gap,
        Row(
          children: [
            const Expanded(
              child: Text('Artículos perdidos o dañados',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _editarArticulo(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...exp.articulos.asMap().entries.map((e) {
          final a = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                onTap: () => _editarArticulo(context, e.key),
                leading: a.fotoBase64 == null
                    ? const CircleAvatar(
                        backgroundColor: AppColors.blueSoft,
                        child: Icon(Icons.chair_outlined,
                            color: AppColors.blueDark, size: 18))
                    : CircleAvatar(
                        backgroundImage:
                            MemoryImage(base64Decode(a.fotoBase64!))),
                title: Text('${a.cantidad} × ${a.descripcion}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${a.estado}${a.valorUsd != null ? ' · ${a.valorUsd!.toStringAsFixed(0)} USD' : ''}',
                    style: const TextStyle(fontSize: 12.5)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.danger, size: 20),
                  onPressed: () {
                    exp.articulos.removeAt(e.key);
                    onChanged();
                  },
                ),
              ),
            ),
          );
        }),
        _gap,
        SectionCard(
          title: 'Documentos anexos del expediente',
          icon: Icons.folder_open_outlined,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Los documentos pendientes no bloquean el ingreso humanitario.',
                style: TextStyle(fontSize: 12.5, color: AppColors.gray),
              ),
            ),
            ...exp.documentos.keys.map((doc) {
              final cargado = exp.documentos[doc] == 'cargado';
              final imgs = exp.documentosImagenes[doc] ?? <String>[];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(doc,
                              style: const TextStyle(fontSize: 13.5)),
                        ),
                        Text(cargado ? 'Cargado' : 'Pendiente',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: cargado
                                    ? AppColors.ok
                                    : AppColors.warning)),
                        Switch(
                          value: cargado,
                          activeColor: AppColors.blue,
                          onChanged: (v) {
                            if (v && imgs.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Adjunte al menos un archivo para marcarlo como cargado.'),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                              return;
                            }
                            exp.documentos[doc] =
                                v ? 'cargado' : 'pendiente';
                            onChanged();
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: imgs.isEmpty
                              ? const Text('Sin archivos adjuntos',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.grayLight))
                              : SizedBox(
                                  height: 70,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: imgs.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 10),
                                    itemBuilder: (_, i) => Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: B64Thumb(
                                        b64: imgs[i],
                                        onRemove: () {
                                          imgs.removeAt(i);
                                          if (imgs.isEmpty) {
                                            exp.documentosImagenes
                                                .remove(doc);
                                            exp.documentos[doc] =
                                                'pendiente';
                                          }
                                          onChanged();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final b64 = await pickImageB64(context,
                                title: doc);
                            if (b64 == null) return;
                            exp.documentosImagenes
                                .putIfAbsent(doc, () => <String>[])
                                .add(b64);
                            exp.documentos[doc] = 'cargado';
                            onChanged();
                          },
                          icon: const Icon(Icons.add_a_photo_outlined,
                              size: 17),
                          label: const Text('Adjuntar',
                              style: TextStyle(fontSize: 12.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _ArticuloSheet extends StatefulWidget {
  final ArticuloDanado? original;
  const _ArticuloSheet({this.original});

  @override
  State<_ArticuloSheet> createState() => _ArticuloSheetState();
}

class _ArticuloSheetState extends State<_ArticuloSheet> {
  late ArticuloDanado a;

  @override
  void initState() {
    super.initState();
    final o = widget.original;
    a = o == null ? ArticuloDanado() : ArticuloDanado.fromJson(o.toJson());
  }

  Future<void> _foto() async {
    final b64 =
        await pickImageB64(context, title: 'Foto del artículo');
    if (b64 != null && mounted) setState(() => a.fotoBase64 = b64);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.original == null ? 'Nuevo artículo' : 'Editar artículo',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Cantidad',
                required: true,
                value: '${a.cantidad}',
                keyboard: TextInputType.number,
                onChanged: (v) => a.cantidad = int.tryParse(v) ?? 1),
            AppTextField(
                label: 'Descripción del artículo',
                required: true,
                value: a.descripcion,
                onChanged: (v) => a.descripcion = v),
            AppDropdown(
                label: 'Estado',
                required: true,
                value: a.estado,
                items: Catalogos.estadosArticulo,
                onChanged: (v) => setState(() => a.estado = v ?? 'Dañado')),
            AppTextField(
                label: 'Valor estimado (USD)',
                value: a.valorUsd?.toString() ?? '',
                keyboard: TextInputType.number,
                onChanged: (v) => a.valorUsd = double.tryParse(v)),
            AppTextField(
                label: 'Observaciones',
                value: a.observaciones,
                maxLines: 2,
                onChanged: (v) => a.observaciones = v),
            OutlinedButton.icon(
              onPressed: _foto,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(a.fotoBase64 == null
                  ? 'Tomar foto del artículo'
                  : 'Foto capturada · tocar para reemplazar'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                if (a.descripcion.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('La descripción es obligatoria'),
                      backgroundColor: AppColors.danger));
                  return;
                }
                Navigator.pop(context, a);
              },
              child: const Text('Guardar artículo'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PASO 7 · Aceptaciones, firma y evaluación (secciones 12 y 13)
// ─────────────────────────────────────────────────────────────
class Step7Firma extends StatelessWidget {
  final Expediente exp;
  final VoidCallback onChanged;
  const Step7Firma({super.key, required this.exp, required this.onChanged});

  Future<void> _firmar(BuildContext context, String key, String title) async {
    // El instrumento acepta firma digital dibujada o capturada de papel.
    final modo = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: const Icon(Icons.draw_outlined, color: AppColors.blue),
              title: const Text('Dibujar firma en pantalla'),
              onTap: () => Navigator.pop(ctx, 'dibujar'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.blue),
              title: const Text('Foto de la firma en papel'),
              onTap: () => Navigator.pop(ctx, 'foto'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (modo == null) return;

    String? b64;
    if (modo == 'dibujar') {
      if (!context.mounted) return;
      b64 = await showSignatureSheet(context, title: title);
    } else {
      if (!context.mounted) return;
      b64 = await pickImageB64(context, maxWidth: 900, title: title);
    }
    if (b64 != null) {
      exp.aceptaciones[key] = b64;
      onChanged();
    }
  }

  Future<void> _fotoResponsable(BuildContext context) async {
    final b64 = await pickImageB64(context,
        maxWidth: 900, title: 'Foto del responsable');
    if (b64 != null) {
      exp.aceptaciones['foto_responsable'] = b64;
      onChanged();
    }
  }

  Future<void> _huella(BuildContext context) async {
    final b64 = await pickImageB64(context,
        maxWidth: 700, title: 'Huella dactilar (opcional)');
    if (b64 != null) {
      exp.aceptaciones['huella'] = b64;
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = exp.aceptaciones;
    final ev = exp.evaluacion;
    final alertas = exp.alertas;

    return ListView(
      padding: _pad,
      children: [
        if (alertas.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDBA74)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Text('Alertas del expediente',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning)),
                ]),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: alertas.map((x) => AlertaChip(x)).toList(),
                ),
              ],
            ),
          ),
        SectionCard(
          title: 'Declaraciones',
          icon: Icons.fact_check_outlined,
          children: [
            CheckTile(
                label: 'Declaro que la información suministrada es verdadera',
                value: a['decl_verdad'] == true,
                onChanged: (v) {
                  a['decl_verdad'] = v;
                  onChanged();
                }),
            CheckTile(
                label:
                    'Declaro que mi vivienda fue afectada por el evento sísmico',
                value: a['decl_afectada'] == true,
                onChanged: (v) {
                  a['decl_afectada'] = v;
                  onChanged();
                }),
            CheckTile(
                label:
                    'Declaro que la vivienda afectada era mi residencia principal',
                value: a['decl_principal'] == true,
                onChanged: (v) {
                  a['decl_principal'] = v;
                  onChanged();
                }),
            CheckTile(
                label: 'Declaro si he recibido o no otra ayuda',
                value: a['decl_ayuda'] == true,
                onChanged: (v) {
                  a['decl_ayuda'] = v;
                  onChanged();
                }),
            CheckTile(
                label:
                    'Autorizo el uso de mis datos para la gestión del refugio y ayudas',
                value: a['autoriza_datos'] == true,
                onChanged: (v) {
                  a['autoriza_datos'] = v;
                  onChanged();
                }),
          ],
        ),
        _gap,
        SectionCard(
          title: 'Firmas y foto',
          icon: Icons.draw_outlined,
          children: [
            SignaturePreview(
              base64Png: a['firma_responsable'],
              label: 'Firma del responsable',
              onTap: () => _firmar(
                  context, 'firma_responsable', 'Firma del responsable'),
            ),
            SignaturePreview(
              base64Png: a['firma_operador'],
              label: 'Firma del operador receptor',
              onTap: () =>
                  _firmar(context, 'firma_operador', 'Firma del operador'),
            ),
            OutlinedButton.icon(
              onPressed: () => _fotoResponsable(context),
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text((a['foto_responsable'] ?? '') == ''
                  ? 'Foto del responsable (recomendado)'
                  : 'Foto capturada · tocar para reemplazar'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _huella(context),
              icon: const Icon(Icons.fingerprint, size: 18),
              label: Text((a['huella'] ?? '') == ''
                  ? 'Huella dactilar (opcional)'
                  : 'Huella capturada · tocar para reemplazar'),
            ),
          ],
        ),
        _gap,
        SectionCard(
          title: 'Evaluación rápida de ingreso',
          icon: Icons.rule_outlined,
          children: [
            TriChoice(
                label: '¿Expediente mínimo completo para ingreso?',
                value: ev['completo'],
                onChanged: (v) {
                  ev['completo'] = v;
                  onChanged();
                }),
            TriChoice(
                label: '¿Requiere atención médica inmediata?',
                value: ev['medica'],
                onChanged: (v) {
                  ev['medica'] = v;
                  onChanged();
                }),
            TriChoice(
                label: '¿Requiere evaluación psicosocial?',
                value: ev['psicosocial'],
                onChanged: (v) {
                  ev['psicosocial'] = v;
                  onChanged();
                }),
            TriChoice(
                label: '¿Requiere cama especial o ubicación prioritaria?',
                value: ev['cama_especial'],
                onChanged: (v) {
                  ev['cama_especial'] = v;
                  onChanged();
                }),
            TriChoice(
                label: '¿Grupo con niños o adultos mayores?',
                value: ev['ninos_mayores'],
                onChanged: (v) {
                  ev['ninos_mayores'] = v;
                  onChanged();
                }),
            TriChoice(
                label: '¿Debe escalarse a coordinación?',
                value: ev['escalar'],
                onChanged: (v) {
                  ev['escalar'] = v;
                  onChanged();
                }),
            AppTextField(
                label: 'Observaciones del operador',
                value: ev['observaciones'],
                maxLines: 3,
                onChanged: (v) => ev['observaciones'] = v),
            AppDropdown(
                label: 'Decisión inicial',
                required: true,
                value: ev['decision'],
                items: Catalogos.decisionesIniciales,
                onChanged: (v) {
                  ev['decision'] = v;
                  onChanged();
                }),
            AppDropdown(
                label: 'Estatus del expediente',
                required: true,
                value: exp.estatus,
                items: Catalogos.estatus,
                onChanged: (v) {
                  exp.estatus = v ?? exp.estatus;
                  onChanged();
                }),
          ],
        ),
      ],
    );
  }
}
