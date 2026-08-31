import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/expediente.dart';
import '../../theme.dart';
import '../../widgets/form_widgets.dart';

// ─────────────────────────────────────────────────────────────
// PASO CENSO · Campamento Monumental
// Campos tomados del Excel oficial (FAMILIAS CAMPAMENTO PERMANENTE
// ESTADIUM MONUMENTAL): apartamento/cubículo, campamento de procedencia,
// brazalete, tallas, vehículo, carnet de la patria y foto familiar.
// ─────────────────────────────────────────────────────────────
class StepCenso extends StatelessWidget {
  final Expediente exp;
  final VoidCallback onChanged;
  const StepCenso({super.key, required this.exp, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = exp.censo;
    final r = exp.responsable;
    final tieneVehiculo = c['posee_vehiculo'] == 'si';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        SectionCard(
          title: 'Ubicación en el refugio',
          icon: Icons.apartment_outlined,
          children: [
            AppTextField(
              label: 'Apartamento / cubículo',
              required: true,
              value: c['apto'] ?? '',
              hint: 'Ej: A01-12',
              onChanged: (v) => c['apto'] = v.toUpperCase(),
            ),
            AppTextField(
              label: 'Nº de familia (censo)',
              value: c['nro_familia'] ?? '',
              hint: 'Número correlativo del listado oficial',
              onChanged: (v) => c['nro_familia'] = v,
            ),
            AppTextField(
              label: 'Campamento de procedencia',
              value: c['campamento'] ?? '',
              hint: 'Ej: UE JESÚS ENRIQUE LOSSADA',
              onChanged: (v) => c['campamento'] = v.toUpperCase(),
            ),
            AppTextField(
              label: 'Brazalete del jefe/a de familia',
              value: c['brazalete'] ?? '',
              hint: 'Código impreso en el brazalete',
              onChanged: (v) => c['brazalete'] = v,
            ),
          ],
        ),
        SectionCard(
          title: 'Procedencia',
          icon: Icons.place_outlined,
          children: [
            AppDropdown(
              label: 'Estado de procedencia',
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
            AppDropdown(
              label: 'Condición de la vivienda antes del terremoto',
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
          title: 'Salud del jefe/a de familia',
          icon: Icons.favorite_outline,
          children: [
            AppDropdown(
              label: 'Condición de salud',
              required: true,
              value: (c['condicion_salud'] ?? '').toString().isEmpty
                  ? null
                  : c['condicion_salud'],
              items: Catalogos.condicionesSalud,
              onChanged: (v) {
                c['condicion_salud'] = v;
                onChanged();
              },
            ),
            AppDropdown(
              label: 'Tipo de sangre',
              value: (c['tipo_sangre'] ?? '').toString().isEmpty
                  ? null
                  : c['tipo_sangre'],
              items: Catalogos.tiposSangre,
              onChanged: (v) {
                c['tipo_sangre'] = v;
                onChanged();
              },
            ),
            TriChoice(
              label: '¿Requiere dieta alimenticia?',
              value: c['dieta'],
              onChanged: (v) {
                c['dieta'] = v;
                onChanged();
              },
            ),
            Conditional(
              show: c['dieta'] == 'si',
              child: AppTextField(
                label: 'Detalle de la dieta',
                value: c['dieta_desc'] ?? '',
                onChanged: (v) => c['dieta_desc'] = v,
              ),
            ),
          ],
        ),
        SectionCard(
          title: 'Datos de dotación',
          icon: Icons.checkroom_outlined,
          children: [
            AppTextField(
              label: 'Estatura (m)',
              value: c['estatura'] ?? '',
              hint: '1.69',
              keyboard: TextInputType.number,
              onChanged: (v) => c['estatura'] = v,
            ),
            Row(
              children: [
                Expanded(
                  child: AppDropdown(
                    label: 'Talla camisa',
                    value: (c['talla_camisa'] ?? '').toString().isEmpty
                        ? null
                        : c['talla_camisa'],
                    items: Catalogos.tallas,
                    onChanged: (v) {
                      c['talla_camisa'] = v;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDropdown(
                    label: 'Talla pantalón',
                    value: (c['talla_pantalon'] ?? '').toString().isEmpty
                        ? null
                        : c['talla_pantalon'],
                    items: Catalogos.tallas,
                    onChanged: (v) {
                      c['talla_pantalon'] = v;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Calzado',
                    value: c['calzado'] ?? '',
                    hint: '38',
                    keyboard: TextInputType.number,
                    onChanged: (v) => c['calzado'] = v,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDropdown(
                    label: 'Gorra',
                    value: (c['gorra'] ?? '').toString().isEmpty
                        ? null
                        : c['gorra'],
                    items: Catalogos.tallasGorra,
                    onChanged: (v) {
                      c['gorra'] = v;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        SectionCard(
          title: 'Vehículo y carnet de la patria',
          icon: Icons.badge_outlined,
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
              show: tieneVehiculo,
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
            AppTextField(
              label: 'Ocupación',
              value: c['ocupacion'] ?? '',
              hint: 'Ej: INDEPENDIENTE',
              onChanged: (v) => c['ocupacion'] = v.toUpperCase(),
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
          title: 'Foto del grupo familiar',
          icon: Icons.groups_outlined,
          children: [
            if ((c['foto_familia'] ?? '') != '')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    base64Decode(c['foto_familia']),
                    height: 170,
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
                  ? 'Cargar foto de la familia'
                  : 'Reemplazar foto'),
            ),
            const SizedBox(height: 6),
            Text(
              'Jefe/a de familia: ${r['nombres'] ?? ''} ${r['apellidos'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.gray),
            ),
          ],
        ),
      ],
    );
  }
}
