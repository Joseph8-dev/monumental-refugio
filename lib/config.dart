/// Configuración global de la app.
class AppConfig {
  AppConfig._();

  /// Backend Node (pm2) — mismo host que el resto del sistema.
  static const String serverApi = 'https://mlgroup.work/api/';

  /// Prefijo del módulo de refugios en el router de Express.
  static const String refugioBase = '${serverApi}refugio';

  /// Token estático opcional (authMiddleware del backend usa Bearer TOKEN).
  /// Déjalo vacío si las rutas de refugio no lo exigen.
  static const String apiToken = '';

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (apiToken.isNotEmpty) 'Authorization': 'Bearer $apiToken',
      };

  /// Nombre visible de la app (pendiente de cambio).
  static const String appName = 'Campamento Temporal Monumental';
}
