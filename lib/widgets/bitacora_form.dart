import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../datos.dart';
import '../models/bitacora.dart';
import '../models/expediente.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'form_widgets.dart';

/// Formulario para registrar una entrada de bitácora.
/// Sirve para los tres tipos (actividad, incidencia, ayuda): cambian la
/// lista de categorías y el color, no la forma. Si en el futuro hay que
/// agregar un cuarto tipo, basta con una lista nueva en
/// `CatalogosBitacora`.
Future<bool> mostrarFormularioBitacora(
  BuildContext context, {
  required String tipo,
  Expediente? familia,
}) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (_) => _FormularioBitacora(tipo: tipo, familia: familia),
  );
  return r ?? false;
}

Color colorTipoBitacora(String tipo) => switch (tipo) {
      TipoBitacora.actividad => AppColors.blue,
      TipoBitacora.incidencia => AppColors.warning,
      TipoBitacora.ayuda => AppColors.ok,
      _ => AppColors.gray,
    };

IconData iconoTipoBitacora(String tipo) => switch (tipo) {
      TipoBitacora.actividad => Icons.event_available_outlined,
      TipoBitacora.incidencia => Icons.report_problem_outlined,
      TipoBitacora.ayuda => Icons.volunteer_activism_outlined,
      _ => Icons.notes_outlined,
    };

class _FormularioBitacora extends StatefulWidget {
  final String tipo;

  /// Las ayudas socioeconómicas siempre corresponden a una familia
  /// concreta, así que se abre desde su tarjeta y llega ya elegida.
  final Expediente? familia;

  const _FormularioBitacora({required this.tipo, this.familia});

  @override
  State<_FormularioBitacora> createState() => _FormularioBitacoraState();
}

class _FormularioBitacoraState extends State<_FormularioBitacora> {
  String? _categoria;
  String _categoriaOtra = '';
  String _descripcion = '';
  String _observacion = '';
  DateTime _ocurrido = DateTime.now();
  bool _guardando = false;

  bool get _esAyuda => widget.tipo == TipoBitacora.ayuda;

  Future<void> _elegirFechaHora() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _ocurrido,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('es'),
      helpText: 'Fecha del hecho',
    );
    if (f == null || !mounted) return;

    final h = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_ocurrido),
      helpText: 'Hora del hecho',
    );
    if (!mounted) return;

    setState(() {
      _ocurrido = DateTime(
        f.year, f.month, f.day,
        h?.hour ?? _ocurrido.hour,
        h?.minute ?? _ocurrido.minute,
      );
    });
  }

  Future<void> _guardar() async {
    if (_categoria == null) {
      _aviso('Seleccione una categoría.');
      return;
    }
    if (_categoria == CatalogosBitacora.otros && _categoriaOtra.trim().isEmpty) {
      _aviso('Escriba cuál, ya que eligió "Otros".');
      return;
    }
    if (_descripcion.trim().isEmpty) {
      _aviso('Describa lo ocurrido.');
      return;
    }
    if (_esAyuda && widget.familia?.id == null) {
      _aviso('La ayuda debe registrarse desde la familia que la recibe.');
      return;
    }

    setState(() => _guardando = true);
    try {
      await ApiService.instance.crearBitacora(RegistroBitacora(
        tipo: widget.tipo,
        categoria: _categoria!,
        categoriaOtra: _categoriaOtra.trim().isEmpty ? null : _categoriaOtra.trim(),
        descripcion: _descripcion.trim(),
        observacion: _observacion.trim().isEmpty ? null : _observacion.trim(),
        expedienteId: widget.familia?.id,
        ocurrido: _ocurrido,
      ));
      Datos.cambiaron(origen: 'acceso');
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _aviso('No se pudo guardar: $e');
    }
  }

  void _aviso(String m) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), backgroundColor: AppColors.danger),
      );

  @override
  Widget build(BuildContext context) {
    final color = colorTipoBitacora(widget.tipo);
    final categorias = CatalogosBitacora.deTipo(widget.tipo);
    final f = DateFormat("d 'de' MMMM, h:mm a", 'es');

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        maxChildSize: 0.95,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconoTipoBitacora(widget.tipo),
                      size: 21, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Registrar ${TipoBitacora.etiqueta(widget.tipo).toLowerCase()}',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            AppDropdown(
              label: 'Categoría',
              required: true,
              value: _categoria,
              items: categorias,
              onChanged: (v) => setState(() => _categoria = v),
            ),
            Conditional(
              show: _categoria == CatalogosBitacora.otros,
              child: AppTextField(
                label: '¿Cuál?',
                required: true,
                value: _categoriaOtra,
                hint: 'Escriba la categoría',
                onChanged: (v) => _categoriaOtra = v,
              ),
            ),

            AppTextField(
              label: 'Descripción',
              required: true,
              value: _descripcion,
              maxLines: 3,
              hint: 'Qué ocurrió, quiénes participaron, dónde',
              onChanged: (v) => _descripcion = v,
            ),
            AppTextField(
              label: 'Observaciones extra',
              value: _observacion,
              maxLines: 2,
              hint: 'Opcional: algo que deba tener en cuenta la coordinación',
              onChanged: (v) => _observacion = v,
            ),

            // Familia de la ayuda: viene fijada desde su tarjeta, no se
            // elige aquí. Una ayuda sin destinatario no sirve de nada.
            if (_esAyuda && widget.familia != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.family_restroom_outlined,
                        size: 18, color: AppColors.blueDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ayuda para la familia',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.gray)),
                          Text(
                            '${widget.familia!.nombreResponsable} · '
                            'Cubículo ${widget.familia!.censo['apto'] ?? '—'}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Fecha y hora: por defecto ahora, editable si se registra algo
            // que pasó más temprano en el turno.
            InkWell(
              onTap: _elegirFechaHora,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 19, color: AppColors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fecha y hora del hecho',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.gray)),
                          Text(f.format(_ocurrido),
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_calendar_outlined,
                        size: 17, color: AppColors.grayLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            FilledButton(
              onPressed: _guardando ? null : _guardar,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('Guardar registro'),
            ),
          ],
        ),
      ),
    );
  }
}
