import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bitacora.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'bitacora_form.dart';

/// Resumen de lo que ya se registró hoy en la bitácora.
///
/// Va en la pantalla del vigilante, encima de los botones: sin esto no
/// hay forma de saber si la actividad de la mañana ya quedó asentada, y
/// terminan duplicándose entre turnos.
class BitacoraHoy extends StatefulWidget {
  /// Se llama al registrar algo, para que la pantalla se refresque.
  final VoidCallback? onCambio;
  const BitacoraHoy({super.key, this.onCambio});

  @override
  State<BitacoraHoy> createState() => BitacoraHoyState();
}

class BitacoraHoyState extends State<BitacoraHoy> {
  List<RegistroBitacora> _hoy = [];
  bool _cargando = true;
  bool _abierto = false;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    try {
      // Se piden las últimas y se filtran por fecha en la app: son pocas
      // y así no hace falta otro parámetro en el servidor.
      final r = await ApiService.instance.listarBitacora(limit: 40);
      final ahora = DateTime.now();
      if (!mounted) return;
      setState(() {
        _hoy = r.items
            .where((x) =>
                x.ocurrido.year == ahora.year &&
                x.ocurrido.month == ahora.month &&
                x.ocurrido.day == ahora.day)
            .toList();
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _registrar(String tipo) async {
    final ok = await mostrarFormularioBitacora(context, tipo: tipo);
    if (!ok) return;
    await cargar();
    widget.onCambio?.call();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${TipoBitacora.etiqueta(tipo)} registrada'),
      backgroundColor: colorTipoBitacora(tipo),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final actividades =
        _hoy.where((x) => x.tipo == TipoBitacora.actividad).toList();
    final incidencias =
        _hoy.where((x) => x.tipo == TipoBitacora.incidencia).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Boton(
              tipo: TipoBitacora.actividad,
              etiqueta: 'Actividad',
              onTap: () => _registrar(TipoBitacora.actividad),
            ),
            const SizedBox(width: 8),
            _Boton(
              tipo: TipoBitacora.incidencia,
              etiqueta: 'Incidencia / Novedad',
              onTap: () => _registrar(TipoBitacora.incidencia),
            ),
          ],
        ),

        if (!_cargando) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(() => _abierto = !_abierto),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    _hoy.isEmpty
                        ? Icons.info_outline
                        : Icons.checklist_rtl_outlined,
                    size: 16,
                    color: AppColors.gray,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _hoy.isEmpty
                          ? 'Hoy no se ha registrado nada en la bitácora'
                          : 'Hoy: ${actividades.length} actividad'
                              '${actividades.length == 1 ? '' : 'es'}'
                              ' · ${incidencias.length} incidencia'
                              '${incidencias.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.gray),
                    ),
                  ),
                  if (_hoy.isNotEmpty)
                    Icon(
                      _abierto ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppColors.gray,
                    ),
                ],
              ),
            ),
          ),
          if (_abierto && _hoy.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 2, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: _hoy.map((x) {
                  final color = colorTipoBitacora(x.tipo);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(iconoTipoBitacora(x.tipo), size: 13, color: color),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            x.categoriaVisible,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          DateFormat('h:mm a', 'es').format(x.ocurrido),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.grayLight),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ],
    );
  }
}

class _Boton extends StatelessWidget {
  final String tipo;
  final String etiqueta;
  final VoidCallback onTap;
  const _Boton(
      {required this.tipo, required this.etiqueta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = colorTipoBitacora(tipo);
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          side: BorderSide(color: color.withValues(alpha: .5)),
          foregroundColor: color,
        ),
        child: Column(
          children: [
            Icon(iconoTipoBitacora(tipo), size: 19),
            const SizedBox(height: 3),
            Text(etiqueta,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
