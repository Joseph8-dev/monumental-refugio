import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme.dart';

/// Envío de reportes por correo.
/// El servidor genera el PDF/Excel y lo manda como adjunto; la app solo
/// encola el pedido. Se recuerda el último correo usado para no tener que
/// escribirlo cada vez.
class ReportesCard extends StatefulWidget {
  const ReportesCard({super.key});

  @override
  State<ReportesCard> createState() => _ReportesCardState();
}

class _ReportesCardState extends State<ReportesCard> {
  // Última semana por defecto: es el corte con el que se revisa el
  // refugio. Para un periodo mayor se elige a mano en el calendario.
  late DateTimeRange _rango = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );
  String? _enviando;

  void _fijarDias(int dias) {
    setState(() {
      _rango = DateTimeRange(
        start: DateTime.now().subtract(Duration(days: dias)),
        end: DateTime.now(),
      );
    });
  }

  Future<void> _elegirRango() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      initialDateRange: _rango,
      locale: const Locale('es'),
      helpText: 'Periodo del reporte',
      saveText: 'Aplicar',
    );
    if (r != null && mounted) setState(() => _rango = r);
  }

  Future<void> _enviar(String tipo, String nombre) async {
    setState(() => _enviando = tipo);
    try {
      final msg = await ApiService.instance.enviarReporte(
        tipo: tipo,
        desde: _rango.start,
        hasta: _rango.end,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.ok,
        duration: const Duration(seconds: 4),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se pudo enviar $nombre: $e'),
        backgroundColor: AppColors.danger,
      ));
    } finally {
      if (mounted) setState(() => _enviando = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('d MMM y', 'es');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reportes por correo',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.ink)),
          const Text('El servidor genera el archivo y lo envía como adjunto',
              style: TextStyle(fontSize: 12, color: AppColors.gray)),
          const SizedBox(height: 14),


          // Selector de periodo
          InkWell(
            onTap: _elegirRango,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range_outlined,
                      size: 19, color: AppColors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Periodo',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.gray)),
                        Text(
                          '${f.format(_rango.start)} — ${f.format(_rango.end)}',
                          style: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_calendar_outlined,
                      size: 17, color: AppColors.grayLight),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Atajo(
                  etiqueta: 'Esta semana',
                  dias: 6,
                  rango: _rango,
                  onTap: _fijarDias),
              _Atajo(
                  etiqueta: 'Últimos 15 días',
                  dias: 14,
                  rango: _rango,
                  onTap: _fijarDias),
              _Atajo(
                  etiqueta: 'Último mes',
                  dias: 29,
                  rango: _rango,
                  onTap: _fijarDias),
            ],
          ),
          const SizedBox(height: 16),

          _Boton(
            icono: Icons.picture_as_pdf_outlined,
            color: AppColors.danger,
            titulo: 'Resumen ejecutivo (PDF)',
            detalle: 'Cifras, urgencia, vivienda y patologías',
            cargando: _enviando == 'resumen',
            onTap: () => _enviar('resumen', 'el resumen'),
          ),
          const SizedBox(height: 8),
          _Boton(
            icono: Icons.table_chart_outlined,
            color: AppColors.ok,
            titulo: 'Censo completo (Excel)',
            detalle: 'Una fila por persona, formato del censo original',
            cargando: _enviando == 'censo',
            onTap: () => _enviar('censo', 'el censo'),
          ),
          const SizedBox(height: 8),
          _Boton(
            icono: Icons.restaurant_outlined,
            color: AppColors.blue,
            titulo: 'Comidas y accesos (Excel)',
            detalle: 'Del periodo seleccionado arriba',
            cargando: _enviando == 'comidas',
            onTap: () => _enviar('comidas', 'el reporte de comidas'),
          ),
        ],
      ),
    );
  }
}

class _Boton extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo, detalle;
  final bool cargando;
  final VoidCallback onTap;
  const _Boton({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.detalle,
    required this.cargando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: cargando ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, size: 19, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13.5)),
                  Text(detalle,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.gray)),
                ],
              ),
            ),
            if (cargando)
              const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            else
              const Icon(Icons.send_outlined,
                  size: 17, color: AppColors.grayLight),
          ],
        ),
      ),
    );
  }
}


/// Atajo de periodo. Se marca cuando el rango elegido coincide.
class _Atajo extends StatelessWidget {
  final String etiqueta;
  final int dias;
  final DateTimeRange rango;
  final void Function(int) onTap;
  const _Atajo({
    required this.etiqueta,
    required this.dias,
    required this.rango,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activo = rango.duration.inDays == dias &&
        DateTime.now().difference(rango.end).inDays == 0;
    return ChoiceChip(
      label: Text(etiqueta,
          style: TextStyle(
              fontSize: 12,
              color: activo ? AppColors.blue : AppColors.gray,
              fontWeight: activo ? FontWeight.w700 : FontWeight.w500)),
      selected: activo,
      showCheckmark: false,
      backgroundColor: Colors.white,
      selectedColor: AppColors.blueSoft,
      side: BorderSide(color: activo ? AppColors.blue : AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => onTap(dias),
    );
  }
}
