import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../datos.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/reportes_card.dart';
import '../widgets/bitacora_panel.dart';
import '../widgets/tabla_familias.dart';
import 'login_screen.dart';

/// Tablero administrativo del Campamento Temporal Monumental.
/// Métricas: total de damnificados, urgencia, tenencia de vivienda,
/// patologías, ocupación por cubículo y comidas del día.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late final VoidCallback _suscripcion;
  Map<String, dynamic>? _m;
  bool _cargando = true;
  String? _error;

  late final AnimationController _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  late final TabController _tabs = TabController(length: 2, vsync: this);

  // Para poder bajar hasta la lista de familias al tocar una patología.
  final _scroll = ScrollController();
  final _claveFamilias = GlobalKey();
  int _intentoScroll = 0;
  bool _scrollLogrado = false;

  @override
  void initState() {
    super.initState();
    // El tablero vive dentro de un IndexedStack: no se reconstruye al
    // cambiar de pestaña, así que necesita escuchar los cambios.
    _suscripcion = Datos.escuchar('tablero', _cargar);
    // Las barras marcan la patología activa, así que tienen que
    // redibujarse también cuando el filtro se quita desde la tabla.
    Datos.filtroPatologia.addListener(_alCambiarFiltro);
    _cargar();
  }

  @override
  void dispose() {
    Datos.dejarDeEscuchar(_suscripcion);
    Datos.filtroPatologia.removeListener(_alCambiarFiltro);
    _tabs.dispose();
    _scroll.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final m = await ApiService.instance.metricas();
      if (!mounted) return;
      setState(() {
        _m = m;
        _cargando = false;
      });
      _anim.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  int _i(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;

  void _alCambiarFiltro() {
    if (mounted) setState(() {});
  }

  /// Lleva la vista hasta la lista de familias, para que al tocar una
  /// patología se vea de una vez a quiénes corresponde.
  /// Lleva la vista hasta la tabla de familias.
  ///
  /// Se intenta varias veces porque al tocar una patología la tabla pide
  /// los datos al servidor: en el primer intento todavía no existe —la
  /// lista construye por partes— y su altura cambia cuando llegan las
  /// filas, así que un solo desplazamiento se queda corto.
  void _irAFamilias() {
    // Identifica esta petición: si el usuario toca otra patología, los
    // intentos pendientes de la anterior se descartan.
    final intento = ++_intentoScroll;

    for (final ms in const [60, 350, 800, 1400]) {
      Future.delayed(Duration(milliseconds: ms), () {
        if (!mounted || !_scroll.hasClients) return;
        if (intento != _intentoScroll || _scrollLogrado) return;

        final ctx = _claveFamilias.currentContext;
        if (ctx != null) {
          _scrollLogrado = true;
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            alignment: 0.02,
          );
          return;
        }

        // Aún no construida: la tabla es el último bloque, así que
        // bajar del todo la deja en pantalla.
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  Future<void> _salir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir de la aplicación?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salir')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('rf_logged_in', false);
    await ApiService.limpiarToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mismo umbral que el layout de dos columnas.
    final ancho = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        titleSpacing: ancho ? 28 : 12,
        // En monitor la barra de 56 px con el logo a 30 se veía diminuta:
        // en pantalla grande crece para que el logo se lea de verdad.
        toolbarHeight: ancho ? 82 : 56,
        title: AppLogo(size: ancho ? 50 : 30),
        actions: [
          IconButton(
              onPressed: _cargar,
              tooltip: 'Actualizar',
              iconSize: ancho ? 26 : 21,
              icon: const Icon(Icons.refresh_rounded)),
          IconButton(
              onPressed: _salir,
              tooltip: 'Cerrar sesión',
              iconSize: ancho ? 26 : 21,
              icon: const Icon(Icons.logout_rounded)),
          SizedBox(width: ancho ? 20 : 4),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.blue,
          unselectedLabelColor: AppColors.gray,
          indicatorColor: AppColors.blue,
          labelStyle: const TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.insights_outlined, size: 19), text: 'Resumen'),
            Tab(icon: Icon(Icons.notes_outlined, size: 19), text: 'Bitácora'),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 44, color: AppColors.grayLight),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.gray)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                          onPressed: _cargar, child: const Text('Reintentar')),
                      const SizedBox(height: 6),
                      TextButton(
                          onPressed: _salir,
                          child: const Text('Volver al inicio de sesión')),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabs,
                  children: [
                    RefreshIndicator(
                      onRefresh: _cargar,
                      child: _contenido(),
                    ),
                    const BitacoraPanel(),
                  ],
                ),
    );
  }

  Widget _contenido() {
    final m = _m!;
    final total = _i(m['total_expedientes']);
    final personas = _i(m['total_personas']);
    final dentro = _i(m['dentro_ahora']);
    final capacidad = _i(m['capacidad']) == 0 ? 1000 : _i(m['capacidad']);
    final comidas = Map<String, dynamic>.from(m['comidas_hoy'] ?? {});

    // Bloques del tablero. Se arman una vez y el layout decide si van en
    // una columna (teléfono) o en dos (navegador ancho): en escritorio,
    // una sola columna centrada dejaba media pantalla vacía a los lados.
    final bloques = <Widget>[
        // Ocupación general
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ocupación del refugio',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$personas',
                      style: const TextStyle(
                          fontSize: 40,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy)),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text('personas · referencia $capacidad',
                        style: const TextStyle(color: AppColors.gray)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    // La capacidad es una REFERENCIA de planificación, no un
                    // tope: si se supera, la barra se llena y cambia de color
                    // en vez de bloquear o mostrar un dato falso.
                    value: (personas / capacidad).clamp(0.0, 1.0) * _anim.value,
                    minHeight: 10,
                    backgroundColor: AppColors.line,
                    color: personas > capacidad
                        ? AppColors.warning
                        : AppColors.navy,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$total familias registradas · $dentro personas dentro ahora',
                style: const TextStyle(fontSize: 12, color: AppColors.gray),
              ),
              const SizedBox(height: 2),
              Text(
                personas > capacidad
                    ? '${personas - capacidad} sobre la referencia de $capacidad '
                        '· la capacidad es orientativa, no limita el registro'
                    : '${(personas / capacidad * 100).toStringAsFixed(0)}% de la '
                        'capacidad de referencia',
                style: TextStyle(
                    fontSize: 11.5,
                    color: personas > capacidad
                        ? AppColors.warning
                        : AppColors.grayLight,
                    fontWeight: personas > capacidad
                        ? FontWeight.w600
                        : FontWeight.w400),
              ),
            ],
          ),
        ),

        // Tarjetas rápidas
        Row(
          children: [
            _Mini(
                label: 'Familias',
                valor: '$total',
                icon: Icons.family_restroom_outlined,
                color: AppColors.blue),
            const SizedBox(width: 10),
            _Mini(
                label: 'Personas',
                valor: '$personas',
                icon: Icons.groups_outlined,
                color: AppColors.navy),
          ],
        ),
        Row(
          children: [
            _Mini(
                label: 'Urgentes',
                valor: '${_i((m['prioridad'] ?? {})['Urgente'])}',
                icon: Icons.priority_high_rounded,
                color: AppColors.danger),
            const SizedBox(width: 10),
            _Mini(
                label: 'Dentro ahora',
                valor: '$dentro',
                icon: Icons.meeting_room_outlined,
                color: AppColors.ok),
          ],
        ),

        _Barras(
          titulo: 'Clasificación por nivel de urgencia',
          datos: Map<String, dynamic>.from(m['prioridad'] ?? {}),
          colores: const {
            'Urgente': AppColors.danger,
            'Alta': AppColors.warning,
            'Normal': AppColors.ok,
          },
          anim: _anim,
        ),

        _Barras(
          titulo: 'Condición de la vivienda antes del terremoto',
          datos: Map<String, dynamic>.from(m['vivienda'] ?? {}),
          anim: _anim,
        ),

        _Barras(
          titulo: 'Patologías y condiciones de salud',
          datos: Map<String, dynamic>.from(m['patologias'] ?? {}),
          anim: _anim,
          // Al tocar una patología se filtra la lista de familias y se
          // baja hasta ella: el admin pasa del número a los nombres sin
          // tener que buscarlos.
          onTocar: (etiqueta) {
            Datos.filtroPatologia.value =
                Datos.filtroPatologia.value == etiqueta ? '' : etiqueta;
            _scrollLogrado = false;
            _irAFamilias();
          },
        ),

        // Comidas de hoy
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Comidas servidas hoy',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Comida('Desayuno', _i(comidas['desayuno']), personas),
                  _Comida('Almuerzo', _i(comidas['almuerzo']), personas),
                  _Comida('Cena', _i(comidas['cena']), personas),
                ],
              ),
            ],
          ),
        ),

        const ReportesCard(),

        // Familias registradas: tabla paginada con ficha emergente, igual
        // de 30 sin filtros, y al tocar una patología no había a dónde
        // llevar al usuario.
        // Nunca se envían fotos aquí: en base64 harían crecer la
        // respuesta a decenas de MB con cientos de expedientes.
        TablaFamilias(key: _claveFamilias),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        // A partir de ~980 px caben dos columnas cómodas.
        final dosColumnas = c.maxWidth >= 980;
        if (!dosColumnas) {
          return ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: bloques
                .map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: b,
                    ))
                .toList(),
          );
        }

        // Reparto en dos columnas alternando bloques, para que ninguna
        // quede mucho más larga que la otra.
        final izq = <Widget>[];
        final der = <Widget>[];
        for (var i = 0; i < bloques.length; i++) {
          (i.isEven ? izq : der).add(Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: bloques[i],
          ));
        }

        return SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
          child: Center(
            child: ConstrainedBox(
              // Tope generoso: aprovecha el monitor sin que las líneas
              // de texto se vuelvan interminables.
              constraints: const BoxConstraints(maxWidth: 1500),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(children: izq)),
                  const SizedBox(width: 18),
                  Expanded(child: Column(children: der)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: child,
      );
}

class _Mini extends StatelessWidget {
  final String label, valor;
  final IconData icon;
  final Color color;
  const _Mini(
      {required this.label,
      required this.valor,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(valor,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.gray)),
          ],
        ),
      ),
    );
  }
}

/// Barras horizontales animadas (sin dependencias de gráficos).
class _Barras extends StatelessWidget {
  final String titulo;
  final Map<String, dynamic> datos;
  final Map<String, Color> colores;
  final Animation<double> anim;

  /// Si se indica, cada barra se vuelve tocable y devuelve su etiqueta.
  final void Function(String)? onTocar;

  const _Barras(
      {required this.titulo,
      required this.datos,
      required this.anim,
      this.colores = const {},
      this.onTocar});

  @override
  Widget build(BuildContext context) {
    final entradas = datos.entries
        .map((e) => MapEntry(e.key, e.value is int ? e.value as int : 0))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entradas.isEmpty) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 8),
            const Text('Sin datos registrados',
                style: TextStyle(fontSize: 12, color: AppColors.grayLight)),
          ],
        ),
      );
    }

    final max = entradas.first.value;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 12),
          if (onTocar != null)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Toque una condición para ver esas familias',
                  style: TextStyle(fontSize: 11, color: AppColors.grayLight)),
            ),
          ...entradas.map((e) {
            final color = colores[e.key] ?? AppColors.blue;
            final seleccionada = Datos.filtroPatologia.value == e.key;
            final fila = Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(e.key,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5)),
                      ),
                      Text('${e.value}',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: anim,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: (e.value / max) * anim.value,
                        minHeight: 7,
                        backgroundColor: AppColors.line,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (onTocar == null) return fila;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onTocar!(e.key),
                child: Container(
                  decoration: BoxDecoration(
                    color: seleccionada
                        ? AppColors.warning.withValues(alpha: .10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  child: fila,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Comida extends StatelessWidget {
  final String label;
  final int valor, total;
  const _Comida(this.label, this.valor, this.total);

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (valor / total).clamp(0.0, 1.0);
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 58,
            width: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 58,
                  width: 58,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 6,
                    backgroundColor: AppColors.line,
                    color: AppColors.skyDeep,
                  ),
                ),
                Text('$valor',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontSize: 11.5, color: AppColors.gray)),
        ],
      ),
    );
  }
}
