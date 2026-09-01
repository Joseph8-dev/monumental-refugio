import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../datos.dart';
import '../models/expediente.dart';
import '../permisos.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/form_widgets.dart';
import 'expediente_detail_screen.dart';
import 'login_screen.dart';
import 'wizard/wizard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final VoidCallback _suscripcion;
  List<Expediente> _items = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _estatus = '';
  String _prioridad = '';

  /// Controla la lista para poder volver al inicio: con cientos de
  /// expedientes, desplazarse a mano hasta arriba es incómodo.
  final _scroll = ScrollController();
  bool _arriba = true;
  String _operador = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadOperador();
    _fetch();
    // Si otra pantalla escribe (detalle, wizard, acceso), recargamos.
    _suscripcion = Datos.escuchar('lista', _fetch);
    _scroll.addListener(() {
      final arriba = _scroll.offset < 300;
      if (arriba != _arriba) setState(() => _arriba = arriba);
    });
  }

  /// El operador ya no se pregunta: es el usuario que inició sesión.
  Future<void> _loadOperador() async {
    final sp = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() =>
        _operador = sp.getString('operador') ?? Permisos.etiquetaRol);
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiService.instance
          .listar(search: _search, estatus: _estatus, prioridad: _prioridad);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _onSearch(String v) {
    _search = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _fetch);
  }

  Future<void> _nuevo() async {
    final res = await Navigator.push<Expediente>(
      context,
      MaterialPageRoute(
          builder: (_) => WizardScreen(operador: _operador)),
    );
    if (res != null) {
      _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Expediente ${res.codigo} registrado')));
      }
    }
  }

  @override
  void dispose() {
    Datos.dejarDeEscuchar(_suscripcion);
    _scroll.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _irArriba() => _scroll.animateTo(0,
      duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);

  Future<void> _cerrarSesion() async {
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
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, a, __) =>
            FadeTransition(opacity: a, child: const LoginScreen()),
      ),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const AppLogo(size: 34),
        actions: [
          // Volver al inicio de la lista. Solo aparece cuando ya se
          // bajó lo suficiente como para necesitarlo.
          AnimatedOpacity(
            opacity: _arriba ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: _arriba,
              child: IconButton(
                tooltip: 'Ir al inicio de la lista',
                onPressed: _irArriba,
                icon: const Icon(Icons.arrow_upward_rounded, size: 21),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout_rounded, size: 21),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: Permisos.puede(Permiso.registrar)
          ? FloatingActionButton.extended(
        onPressed: _nuevo,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo ingreso'),
      )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: _onSearch,
              decoration: const InputDecoration(
                hintText: 'Buscar por cédula, nombre, teléfono o refugio',
                prefixIcon: Icon(Icons.search, color: AppColors.gray),
              ),
            ),
          ),
          // Filtro por prioridad de atención.
          FiltroFila(children: [
            _chipPrioridad('Toda prioridad', ''),
            ...Catalogos.prioridades.map((p) => _chipPrioridad(p, p)),
          ]),
          // Filtro por estatus del expediente.
          FiltroFila(children: [
            _chip('Todos', ''),
            ...Catalogos.estatus.map((s) => _chip(s, s)),
          ]),
          const SizedBox(height: 4),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  /// Chip de prioridad, con el color del nivel para leerlo de un vistazo.
  Widget _chipPrioridad(String label, String value) => FiltroChip(
        label: label,
        activo: _prioridad == value,
        color: value.isEmpty ? AppColors.gray : prioridadColor(value),
        icono: value.isEmpty ? null : Icons.circle,
        onTap: () {
          setState(() => _prioridad = value);
          _fetch();
        },
      );

  Widget _chip(String label, String value) => FiltroChip(
        label: label,
        activo: _estatus == value,
        onTap: () {
          setState(() => _estatus = value);
          _fetch();
        },
      );

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          key: ValueKey('loading'), child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 44, color: AppColors.grayLight),
              const SizedBox(height: 10),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.gray)),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _fetch,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        key: ValueKey('empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined,
                size: 44, color: AppColors.grayLight),
            SizedBox(height: 10),
            Text('Sin expedientes.\nRegistra el primer ingreso con el botón azul.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.gray)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      key: const ValueKey('list'),
      onRefresh: _fetch,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final e = _items[i];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 250 + (i * 40).clamp(0, 300)),
            curve: Curves.easeOutCubic,
            builder: (_, v, child) => Opacity(
              opacity: v,
              child:
                  Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExpedienteCard(
                exp: e,
                onTap: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ExpedienteDetailScreen(
                            id: e.id!, operador: _operador)),
                  );
                  if (changed == true) _fetch();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExpedienteCard extends StatelessWidget {
  final Expediente exp;
  final VoidCallback onTap;
  const _ExpedienteCard({required this.exp, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final alertas = exp.alertas;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exp.nombreResponsable.isEmpty
                          ? '(sin nombre)'
                          : exp.nombreResponsable,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  Badge2(exp.prioridad,
                      color: prioridadColor(exp.prioridad)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${exp.codigo} · ${exp.refugio} · ${exp.totalPersonas} persona${exp.totalPersonas == 1 ? '' : 's'}',
                style:
                    const TextStyle(color: AppColors.gray, fontSize: 12.5),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // El borrador se marca en ámbar: es un registro que
                  // quedó a medias y hay que volver a abrir.
                  Badge2(exp.estatus,
                      color: exp.estatus == Catalogos.estatusBorrador
                          ? AppColors.warning
                          : AppColors.blueDark),
                  const Spacer(),
                  // Un icono por alerta: niños, adulto mayor, discapacidad,
                  // etc. se distinguen sin abrir el expediente.
                  ...alertas.map((a) => Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: Tooltip(
                          message: a.texto,
                          child: Icon(
                            iconoDeAlerta(a.clase),
                            size: 16,
                            color: a.esPendiente
                                ? AppColors.warning
                                : AppColors.blue,
                          ),
                        ),
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
