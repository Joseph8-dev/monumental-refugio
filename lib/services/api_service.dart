import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/expediente.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// CRUD contra el backend Node (Express + PostgreSQL).
///
/// Endpoints esperados (ver backend/refugio_routes.js incluido):
///   GET    /api/refugio/expedientes?search=&estatus=
///   GET    /api/refugio/expedientes/:id
///   POST   /api/refugio/expedientes
///   PUT    /api/refugio/expedientes/:id
///   POST   /api/refugio/expedientes/:id/delete   (borrado lógico)
class ApiService {
  ApiService._();
  static final instance = ApiService._();

  static const _timeout = Duration(seconds: 20);

  /// Token de sesión (JWT emitido por /refugio/login). Se envía como Bearer
  /// en todas las peticiones. El secreto de firma vive solo en el servidor.
  static String token = '';

  /// Rol del usuario en sesión: 'admin' | 'recolector' | 'vigilante'.
  static String rol = 'recolector';

  static Future<void> cargarToken() async {
    final sp = await SharedPreferences.getInstance();
    token = sp.getString('rf_token') ?? '';
    rol = sp.getString('rf_rol') ?? 'recolector';
  }

  static Future<void> limpiarToken() async {
    token = '';
    rol = 'recolector';
    final sp = await SharedPreferences.getInstance();
    await sp.remove('rf_token');
    await sp.remove('rf_rol');
  }

  Map<String, String> get _h => {
        ...AppConfig.headers,
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse('${AppConfig.refugioBase}$path')
          .replace(queryParameters: q?.isEmpty == true ? null : q);

  /// Login contra el backend. Si las credenciales son válidas, guarda el
  /// token de sesión (JWT) y devuelve el nombre visible del usuario.
  Future<String> login(String usuario, String clave) async {
    final res = await http
        .post(_u('/login'),
            headers: AppConfig.headers,
            body: jsonEncode({'usuario': usuario.trim(), 'clave': clave}))
        .timeout(_timeout);
    final body = _ok(res);
    final data = body['data'];
    if (data is Map && (data['token'] ?? '') != '') {
      token = data['token'].toString();
      final sp = await SharedPreferences.getInstance();
      await sp.setString('rf_token', token);
    }
    if (data is Map && (data['rol'] ?? '') != '') {
      rol = data['rol'].toString();
      final sp = await SharedPreferences.getInstance();
      await sp.setString('rf_rol', rol);
    }
    if (data is Map && data['nombre'] != null) return data['nombre'].toString();
    return usuario.trim();
  }

  // ── Vigilancia: acceso y comidas ──────────────────────────

  /// Estado de hoy por expediente: {id: {dentro, desayuno, almuerzo, cena}}
  Future<Map<String, dynamic>> estadoHoy() async {
    final res =
        await http.get(_u('/estado-hoy'), headers: _h).timeout(_timeout);
    final body = _ok(res);
    return Map<String, dynamic>.from(body['data'] ?? {});
  }

  Future<void> marcarMovimiento(
      {required int expedienteId, required String tipo}) async {
    final res = await http
        .post(_u('/movimientos'),
            headers: _h,
            body: jsonEncode({'expediente_id': expedienteId, 'tipo': tipo}))
        .timeout(_timeout);
    _ok(res);
  }

  Future<void> marcarComida(
      {required int expedienteId,
      required String comida,
      required bool valor}) async {
    final res = await http
        .post(_u('/comidas'),
            headers: _h,
            body: jsonEncode({
              'expediente_id': expedienteId,
              'comida': comida,
              'valor': valor,
            }))
        .timeout(_timeout);
    _ok(res);
  }

  /// Encola un reporte en el servidor. El destino sale del .env del
  /// servidor, no de la app.
  /// tipo: 'resumen' | 'censo' | 'comidas'
  Future<String> enviarReporte({
    required String tipo,
    required DateTime desde,
    required DateTime hasta,
  }) async {
    String d(DateTime x) =>
        '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
    final res = await http
        .post(_u('/reportes/enviar'),
            headers: _h,
            body: jsonEncode({
              'tipo': tipo,
              'desde': d(desde),
              'hasta': d(hasta),
            }))
        .timeout(_timeout);
    final body = _ok(res);
    return (body['message'] ?? 'Reporte encolado.').toString();
  }

  /// Métricas agregadas para el tablero administrativo.
  Future<Map<String, dynamic>> metricas() async {
    final res =
        await http.get(_u('/metricas'), headers: _h).timeout(_timeout);
    final body = _ok(res);
    return Map<String, dynamic>.from(body['data'] ?? {});
  }

  /// Lista de refugios disponibles (GET /refugio/refugios). El servidor
  /// devuelve los refugios activos de la tabla rf_refugios + 'Otros'.
  Future<List<String>> refugios() async {
    final res =
        await http.get(_u('/refugios'), headers: _h).timeout(_timeout);
    final body = _ok(res);
    return (body['data'] as List?)?.map((e) => '$e').toList() ?? [];
  }

  /// Página de expedientes: los datos más el total sin paginar, que el
  /// tablero web necesita para saber cuántas páginas hay.
  Future<({List<Expediente> items, int total})> listarPagina({
    String search = '',
    String estatus = '',
    String prioridad = '',
    int limit = 10,
    int offset = 0,
  }) async {
    final q = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
    };
    if (search.trim().isNotEmpty) q['search'] = search.trim();
    if (estatus.isNotEmpty) q['estatus'] = estatus;
    if (prioridad.isNotEmpty) q['prioridad'] = prioridad;

    final res =
        await http.get(_u('/expedientes', q), headers: _h).timeout(_timeout);
    final body = _ok(res);
    final data = (body['data'] as List? ?? [])
        .map((e) => Expediente.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final total = body['total'] is int
        ? body['total'] as int
        : int.tryParse('${body['total'] ?? data.length}') ?? data.length;
    return (items: data, total: total);
  }

  Future<List<Expediente>> listar(
      {String search = '', String estatus = '', String prioridad = ''}) async {
    final q = <String, String>{};
    if (search.trim().isNotEmpty) q['search'] = search.trim();
    if (estatus.isNotEmpty) q['estatus'] = estatus;
    if (prioridad.isNotEmpty) q['prioridad'] = prioridad;

    final res = await http
        .get(_u('/expedientes', q), headers: _h)
        .timeout(_timeout);
    final body = _ok(res);
    final data = (body['data'] as List? ?? []);
    return data
        .map((e) => Expediente.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Expediente> obtener(int id) async {
    final res = await http
        .get(_u('/expedientes/$id'), headers: _h)
        .timeout(_timeout);
    final body = _ok(res);
    return Expediente.fromJson(Map<String, dynamic>.from(body['data']));
  }

  Future<Expediente> crear(Expediente e) async {
    final res = await http
        .post(_u('/expedientes'),
            headers: _h, body: jsonEncode(e.toJson()))
        .timeout(_timeout);
    final body = _ok(res);
    return Expediente.fromJson(Map<String, dynamic>.from(body['data']));
  }

  Future<Expediente> actualizar(Expediente e) async {
    if (e.id == null) throw ApiException('Expediente sin ID');
    final res = await http
        .put(_u('/expedientes/${e.id}'),
            headers: _h, body: jsonEncode(e.toJson()))
        .timeout(_timeout);
    final body = _ok(res);
    return Expediente.fromJson(Map<String, dynamic>.from(body['data']));
  }

  Future<void> eliminar(int id) async {
    final res = await http
        .post(_u('/expedientes/$id/delete'), headers: _h)
        .timeout(_timeout);
    _ok(res);
  }

  Map<String, dynamic> _ok(http.Response res) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Respuesta inválida del servidor (${res.statusCode})');
    }
    if (res.statusCode == 401) {
      throw ApiException(
          body['message']?.toString() ??
              'Sesion expirada. Cierre sesion y vuelva a entrar.');
    }
    if (res.statusCode >= 200 &&
        res.statusCode < 300 &&
        body['success'] != false) {
      return body;
    }
    throw ApiException(
        body['message']?.toString() ?? 'Error del servidor (${res.statusCode})');
  }
}
