import 'package:flutter/material.dart';
import '../permisos.dart';
import '../plataforma.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
import 'vigilante_screen.dart';

/// Arma la app según los permisos del perfil (ver lib/permisos.dart).
/// Si el rol tiene una sola pantalla, la muestra sin barra inferior.
class RouterScreen extends StatefulWidget {
  const RouterScreen({super.key});

  @override
  State<RouterScreen> createState() => _RouterScreenState();
}

class _Seccion {
  final String permiso;
  final String label;
  final IconData icono, iconoSel;
  final Widget pantalla;
  const _Seccion(
      this.permiso, this.label, this.icono, this.iconoSel, this.pantalla);
}

class _RouterScreenState extends State<RouterScreen> {
  int _tab = 0;

  // Orden en que aparecen las pestañas si el perfil las tiene habilitadas.
  static const _todas = [
    _Seccion(Permiso.dashboard, 'Tablero', Icons.insights_outlined,
        Icons.insights, DashboardScreen()),
    _Seccion(Permiso.expedientes, 'Expedientes', Icons.folder_outlined,
        Icons.folder, HomeScreen()),
    _Seccion(Permiso.acceso, 'Acceso', Icons.meeting_room_outlined,
        Icons.meeting_room, VigilanteScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    // En web solo se expone el tablero (ver lib/plataforma.dart).
    final visibles = _todas
        .where((s) => Permisos.puede(s.permiso))
        .where((s) => !Plataforma.soloTablero || s.permiso == Permiso.dashboard)
        .toList(growable: false);

    if (visibles.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Su perfil no tiene pantallas asignadas.\n'
              'Contacte al administrador del refugio.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Un solo permiso: pantalla completa, sin navegación inferior.
    if (visibles.length == 1) return visibles.first.pantalla;

    final idx = _tab.clamp(0, visibles.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: idx,
        children: visibles.map((s) => s.pantalla).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: visibles
            .map((s) => NavigationDestination(
                  icon: Icon(s.icono),
                  selectedIcon: Icon(s.iconoSel),
                  label: s.label,
                ))
            .toList(),
      ),
    );
  }
}
