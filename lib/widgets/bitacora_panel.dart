import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../datos.dart';
import '../models/bitacora.dart';
import '../permisos.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'bitacora_form.dart';
import 'form_widgets.dart';

/// Bitácora del refugio dentro del tablero: lo que registran los
/// vigilantes en su turno, en orden cronológico.
class BitacoraPanel extends StatefulWidget {
  const BitacoraPanel({super.key});

  @override
  State<BitacoraPanel> createState() => _BitacoraPanelState();
}

class _BitacoraPanelState extends State<BitacoraPanel> {
  static const _porPagina = 25;

  List<RegistroBitacora> _items = [];
  int _total = 0;
  int _pagina = 0;
  bool _cargando = true;
  String? _error;
  String _tipo = ''; // '' = todos

  late final VoidCallback _suscripcion;

  @override
  void initState() {
    super.initState();
    _suscripcion = Datos.escuchar('bitacora', _cargar);
    _cargar();
  }

  @override
  void dispose() {
    Datos.dejarDeEscuchar(_suscripcion);
    super.dispose();
  }

  int get _paginas => _total == 0 ? 1 : ((_total - 1) ~/ _porPagina) + 1;

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await ApiService.instance.listarBitacora(
        tipo: _tipo,
        limit: _porPagina,
        offset: _pagina * _porPagina,
      );
      if (!mounted) return;
      setState(() {
        _items = r.items;
        _total = r.total;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  void _filtrar(String tipo) {
    setState(() {
      _tipo = tipo;
      _pagina = 0;
    });
    _cargar();
  }

  Future<void> _eliminar(RegistroBitacora r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text('¿Eliminar "${r.categoriaVisible}"? '
            'Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.instance.eliminarBitacora(r.id!);
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se pudo eliminar: $e'),
          backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        // El admin también puede registrar: tiene el permiso de acceso.
        if (Permisos.puede(Permiso.acceso))
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                // Solo actividad e incidencia: las ayudas se registran
                // desde la tarjeta de la familia que las recibe.
                for (final t in const [
                  TipoBitacora.actividad,
                  TipoBitacora.incidencia,
                ]) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await mostrarFormularioBitacora(context,
                            tipo: t);
                        if (ok) _cargar();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        foregroundColor: colorTipoBitacora(t),
                        side: BorderSide(
                            color: colorTipoBitacora(t).withOpacity(.5)),
                      ),
                      icon: Icon(iconoTipoBitacora(t), size: 17),
                      label: Text(
                        TipoBitacora.etiqueta(t).split(' / ').first,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  if (t != TipoBitacora.incidencia) const SizedBox(width: 8),
                ],
              ],
            ),
          ),

        // Filtros por tipo.
        Wrap(
          runSpacing: 8,
          children: [
            FiltroChip(
              label: 'Todo',
              activo: _tipo.isEmpty,
              color: AppColors.gray,
              onTap: () => _filtrar(''),
            ),
            for (final t in const [
              TipoBitacora.actividad,
              TipoBitacora.incidencia,
              TipoBitacora.ayuda,
            ])
              FiltroChip(
                label: TipoBitacora.etiqueta(t).split(' / ').first,
                activo: _tipo == t,
                color: colorTipoBitacora(t),
                icono: iconoTipoBitacora(t),
                onTap: () => _filtrar(t),
              ),
          ],
        ),
        const SizedBox(height: 14),

        if (_cargando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 50),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Column(
                children: [
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.gray)),
                  const SizedBox(height: 10),
                  OutlinedButton(
                      onPressed: _cargar, child: const Text('Reintentar')),
                ],
              ),
            ),
          )
        else if (_items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 44),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.notes_outlined,
                      size: 40, color: AppColors.grayLight),
                  SizedBox(height: 10),
                  Text('Sin registros en la bitácora',
                      style: TextStyle(color: AppColors.gray)),
                ],
              ),
            ),
          )
        else
          ..._agruparPorDia(),

        if (_paginas > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _pagina == 0
                    ? null
                    : () {
                        setState(() => _pagina--);
                        _cargar();
                      },
                icon: const Icon(Icons.chevron_left),
              ),
              Text('Página ${_pagina + 1} de $_paginas',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              IconButton(
                onPressed: _pagina >= _paginas - 1
                    ? null
                    : () {
                        setState(() => _pagina++);
                        _cargar();
                      },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Agrupa por día con encabezado, que es como se lee una bitácora.
  List<Widget> _agruparPorDia() {
    final fmtDia = DateFormat("EEEE d 'de' MMMM", 'es');
    final out = <Widget>[];
    String? diaActual;

    for (final r in _items) {
      final dia = fmtDia.format(r.ocurrido);
      if (dia != diaActual) {
        diaActual = dia;
        out.add(Padding(
          padding: EdgeInsets.only(top: out.isEmpty ? 0 : 18, bottom: 8),
          child: Text(
            dia[0].toUpperCase() + dia.substring(1),
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: .3,
                color: AppColors.blueDark),
          ),
        ));
      }
      out.add(_Tarjeta(
        registro: r,
        onEliminar: Permisos.puede(Permiso.administrar) && r.id != null
            ? () => _eliminar(r)
            : null,
      ));
    }
    return out;
  }
}

class _Tarjeta extends StatelessWidget {
  final RegistroBitacora registro;
  final VoidCallback? onEliminar;
  const _Tarjeta({required this.registro, this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final r = registro;
    final color = colorTipoBitacora(r.tipo);
    final hora = DateFormat('h:mm a', 'es').format(r.ocurrido);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            margin: const EdgeInsets.only(right: 11),
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(iconoTipoBitacora(r.tipo), size: 17, color: color),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(r.categoriaVisible,
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ),
                    Text(hora,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.gray)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(r.descripcion, style: const TextStyle(fontSize: 13)),
                if ((r.observacion ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Obs.: ${r.observacion}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.gray)),
                ],
                if (r.familia != null) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.family_restroom_outlined,
                          size: 13, color: AppColors.gray),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${r.familia}'
                          '${r.apto == null ? '' : ' · Cubículo ${r.apto}'}',
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.gray),
                        ),
                      ),
                    ],
                  ),
                ],
                if ((r.operador ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Registró: ${r.operador}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.grayLight)),
                ],
              ],
            ),
          ),
          if (onEliminar != null)
            IconButton(
              onPressed: onEliminar,
              iconSize: 17,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline, color: AppColors.grayLight),
            ),
        ],
      ),
    );
  }
}
