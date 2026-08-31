import 'services/api_service.dart';

/// ═══════════════════════════════════════════════════════════
/// PERMISOS · único lugar para prender/apagar pantallas por perfil
///
/// Para cambiar qué ve cada rol, edita SOLO el mapa `matriz` de abajo:
/// agrega o quita una constante de la lista del rol. Nada más hay que
/// tocar — la barra de navegación, el botón de "nuevo ingreso" y la
/// pantalla inicial se arman solos a partir de esta matriz.
///
/// El servidor tiene la MISMA matriz (backend/permisos.js). La de aquí
/// controla lo que se ve; la del servidor controla lo que se permite.
/// Si cambias una, cambia la otra.
/// ═══════════════════════════════════════════════════════════
class Permiso {
  /// Tablero de reportes y métricas.
  static const dashboard = 'dashboard';

  /// Ver la lista de expedientes y abrir el detalle.
  static const expedientes = 'expedientes';

  /// Registrar y editar damnificados (asistente de ingreso).
  static const registrar = 'registrar';

  /// Marcar entrada/salida y comidas.
  static const acceso = 'acceso';

  /// Cambiar el estatus de un expediente y eliminarlo.
  static const administrar = 'administrar';
}

class Permisos {
  Permisos._();

  /// 🔧 MATRIZ EDITABLE — qué puede hacer cada perfil.
  static const Map<String, List<String>> matriz = {
    // Administrador: todo.
    'admin': [
      Permiso.dashboard,
      Permiso.expedientes,
      Permiso.registrar,
      Permiso.acceso,
      Permiso.administrar,
    ],

    // Recolector de datos: solo registrar damnificados.
    'recolector': [
      Permiso.expedientes,
      Permiso.registrar,
    ],

    // Vigilante: solo marcar entrada/salida y comidas.
    'vigilante': [
      Permiso.acceso,
    ],
  };

  static List<String> get _mios => matriz[ApiService.rol] ?? const [];

  /// ¿El usuario en sesión tiene este permiso?
  static bool puede(String permiso) => _mios.contains(permiso);

  static bool get esAdmin => ApiService.rol == 'admin';

  /// Nombre legible del perfil (para la cabecera).
  static String get etiquetaRol {
    switch (ApiService.rol) {
      case 'admin':
        return 'Administrador';
      case 'vigilante':
        return 'Vigilante';
      case 'recolector':
        return 'Recolector de datos';
      default:
        return ApiService.rol;
    }
  }
}
