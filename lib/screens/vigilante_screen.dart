import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../datos.dart';
import '../models/bitacora.dart';
import '../models/expediente.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/bitacora_form.dart';
import '../widgets/bitacora_hoy.dart';
import '../widgets/form_widgets.dart';
import 'login_screen.dart';

/// Pantalla del VIGILANTE.
/// Solo dos funciones: marcar entrada/salida del refugio y registrar
/// si el damnificado comió en desayuno, almuerzo y cena.
class VigilanteScreen extends StatefulWidget {
  const VigilanteScreen({super.key});

  @override
  State<VigilanteScreen> createState() => _VigilanteScreenState();
}

class _VigilanteScreenState extends State<VigilanteScreen> {
  late final VoidCallback _suscripcion;
  List<Expediente> _items = [];
  Map<String, dynamic> _estado = {}; // id → {dentro, desayuno, almuerzo, cena}
  bool _cargando = true;
  String? _error;
  String _q = '';
  Timer? _debounce;
  String _operador = '';

  /// Filtros de la pantalla de acceso. Se aplican sobre la lista ya
  /// cargada porque el estado de hoy (dentro/fuera, comidas) vive en
  /// memoria, no en la consulta al servidor.
  String _presencia = ''; // '' | 'dentro' | 'fuera'
  // no llamarlo _comida — ese nombre ya lo usa el método que marca
  // las comidas más abajo.
  String _filtroComida = ''; // '' | 'desayuno' | 'almuerzo' | 'cena'

  /// Volver al inicio de la lista (mismo gesto que en Expedientes).
  final _scroll = ScrollController();
  final _claveBitacora = GlobalKey<BitacoraHoyState>();
  bool _bitacoraPlegada = false;
  bool _arriba = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final sp = await SharedPreferences.getInstance();
    _operador = sp.getString('operador') ?? 'Vigilante';
    _suscripcion = Datos.escuchar('acceso', _cargar);
    _scroll.addListener(() {
      final arriba = _scroll.offset < 300;
      if (arriba != _arriba) setState(() => _arriba = arriba);

      // El bloque de bitácora se pliega al bajar, para dejarle la
      // pantalla a las familias, y solo vuelve al llegar arriba del todo.
      //
      // Depende únicamente de la posición, no de la dirección: mirando la
      // dirección el bloque aparecía y desaparecía solo, porque al soltar
      // el dedo o al rebotar la lista el gesto pasa a 'forward' un
      // instante aunque el usuario no haya subido nada.
      final plegada = _scroll.offset > 90;
      if (plegada != _bitacoraPlegada) {
        setState(() => _bitacoraPlegada = plegada);
      }
    });
    _cargar();
  }

  void _irArriba() => _scroll.animateTo(0,
      duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);

  @override
  void dispose() {
    Datos.dejarDeEscuchar(_suscripcion);
    _debounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await ApiService.instance.listar(search: _q);
      final est = await ApiService.instance.estadoHoy();
      if (!mounted) return;
      setState(() {
        _items = lista;
        _estado = est;
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

  void _buscar(String v) {
    _q = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _cargar);
  }

  Map<String, dynamic> _e(Expediente x) =>
      Map<String, dynamic>.from(_estado['${x.id}'] ?? {});

  /// Expedientes que pasan los filtros activos.
  List<Expediente> get _visibles => _items.where((x) {
        final e = _e(x);
        if (_presencia == 'dentro' && e['dentro'] != true) return false;
        if (_presencia == 'fuera' && e['dentro'] == true) return false;
        // El filtro de comida muestra a quien AÚN NO ha recibido esa
        // comida hoy: es la lista de pendientes por servir.
        if (_filtroComida.isNotEmpty && e[_filtroComida] == true) {
          return false;
        }
        return true;
      }).toList();

  Future<void> _movimiento(Expediente x, bool entrada) async {
    final prev = _estado['${x.id}'];
    setState(() {
      _estado['${x.id}'] = {..._e(x), 'dentro': entrada};
    });
    try {
      await ApiService.instance.marcarMovimiento(
          expedienteId: x.id!, tipo: entrada ? 'entrada' : 'salida');
      Datos.cambiaron(origen: 'acceso');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${entrada ? "Entrada" : "Salida"} registrada · ${x.responsable['nombres']}'),
        backgroundColor: entrada ? AppColors.ok : AppColors.gray,
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _estado['${x.id}'] = prev); // revierte
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se registró: $e'),
          backgroundColor: AppColors.danger));
    }
  }

  Future<void> _comida(Expediente x, String tipo, bool valor) async {
    final prev = _estado['${x.id}'];
    setState(() => _estado['${x.id}'] = {..._e(x), tipo: valor});
    try {
      await ApiService.instance
          .marcarComida(expedienteId: x.id!, comida: tipo, valor: valor);
      Datos.cambiaron(origen: 'acceso');
    } catch (e) {
      if (!mounted) return;
      setState(() => _estado['${x.id}'] = prev);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se registró: $e'),
          backgroundColor: AppColors.danger));
    }
  }

  /// Registra una ayuda socioeconómica para esta familia. Se abre desde
  /// su tarjeta porque la ayuda siempre tiene un destinatario concreto.
  Future<void> _ayuda(Expediente x) async {
    final ok = await mostrarFormularioBitacora(
      context,
      tipo: TipoBitacora.ayuda,
      familia: x,
    );
    if (!ok || !mounted) return;
    _claveBitacora.currentState?.cargar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Ayuda registrada para ${x.nombreResponsable}'),
      backgroundColor: AppColors.ok,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _salir() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('rf_logged_in', false);
    await ApiService.limpiarToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (r) => false,
    );
  }

  /// Usa el mismo chip que la pantalla de expedientes (FiltroChip),
  /// para que los filtros se vean igual en toda la app.
  Widget _filtro(String label, String valor, String actual,
          ValueChanged<String> onTap,
          {Color color = AppColors.blue, IconData? icono}) =>
      FiltroChip(
        label: label,
        activo: actual == valor,
        color: color,
        icono: icono,
        onTap: () => onTap(valor),
      );

  @override
  Widget build(BuildContext context) {
    final hoy = DateFormat('EEEE d MMMM', 'es').format(DateTime.now());
    final dentro = _items.where((x) => _e(x)['dentro'] == true).length;
    final visibles = _visibles;
    final filtrando = _presencia.isNotEmpty || _filtroComida.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        titleSpacing: 12,
        title: const AppLogo(size: 30),
        actions: [
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
              onPressed: _salir,
              icon: const Icon(Icons.logout_rounded, size: 21)),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Control de acceso y comidas · $hoy',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.ink)),
                // Bitácora del turno, con lo ya registrado hoy a la
                // vista para no duplicar entre turnos. Se pliega al
                // desplazarse hacia abajo.
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: _bitacoraPlegada
                      ? const SizedBox(width: double.infinity)
                      : Column(
                          children: [
                            BitacoraHoy(
                                key: _claveBitacora, onCambio: _cargar),
                            const Divider(height: 20),
                          ],
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                    'Vigilante: $_operador · $dentro dentro del refugio'
                    '${filtrando ? " · ${visibles.length} en el filtro" : ""}',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.gray)),
                const SizedBox(height: 10),
                TextField(
                  onChanged: _buscar,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por cédula, nombre, cubículo o brazalete',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                // Presencia
                FiltroFila(
                  padding: EdgeInsets.zero,
                  children: [
                      _filtro('Todos', '', _presencia,
                          (v) => setState(() => _presencia = v)),
                      _filtro('Dentro', 'dentro', _presencia,
                          (v) => setState(() => _presencia = v),
                          color: AppColors.ok, icono: Icons.login_rounded),
                      _filtro('Fuera', 'fuera', _presencia,
                          (v) => setState(() => _presencia = v),
                          color: AppColors.gray, icono: Icons.logout_rounded),
                  ],
                ),
                // Comidas pendientes
                FiltroFila(
                  padding: EdgeInsets.zero,
                  children: [
                      _filtro('Toda comida', '', _filtroComida,
                          (v) => setState(() => _filtroComida = v)),
                      _filtro('Falta desayuno', 'desayuno', _filtroComida,
                          (v) => setState(() => _filtroComida = v),
                          color: AppColors.blue,
                          icono: Icons.free_breakfast_outlined),
                      _filtro('Falta almuerzo', 'almuerzo', _filtroComida,
                          (v) => setState(() => _filtroComida = v),
                          color: AppColors.blue,
                          icono: Icons.lunch_dining_outlined),
                      _filtro('Falta cena', 'cena', _filtroComida,
                          (v) => setState(() => _filtroComida = v),
                          color: AppColors.blue,
                          icono: Icons.dinner_dining_outlined),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _Estado(
                        icon: Icons.wifi_off_rounded,
                        texto: _error!,
                        onRetry: _cargar)
                    : visibles.isEmpty
                        ? _Estado(
                            icon: Icons.person_search_outlined,
                            texto: filtrando
                                ? 'Ninguna familia cumple el filtro seleccionado'
                                : 'Sin resultados')
                        : RefreshIndicator(
                            onRefresh: _cargar,
                            child: ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                              itemCount: visibles.length,
                              itemBuilder: (_, i) {
                                final x = visibles[i];
                                final e = _e(x);
                                return _TarjetaVigilante(
                                  exp: x,
                                  dentro: e['dentro'] == true,
                                  desayuno: e['desayuno'] == true,
                                  almuerzo: e['almuerzo'] == true,
                                  cena: e['cena'] == true,
                                  onMovimiento: (v) => _movimiento(x, v),
                                  onComida: (t, v) => _comida(x, t, v),
                                  onAyuda: () => _ayuda(x),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaVigilante extends StatelessWidget {
  final Expediente exp;
  final bool dentro, desayuno, almuerzo, cena;
  final ValueChanged<bool> onMovimiento;
  final void Function(String, bool) onComida;
  final VoidCallback onAyuda;

  const _TarjetaVigilante({
    required this.exp,
    required this.dentro,
    required this.desayuno,
    required this.almuerzo,
    required this.cena,
    required this.onMovimiento,
    required this.onComida,
    required this.onAyuda,
  });

  @override
  Widget build(BuildContext context) {
    final r = exp.responsable;
    final apto = exp.censo['apto'] ?? '—';
    final brazalete = exp.censo['brazalete'] ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: dentro ? AppColors.ok.withValues(alpha: .45) : AppColors.line,
            width: dentro ? 1.4 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r['nombres'] ?? ''} ${r['apellidos'] ?? ''}'.trim(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14.5)),
                    Text(
                      'Cubículo $apto · C.I. ${r['cedula'] ?? '—'}'
                      '${brazalete == '' ? '' : ' · Braz. $brazalete'}',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.gray),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Container(
                  key: ValueKey(dentro),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: dentro
                        ? AppColors.ok.withValues(alpha: .12)
                        : AppColors.line.withValues(alpha: .6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(dentro ? 'DENTRO' : 'FUERA',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: dentro ? AppColors.ok : AppColors.gray)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: dentro ? null : () => onMovimiento(true),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ok,
                      padding: const EdgeInsets.symmetric(vertical: 10)),
                  icon: const Icon(Icons.login_rounded, size: 17),
                  label: const Text('Entrada'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: dentro ? () => onMovimiento(false) : null,
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10)),
                  icon: const Icon(Icons.logout_rounded, size: 17),
                  label: const Text('Salida'),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          const Text('Comidas de hoy',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray)),
          const SizedBox(height: 6),
          Row(
            children: [
              _Comida(
                  label: 'Desayuno',
                  icon: Icons.free_breakfast_outlined,
                  activo: desayuno,
                  onTap: () => onComida('desayuno', !desayuno)),
              const SizedBox(width: 8),
              _Comida(
                  label: 'Almuerzo',
                  icon: Icons.lunch_dining_outlined,
                  activo: almuerzo,
                  onTap: () => onComida('almuerzo', !almuerzo)),
              const SizedBox(width: 8),
              _Comida(
                  label: 'Cena',
                  icon: Icons.dinner_dining_outlined,
                  activo: cena,
                  onTap: () => onComida('cena', !cena)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAyuda,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 9),
                foregroundColor: AppColors.ok,
                side: BorderSide(color: AppColors.ok.withValues(alpha: .45)),
              ),
              icon: const Icon(Icons.volunteer_activism_outlined, size: 17),
              label: const Text('Registrar ayuda socioeconómica',
                  style: TextStyle(fontSize: 12.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Comida extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool activo;
  final VoidCallback onTap;
  const _Comida(
      {required this.label,
      required this.icon,
      required this.activo,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: activo ? AppColors.blueSoft : Colors.white,
            border: Border.all(
                color: activo ? AppColors.blue : AppColors.line,
                width: activo ? 1.5 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 19, color: activo ? AppColors.blue : AppColors.gray),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                      color: activo ? AppColors.blue : AppColors.gray)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Estado extends StatelessWidget {
  final IconData icon;
  final String texto;
  final VoidCallback? onRetry;
  const _Estado({required this.icon, required this.texto, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColors.grayLight),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(texto,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.gray)),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ],
      ),
    );
  }
}
