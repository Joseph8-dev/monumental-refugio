import 'dart:convert';
import 'package:flutter/material.dart';
import '../datos.dart';
import '../models/expediente.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'ficha.dart';
import 'form_widgets.dart';

/// Tabla de familias con paginación, para el tablero web.
/// En el teléfono el listado completo vive en su propia pantalla; en el
/// navegador no hay pestañas, así que el tablero necesita poder recorrer
/// todas las familias sin traerlas de golpe: se piden de a 10 al servidor.
/// Filtro de patología compartido con el tablero: al tocar una barra de
/// "Patologías" se escribe aquí y la tabla se recarga sola. Un notifier
/// en vez de pasarlo por constructor porque el widget que lo enciende
/// está en otra rama del árbol.
final ValueNotifier<String> filtroPatologia = ValueNotifier<String>('');

class TablaFamilias extends StatefulWidget {
  const TablaFamilias({super.key});

  @override
  State<TablaFamilias> createState() => _TablaFamiliasState();
}

class _TablaFamiliasState extends State<TablaFamilias> {
  static const _porPagina = 10;

  List<Expediente> _items = [];
  int _total = 0;
  int _pagina = 0;
  bool _cargando = true;
  String? _error;
  String _busqueda = '';
  // Con controlador para poder vaciar el campo desde "Quitar filtros";
  // sin él, el texto seguiría en pantalla aunque el filtro ya no aplique.
  final _campoBusqueda = TextEditingController();
  String _prioridad = ''; // '' = todas

  late final VoidCallback _suscripcion;

  @override
  void initState() {
    super.initState();
    _suscripcion = Datos.escuchar('tablero', _cargar);
    filtroPatologia.addListener(_porPatologia);
    _cargar();
  }

  @override
  void dispose() {
    Datos.dejarDeEscuchar(_suscripcion);
    filtroPatologia.removeListener(_porPatologia);
    _campoBusqueda.dispose();
    super.dispose();
  }

  void _porPatologia() {
    setState(() => _pagina = 0);
    _cargar();
  }

  int get _paginas => _total == 0 ? 1 : ((_total - 1) ~/ _porPagina) + 1;

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await ApiService.instance.listarPagina(
        search: _busqueda,
        prioridad: _prioridad,
        patologia: filtroPatologia.value,
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

  void _irA(int pagina) {
    if (pagina < 0 || pagina >= _paginas) return;
    setState(() => _pagina = pagina);
    _cargar();
  }

  void _buscar(String v) {
    _busqueda = v;
    _pagina = 0; // una búsqueda nueva empieza en la primera página
    _cargar();
  }

  /// Cualquier cambio de filtro vuelve a la primera página: si estabas en
  /// la 5 y el filtro deja 2 páginas, quedarías viendo una lista vacía.
  void _filtrar(void Function() aplicar) {
    setState(aplicar);
    _pagina = 0;
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final desde = _total == 0 ? 0 : _pagina * _porPagina + 1;
    final hasta = (_pagina * _porPagina + _items.length);

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
          Row(
            children: [
              const Expanded(
                child: Text('Familias registradas',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              if (_total > 0)
                Text(
                  // Deja claro si el total responde a un filtro activo.
                  _prioridad.isEmpty &&
                          _busqueda.isEmpty &&
                          filtroPatologia.value.isEmpty
                      ? '$desde–$hasta de $_total'
                      : '$desde–$hasta de $_total filtradas',
                  style: const TextStyle(fontSize: 12, color: AppColors.gray),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _campoBusqueda,
            onSubmitted: _buscar,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, cédula, cubículo o brazalete',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward, size: 18),
                onPressed: () => _buscar(_busqueda),
              ),
            ),
            onChanged: (v) => _busqueda = v,
          ),
          const SizedBox(height: 10),

          // Filtro por nivel de urgencia.
          // Wrap y no una lista horizontal: en el navegador una fila con
          // desplazamiento lateral no se arrastra con el ratón y los
          // chips que no caben quedan inalcanzables.
          Wrap(
            spacing: 0,
            runSpacing: 8,
            children: [
              FiltroChip(
                label: 'Toda urgencia',
                activo: _prioridad.isEmpty,
                color: AppColors.gray,
                onTap: () => _filtrar(() => _prioridad = ''),
              ),
              ...Catalogos.prioridades.map((pr) => FiltroChip(
                    label: pr,
                    activo: _prioridad == pr,
                    color: prioridadColor(pr),
                    icono: Icons.circle,
                    onTap: () => _filtrar(() => _prioridad = pr),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Filtro llegado desde el tablero de patologías.
          if (filtroPatologia.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: .4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medical_services_outlined,
                        size: 17, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mostrando familias con: ${filtroPatologia.value}',
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning),
                      ),
                    ),
                    InkWell(
                      onTap: () => filtroPatologia.value = '',
                      child: const Icon(Icons.close,
                          size: 17, color: AppColors.warning),
                    ),
                  ],
                ),
              ),
            ),

          if (_cargando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    const Text('Sin resultados',
                        style: TextStyle(color: AppColors.gray)),
                    if (_prioridad.isNotEmpty ||
                        _busqueda.isNotEmpty ||
                        filtroPatologia.value.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _filtrar(() {
                          _prioridad = '';
                          _busqueda = '';
                          _campoBusqueda.clear();
                          filtroPatologia.value = '';
                        }),
                        icon: const Icon(Icons.filter_alt_off_outlined,
                            size: 17),
                        label: const Text('Quitar filtros'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            ..._items.map((e) => _Fila(
                  exp: e,
                  onTap: () => mostrarFichaExpediente(context, e),
                )),

          if (_paginas > 1) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Primera página',
                  onPressed: _pagina == 0 ? null : () => _irA(0),
                  icon: const Icon(Icons.first_page, size: 20),
                ),
                IconButton(
                  tooltip: 'Anterior',
                  onPressed: _pagina == 0 ? null : () => _irA(_pagina - 1),
                  icon: const Icon(Icons.chevron_left, size: 22),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Página ${_pagina + 1} de $_paginas',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  tooltip: 'Siguiente',
                  onPressed:
                      _pagina >= _paginas - 1 ? null : () => _irA(_pagina + 1),
                  icon: const Icon(Icons.chevron_right, size: 22),
                ),
                IconButton(
                  tooltip: 'Última página',
                  onPressed: _pagina >= _paginas - 1
                      ? null
                      : () => _irA(_paginas - 1),
                  icon: const Icon(Icons.last_page, size: 20),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Fila extends StatefulWidget {
  final Expediente exp;
  final VoidCallback onTap;
  const _Fila({required this.exp, required this.onTap});

  @override
  State<_Fila> createState() => _FilaState();
}

class _FilaState extends State<_Fila> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.exp;
    final color = prioridadColor(e.prioridad);
    final alertas = e.alertas;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: _hover ? AppColors.blueSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          // En pantalla ancha va todo en una fila con columnas; en el
          // teléfono no cabe (el nombre se corta y el cubículo se parte
          // en vertical), así que se apila en dos líneas.
          child: LayoutBuilder(
            builder: (context, c) => c.maxWidth < 560
                ? _compacta(e, color, alertas)
                : _amplia(e, color, alertas),
          ),
        ),
      ),
    );
  }

  /// Teléfono: nombre arriba, datos y alertas debajo.
  Widget _compacta(Expediente e, Color color, List<Alerta> alertas) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 44,
          margin: const EdgeInsets.only(right: 10, top: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      e.nombreResponsable.isEmpty
                          ? e.codigo
                          : e.nombreResponsable,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(e.prioridad,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                [
                  'Cubículo ${e.censo['apto'] ?? '—'}',
                  '${e.totalPersonas} pers.',
                  if ((e.responsable['cedula'] ?? '').toString().isNotEmpty)
                    '${e.responsable['cedula']}',
                ].join('  ·  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: AppColors.gray),
              ),
              if (alertas.isNotEmpty) ...[
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  children: alertas
                      .take(6)
                      .map((a) => Icon(iconoDeAlerta(a.clase),
                          size: 14,
                          color: a.esPendiente
                              ? AppColors.warning
                              : AppColors.blue))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 6, top: 2),
          child: Icon(Icons.chevron_right, size: 18, color: AppColors.grayLight),
        ),
      ],
    );
  }

  /// Escritorio: columnas alineadas, como una tabla.
  Widget _amplia(Expediente e, Color color, List<Alerta> alertas) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 34,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.nombreResponsable.isEmpty ? e.codigo : e.nombreResponsable,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              Text(e.responsable['cedula']?.toString() ?? '—',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.gray)),
            ],
          ),
        ),
        Expanded(
          child: Text('${e.censo['apto'] ?? '—'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5)),
        ),
        Expanded(
          child: Text('${e.totalPersonas} pers.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5)),
        ),
        SizedBox(
          width: 92,
          child: Wrap(
            spacing: 4,
            children: alertas
                .take(4)
                .map((a) => Icon(iconoDeAlerta(a.clase),
                    size: 14,
                    color:
                        a.esPendiente ? AppColors.warning : AppColors.blue))
                .toList(),
          ),
        ),
        SizedBox(
          width: 78,
          child: Text(e.prioridad,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ),
        const Icon(Icons.open_in_new, size: 15, color: AppColors.grayLight),
      ],
    );
  }
}

/// Ventana emergente con la ficha completa del expediente.
/// Usa las mismas secciones que la pantalla de detalle del teléfono.
Future<void> mostrarFichaExpediente(BuildContext context, Expediente e) {
  final secciones = fichaCompleta(e);
  final cedula = (e.responsable['documento_imagen'] ?? '').toString();
  final familia = (e.censo['foto_familia'] ?? '').toString();

  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.nombreResponsable.isEmpty
                              ? e.codigo
                              : e.nombreResponsable,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${e.codigo} · Cubículo ${e.censo['apto'] ?? '—'} · '
                          '${e.totalPersonas} persona'
                          '${e.totalPersonas == 1 ? '' : 's'}',
                          style: const TextStyle(
                              color: Color(0xFFCBD5E1), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Badge2(e.estatus,
                          color: e.estatus == Catalogos.estatusBorrador
                              ? AppColors.warning
                              : AppColors.blueDark),
                      Badge2(e.prioridad,
                          color: prioridadColor(e.prioridad)),
                      ...e.alertas.map((a) => AlertaChip(a)),
                    ],
                  ),
                  if (cedula.isNotEmpty || familia.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cedula.isNotEmpty)
                          Expanded(child: _FotoDialogo(b64: cedula, titulo: 'Cédula')),
                        if (cedula.isNotEmpty && familia.isNotEmpty)
                          const SizedBox(width: 12),
                        if (familia.isNotEmpty)
                          Expanded(
                              child: _FotoDialogo(
                                  b64: familia, titulo: 'Grupo familiar')),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  ...secciones.map((s) => Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.$1.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .6,
                                    color: AppColors.blue)),
                            const SizedBox(height: 6),
                            ...s.$2.map((linea) => Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Text(linea,
                                      style: const TextStyle(fontSize: 13)),
                                )),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FotoDialogo extends StatelessWidget {
  final String b64, titulo;
  const _FotoDialogo({required this.b64, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(base64Decode(b64),
              height: 150, width: double.infinity, fit: BoxFit.cover),
        ),
        const SizedBox(height: 4),
        Text(titulo,
            style: const TextStyle(fontSize: 11, color: AppColors.gray)),
      ],
    );
  }
}
