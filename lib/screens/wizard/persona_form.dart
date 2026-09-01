import 'package:flutter/material.dart';
import '../../models/expediente.dart';
import '../../theme.dart';
import '../../widgets/form_widgets.dart';

/// Formulario de UNA PERSONA — equivale a una fila del Excel del censo.
/// Se usa igual para el jefe/a de familia y para cada integrante, porque el
/// censo los trata idénticamente. Trabaja sobre un Map para poder editar
/// tanto `expediente.responsable` como cada acompañante sin duplicar código.
/// Claves (mismas que guarda el importador):
///   nombres · apellidos · cedula · fecha_nacimiento · edad · sexo
///   parentesco · condicion_salud · tipo_sangre · telefono · email
///   brazalete · ocupacion · dieta · dieta_desc · estatura
///   talla_camisa · talla_pantalon · calzado · gorra · observaciones
///   documento_imagen
class PersonaForm extends StatelessWidget {
  final Map<String, dynamic> p;
  final VoidCallback onChanged;

  /// El jefe/a no elige parentesco (siempre es "Jefe/a").
  final bool esJefe;

  const PersonaForm({
    super.key,
    required this.p,
    required this.onChanged,
    this.esJefe = false,
  });

  static int? edadDesde(String? iso) =>
      edadViva(fechaNacimiento: iso);

  String _s(String k) => (p[k] ?? '').toString();
  String? _opt(String k) => _s(k).isEmpty ? null : _s(k);

  @override
  Widget build(BuildContext context) {
    // Edad sugerida por la fecha de nacimiento. NO se escribe aquí: si se
    // asignara en cada rebuild, cualquier edad tecleada a mano se perdería
    // al instante (por eso antes no se podía corregir la edad de nadie).
    // Solo se rellena cuando el operador cambia la fecha, o cuando el
    // campo está vacío.
    final auto = edadDesde(p['fecha_nacimiento']);
    if (auto != null && p['edad'] == null) p['edad'] = auto;

    return Column(
      children: [
        SectionCard(
          title: 'Identificación',
          subtitle: 'Datos que identifican a la persona en el censo',
          icon: Icons.badge_outlined,
          children: [
            AppTextField(
              label: 'Nombres',
              required: true,
              value: _s('nombres'),
              onChanged: (v) => p['nombres'] = v,
            ),
            AppTextField(
              label: 'Apellidos',
              required: true,
              value: _s('apellidos'),
              onChanged: (v) => p['apellidos'] = v,
            ),
            CedulaField(
              required: esJefe,
              value: _s('cedula'),
              onChanged: (v) => p['cedula'] = v,
            ),
            DateField(
              label: 'Fecha de nacimiento',
              value: p['fecha_nacimiento'],
              onChanged: (v) {
                p['fecha_nacimiento'] = v;
                // Al cambiar la fecha sí recalculamos: es una acción
                // explícita del operador.
                p['edad'] = edadDesde(v);
                onChanged();
              },
            ),
            AppTextField(
              // La clave depende de la fecha para que el campo se refresque
              // cuando el operador la cambia, pero no mientras teclea.
              key: ValueKey('edad-${p['fecha_nacimiento']}'),
              label: 'Edad',
              required: true,
              value: p['edad']?.toString() ?? '',
              keyboard: TextInputType.number,
              hint: auto != null
                  ? 'Según la fecha: $auto años (puede corregirse)'
                  : null,
              onChanged: (v) => p['edad'] = int.tryParse(v),
            ),
            AppDropdown(
              label: 'Sexo',
              required: true,
              value: _opt('sexo'),
              items: Catalogos.sexos,
              onChanged: (v) {
                p['sexo'] = v;
                onChanged();
              },
            ),
            if (!esJefe)
              AppDropdown(
                label: 'Parentesco con el jefe/a de familia',
                required: true,
                value: _opt('parentesco'),
                items: Catalogos.parentescos,
                onChanged: (v) {
                  p['parentesco'] = v;
                  onChanged();
                },
              ),
            AppTextField(
              label: 'Brazalete',
              value: _s('brazalete'),
              hint: 'Código impreso en el brazalete',
              onChanged: (v) => p['brazalete'] = v,
            ),
          ],
        ),
        SectionCard(
          title: 'Contacto y ocupación',
          subtitle: 'Opcional para los integrantes menores de edad',
          icon: Icons.call_outlined,
          children: [
            TelefonoField(
              required: esJefe,
              value: _s('telefono'),
              onChanged: (v) => p['telefono'] = v,
            ),
            AppTextField(
              label: 'Correo electrónico',
              value: _s('email'),
              keyboard: TextInputType.emailAddress,
              onChanged: (v) => p['email'] = v,
            ),
            AppTextField(
              label: 'Ocupación',
              value: _s('ocupacion'),
              hint: 'Ej: INDEPENDIENTE',
              onChanged: (v) => p['ocupacion'] = v.toUpperCase(),
            ),
          ],
        ),
        SectionCard(
          title: 'Salud',
          subtitle: 'Alimenta el tablero de patologías del refugio',
          icon: Icons.favorite_outline,
          children: [
            AppDropdown(
              label: 'Condición de salud',
              required: true,
              value: _opt('condicion_salud'),
              items: Catalogos.condicionesSalud,
              onChanged: (v) {
                p['condicion_salud'] = v;
                onChanged();
              },
            ),
            Conditional(
              show: _s('condicion_salud') == 'OTRA',
              child: AppTextField(
                label: 'Especifique la condición',
                value: _s('condicion_desc'),
                onChanged: (v) => p['condicion_desc'] = v,
              ),
            ),
            AppDropdown(
              label: 'Tipo de sangre',
              value: _opt('tipo_sangre'),
              items: Catalogos.tiposSangre,
              onChanged: (v) {
                p['tipo_sangre'] = v;
                onChanged();
              },
            ),
            TriChoice(
              label: '¿Requiere dieta alimenticia?',
              value: p['dieta'],
              onChanged: (v) {
                p['dieta'] = v;
                onChanged();
              },
            ),
            Conditional(
              show: p['dieta'] == 'si',
              child: AppTextField(
                label: 'Detalle de la dieta',
                value: _s('dieta_desc'),
                hint: 'Ej: nada enlatado',
                onChanged: (v) => p['dieta_desc'] = v,
              ),
            ),
          ],
        ),
        SectionCard(
          title: 'Dotación',
          subtitle: 'Tallas para la entrega de insumos',
          icon: Icons.checkroom_outlined,
          children: [
            EstaturaField(
              value: _s('estatura'),
              onChanged: (v) => p['estatura'] = v,
            ),
            Row(
              children: [
                Expanded(
                  child: AppDropdown(
                    label: 'Talla camisa',
                    value: _opt('talla_camisa'),
                    items: Catalogos.tallas,
                    onChanged: (v) {
                      p['talla_camisa'] = v;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDropdown(
                    label: 'Talla pantalón',
                    value: _opt('talla_pantalon'),
                    items: Catalogos.tallas,
                    onChanged: (v) {
                      p['talla_pantalon'] = v;
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
                    value: _s('calzado'),
                    keyboard: TextInputType.number,
                    onChanged: (v) => p['calzado'] = v,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDropdown(
                    label: 'Gorra',
                    value: _opt('gorra'),
                    items: Catalogos.tallasGorra,
                    onChanged: (v) {
                      p['gorra'] = v;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        SectionCard(
          title: 'Documento y observaciones',
          subtitle: 'La foto de la cédula se puede cargar después',
          icon: Icons.description_outlined,
          children: [
            Row(
              children: [
                if (_s('documento_imagen').isNotEmpty) ...[
                  B64Thumb(
                    b64: _s('documento_imagen'),
                    onRemove: () {
                      p['documento_imagen'] = null;
                      onChanged();
                    },
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final b64 = await pickImageB64(context,
                          maxWidth: 900, title: 'Cédula o documento');
                      if (b64 == null) return;
                      p['documento_imagen'] = b64;
                      onChanged();
                    },
                    icon: const Icon(Icons.add_a_photo_outlined, size: 17),
                    label: Text(_s('documento_imagen').isEmpty
                        ? 'Adjuntar foto de la cédula'
                        : 'Reemplazar foto'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Observaciones',
              value: _s('observaciones'),
              maxLines: 3,
              onChanged: (v) => p['observaciones'] = v,
            ),
          ],
        ),
      ],
    );
  }
}

/// Valida una persona del censo. Devuelve el primer error o null.
String? validarPersona(Map<String, dynamic> p, {bool esJefe = false}) {
  String s(String k) => (p[k] ?? '').toString().trim();
  final quien = esJefe ? 'del jefe/a de familia' : 'del integrante';

  if (s('nombres').isEmpty || s('apellidos').isEmpty) {
    return 'Faltan nombres y apellidos $quien.';
  }
  if (esJefe && s('cedula').isEmpty) {
    return 'La cédula del jefe/a de familia es obligatoria.';
  }
  if (s('cedula').isNotEmpty) {
    final d = s('cedula').replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length < 6) return 'La cédula parece incompleta ($quien).';
  }
  if (p['edad'] == null) return 'Falta la edad $quien.';
  if (s('sexo').isEmpty) return 'Falta el sexo $quien.';
  if (!esJefe && s('parentesco').isEmpty) {
    return 'Falta el parentesco de ${s('nombres')} ${s('apellidos')}.';
  }
  if (esJefe && s('telefono').isEmpty) {
    return 'El teléfono del jefe/a de familia es obligatorio.';
  }
  if (s('telefono').isNotEmpty) {
    // Código de operadora (4) + abonado (7) = 11 dígitos.
    final d = s('telefono').replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length != 11) {
      return 'El teléfono $quien está incompleto (código + 7 dígitos).';
    }
  }
  if (s('condicion_salud').isEmpty) {
    return 'Falta la condición de salud $quien.';
  }
  final d = p['dieta'];
  if (d != 'si' && d != 'no' && d != 'ns') {
    return 'Indique si requiere dieta alimenticia $quien.';
  }
  return null;
}
