import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/expediente.dart';
import '../theme.dart';

/// Muestra un selector Cámara / Galería y devuelve la imagen en base64
/// (comprimida). Devuelve null si el usuario cancela.
Future<String?> pickImageB64(BuildContext context,
    {double maxWidth = 1024, int quality = 70, String? title}) async {
  final source = await showModalBottomSheet<ImageSource>(
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
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          const SizedBox(height: 6),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined,
                color: AppColors.blue),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading:
                const Icon(Icons.photo_library_outlined, color: AppColors.blue),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final img = await ImagePicker()
      .pickImage(source: source, maxWidth: maxWidth, imageQuality: quality);
  if (img == null) return null;
  return base64Encode(await img.readAsBytes());
}

/// Miniatura de imagen base64 con botón para quitarla.
class B64Thumb extends StatelessWidget {
  final String b64;
  final VoidCallback onRemove;
  const B64Thumb({super.key, required this.b64, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(base64Decode(b64),
              width: 64, height: 64, fit: BoxFit.cover, gaplessPlayback: true),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  color: AppColors.danger, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de sección con título e ícono.
class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  /// Línea de apoyo bajo el título, para explicar qué se pide sin
  /// recargar cada campo con textos de ayuda.
  final String? subtitle;

  const SectionCard(
      {super.key,
      required this.title,
      required this.icon,
      required this.children,
      this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: AppColors.blueDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.ink)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!,
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.gray)),
                      ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Campo de texto controlado por valor inicial + onChanged.
class AppTextField extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboard;
  final int maxLines;
  final bool required;
  final String? hint;

  const AppTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboard,
    this.maxLines = 1,
    this.required = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value ?? '',
        keyboardType: keyboard,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
        ),
      ),
    );
  }
}

/// Dropdown simple para catálogos.
class AppDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool required;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    // Los expedientes importados del censo traen texto libre escrito a mano
    // ("DISCAPACIDAD MOTORA", talla "14"). Si ese valor no está en la lista,
    // lo agregamos como opción en vez de mostrarlo vacío: así el operador ve
    // el dato real y no lo pierde sin darse cuenta al guardar.
    final v = (value ?? '').trim();
    final opciones = (v.isNotEmpty && !items.contains(v))
        ? [v, ...items]
        : items;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: v.isEmpty ? null : v,
        isExpanded: true,
        decoration:
            InputDecoration(labelText: required ? '$label *' : label),
        items: opciones
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    overflow: TextOverflow.ellipsis,
                    // El valor traído del censo se marca en gris para que se
                    // note que no es una opción estándar.
                    style: items.contains(e)
                        ? null
                        : const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

/// Pregunta Sí / No / (No sabe). Guarda 'si' / 'no' / 'ns'.
class TriChoice extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool allowNs;

  const TriChoice({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.allowNs = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13.5, color: AppColors.gray)),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: [
              const ButtonSegment(value: 'si', label: Text('Sí')),
              const ButtonSegment(value: 'no', label: Text('No')),
              if (allowNs)
                const ButtonSegment(value: 'ns', label: Text('No sabe')),
            ],
            selected: value == null ? <String>{} : {value!},
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            onSelectionChanged: (s) {
              if (s.isNotEmpty) onChanged(s.first);
            },
          ),
        ],
      ),
    );
  }
}

/// Aparece/desaparece suavemente cuando la condición cambia.
class Conditional extends StatelessWidget {
  final bool show;
  final Widget child;
  const Conditional({super.key, required this.show, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: show ? child : const SizedBox(width: double.infinity),
    );
  }
}

/// Checkbox de aceptación / declaración.
class CheckTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const CheckTile(
      {super.key,
      required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: AppColors.blue,
    );
  }
}

/// Selector de fecha (guarda ISO yyyy-MM-dd).
class DateField extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool required;

  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    String display = '';
    if (value != null && value!.isNotEmpty) {
      final d = DateTime.tryParse(value!);
      if (d != null) display = DateFormat('dd/MM/yyyy').format(d);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.tryParse(value ?? '') ??
                DateTime(now.year - 30, now.month, now.day),
            firstDate: DateTime(1920),
            lastDate: now,
          );
          if (picked != null) {
            onChanged(DateFormat('yyyy-MM-dd').format(picked));
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: required ? '$label *' : label,
            suffixIcon:
                const Icon(Icons.calendar_today_outlined, size: 18),
          ),
          child: Text(display.isEmpty ? '—' : display,
              style: TextStyle(
                  fontSize: 15,
                  color: display.isEmpty
                      ? AppColors.grayLight
                      : AppColors.ink)),
        ),
      ),
    );
  }
}

/// Selección múltiple con chips.
class MultiChips extends StatelessWidget {
  final String label;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const MultiChips({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13.5, color: AppColors.gray)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((o) {
              final on = selected.contains(o);
              return FilterChip(
                label: Text(o),
                selected: on,
                onSelected: (_) {
                  final next = [...selected];
                  on ? next.remove(o) : next.add(o);
                  onChanged(next);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Insignia de prioridad / estatus.
class Badge2 extends StatelessWidget {
  final String text;
  final Color color;
  const Badge2(this.text, {super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

Color prioridadColor(String p) => switch (p) {
      'Urgente' => AppColors.danger,
      'Alta' => AppColors.warning,
      _ => AppColors.blue,
    };

/// Icono propio de cada alerta, para distinguirlas de un vistazo.
IconData iconoDeAlerta(ClaseAlerta c) {
  switch (c) {
    case ClaseAlerta.ninos:
      return Icons.child_care_outlined;
    case ClaseAlerta.adultoMayor:
      return Icons.elderly_outlined;
    case ClaseAlerta.discapacidad:
      return Icons.accessible_outlined;
    case ClaseAlerta.embarazo:
      return Icons.pregnant_woman_outlined;
    case ClaseAlerta.condicionMedica:
      return Icons.medical_services_outlined;
    case ClaseAlerta.sinCedula:
      return Icons.badge_outlined;
    case ClaseAlerta.sinFotoFamilia:
      return Icons.photo_camera_outlined;
  }
}

/// Chip de alerta del expediente.
/// Azul = necesidad de atención (niños, adulto mayor, discapacidad,
/// condición médica). Ámbar = falta cargar algo (fotos).
/// El color y el icono distintos evitan que se confundan entre sí.
class AlertaChip extends StatelessWidget {
  final Alerta alerta;
  const AlertaChip(this.alerta, {super.key});

  @override
  Widget build(BuildContext context) {
    final pendiente = alerta.esPendiente;
    final color = pendiente ? AppColors.warning : AppColors.blue;
    final icono = iconoDeAlerta(alerta.clase);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: color),
          const SizedBox(width: 5),
          Text(alerta.texto,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

/// Chip de filtro. Único estilo para toda la app (expedientes y acceso),
/// para que los filtros se vean y se comporten igual en cada pantalla.
///
/// [color] tiñe el chip cuando está activo; [icono] es opcional y sirve
/// para reforzar el significado (prioridad, presencia, comida).
class FiltroChip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;
  final Color color;
  final IconData? icono;

  const FiltroChip({
    super.key,
    required this.label,
    required this.activo,
    required this.onTap,
    this.color = AppColors.blue,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: activo ? color : AppColors.gray,
            fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        avatar: icono == null
            ? null
            : Icon(icono, size: 14, color: activo ? color : AppColors.gray),
        selected: activo,
        showCheckmark: false,
        backgroundColor: Colors.white,
        selectedColor: color.withOpacity(.12),
        side: BorderSide(color: activo ? color : AppColors.line),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// Fila de filtros con desplazamiento horizontal, con el alto y el
/// margen que usan todas las pantallas.
class FiltroFila extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  const FiltroFila({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: padding,
          children: children,
        ),
      );
}

// CÉDULA · nacionalidad + número, guardados como un solo valor

/// Prefijos de cédula usados en Venezuela.
const kNacionalidadesCedula = ['V', 'E', 'P'];

/// Separa "V-22.352.324" en ('V', '22352324'). Tolera lo que traiga el
/// censo viejo: sin guion, sin puntos o sin letra.
(String, String) partirCedula(String? valor) {
  final v = (valor ?? '').trim().toUpperCase();
  if (v.isEmpty) return ('V', '');
  final letra = kNacionalidadesCedula.firstWhere(
      (n) => v.startsWith(n), orElse: () => 'V');
  final digitos = v.replaceAll(RegExp(r'[^0-9]'), '');
  return (letra, digitos);
}

/// Arma "V-22.352.324" a partir de la letra y los dígitos.
String unirCedula(String letra, String digitos) {
  final d = digitos.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.isEmpty) return '';
  // Puntos de millar, como se escribe la cédula en Venezuela.
  final buf = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i > 0 && (d.length - i) % 3 == 0) buf.write('.');
    buf.write(d[i]);
  }
  return '$letra-$buf';
}

/// Campo de cédula: desplegable V/E/P + número. Se guarda concatenado.
class CedulaField extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final bool required;
  final String label;

  const CedulaField({
    super.key,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.label = 'Cédula',
  });

  @override
  State<CedulaField> createState() => _CedulaFieldState();
}

class _CedulaFieldState extends State<CedulaField> {
  late String _letra;
  late TextEditingController _num;

  @override
  void initState() {
    super.initState();
    final (l, d) = partirCedula(widget.value);
    _letra = l;
    _num = TextEditingController(text: d);
  }

  @override
  void dispose() {
    _num.dispose();
    super.dispose();
  }

  void _emitir() => widget.onChanged(unirCedula(_letra, _num.text));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: DropdownButtonFormField<String>(
              value: _letra,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: kNacionalidadesCedula
                  .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                  .toList(),
              onChanged: (v) {
                setState(() => _letra = v ?? 'V');
                _emitir();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _num,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              decoration: InputDecoration(
                labelText: widget.required
                    ? '${widget.label} *'
                    : widget.label,
                hintText: '22352324',
                helperText: _num.text.isEmpty
                    ? null
                    : unirCedula(_letra, _num.text),
              ),
              onChanged: (_) {
                setState(() {}); // refresca el helper con el formato final
                _emitir();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// TELÉFONO · código de operadora + 7 dígitos

/// Códigos válidos en Venezuela: móviles primero, luego los fijos más
/// usados en la zona de procedencia de las familias.
const kCodigosTelefono = [
  '0412', '0414', '0416', '0424', '0426', // móviles
  '0212', '0234', '0235', '0238', '0239', // Distrito Capital, La Guaira, Miranda
  '0241', '0243', '0244', '0245', '0246', // centro
  '0251', '0252', '0253', '0254', '0255', // centro-occidente
  '0261', '0264', '0265', '0268', '0269', // occidente
  '0271', '0272', '0273', '0274', '0275', // andes
  '0281', '0282', '0283', '0285', '0286', '0287', '0288', // oriente
  '0291', '0292', '0293', '0294', '0295', // nororiente
];

/// Separa "0414-3782216" en ('0414', '3782216').
/// Tolera los del censo viejo, que muchas veces vienen sin el 0 inicial
/// ("4143782216") o sin guion.
(String, String) partirTelefono(String? valor) {
  var d = (valor ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  if (d.isEmpty) return ('0414', '');
  if (d.length == 10 && !d.startsWith('0')) d = '0$d'; // faltaba el cero
  if (d.length >= 11) {
    final code = d.substring(0, 4);
    return (
      kCodigosTelefono.contains(code) ? code : '0414',
      d.substring(4, 11),
    );
  }
  return ('0414', d.length > 7 ? d.substring(0, 7) : d);
}

String unirTelefono(String codigo, String numero) {
  final n = numero.replaceAll(RegExp(r'[^0-9]'), '');
  if (n.isEmpty) return '';
  return '$codigo-$n';
}

/// Campo de teléfono: código de operadora + 7 dígitos, como en la banca.
class TelefonoField extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final bool required;
  final String label;

  const TelefonoField({
    super.key,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.label = 'Teléfono',
  });

  @override
  State<TelefonoField> createState() => _TelefonoFieldState();
}

class _TelefonoFieldState extends State<TelefonoField> {
  late String _codigo;
  late TextEditingController _num;

  @override
  void initState() {
    super.initState();
    final (c, n) = partirTelefono(widget.value);
    _codigo = c;
    _num = TextEditingController(text: n);
  }

  @override
  void dispose() {
    _num.dispose();
    super.dispose();
  }

  void _emitir() => widget.onChanged(unirTelefono(_codigo, _num.text));

  @override
  Widget build(BuildContext context) {
    final n = _num.text;
    final incompleto = n.isNotEmpty && n.length < 7;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: DropdownButtonFormField<String>(
              value: _codigo,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Código'),
              items: kCodigosTelefono
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                setState(() => _codigo = v ?? '0414');
                _emitir();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _num,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(7),
              ],
              decoration: InputDecoration(
                labelText:
                    widget.required ? '${widget.label} *' : widget.label,
                hintText: '3782216',
                errorText: incompleto ? 'Faltan ${7 - n.length} dígitos' : null,
                helperText: incompleto || n.isEmpty
                    ? null
                    : unirTelefono(_codigo, n),
              ),
              onChanged: (_) {
                setState(() {});
                _emitir();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de estatura en metros con formato automático.
/// El operador teclea dígitos y el campo los acomoda solo: 170 → 1.70.
/// Evita la mezcla de "1,70", "170", "1.7" que trae el censo en papel.
class EstaturaField extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final String label;

  const EstaturaField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Estatura (m)',
  });

  @override
  State<EstaturaField> createState() => _EstaturaFieldState();
}

class _EstaturaFieldState extends State<EstaturaField> {
  late TextEditingController _c;

  /// "1.70" / "1,70" / "170" → "170" (solo dígitos, máximo 3).
  static String _digitos(String? v) {
    final d = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return d.length > 3 ? d.substring(0, 3) : d;
  }

  /// "170" → "1.70"; "17" → "1.7"; "1" → "1"
  static String formatear(String digitos) {
    if (digitos.isEmpty) return '';
    if (digitos.length == 1) return digitos;
    return '${digitos[0]}.${digitos.substring(1)}';
  }

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: formatear(_digitos(widget.value)));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _alEscribir(String texto) {
    final formateado = formatear(_digitos(texto));
    // El cursor siempre al final: el punto se inserta mientras se escribe.
    _c.value = TextEditingValue(
      text: formateado,
      selection: TextSelection.collapsed(offset: formateado.length),
    );
    widget.onChanged(formateado);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: '1.70',
          helperText: 'Escriba solo números: 170 se convierte en 1.70',
        ),
        onChanged: _alEscribir,
      ),
    );
  }
}
