import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../plataforma.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import 'router_screen.dart';

/// Pantalla de acceso. Credenciales validadas en el servidor
/// (POST /api/refugio/login). Guarda la sesión en SharedPreferences.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  final _claveFocus = FocusNode();

  bool _cargando = false;
  bool _verClave = false;
  String? _error;

  // Entrada escalonada (logo → campos → botón).
  late final AnimationController _intro = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..forward();

  // Sacudida horizontal cuando falla el login.
  late final AnimationController _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void dispose() {
    _usuario.dispose();
    _clave.dispose();
    _claveFocus.dispose();
    _intro.dispose();
    _shake.dispose();
    super.dispose();
  }

  Animation<double> _fadeAt(double start) => CurvedAnimation(
      parent: _intro, curve: Interval(start, 1, curve: Curves.easeOut));

  Animation<Offset> _slideAt(double start) =>
      Tween(begin: const Offset(0, .18), end: Offset.zero).animate(
          CurvedAnimation(
              parent: _intro,
              curve: Interval(start, 1, curve: Curves.easeOutCubic)));

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    final u = _usuario.text.trim();
    final c = _clave.text;
    if (u.isEmpty || c.isEmpty) {
      setState(() => _error = 'Ingresa usuario y clave');
      _shake.forward(from: 0);
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final nombre = await ApiService.instance.login(u, c);

      // Comprobación secundaria: el servidor ya rechaza a quien no tenga
      // acceso web habilitado (devuelve 403). Esto solo evita mostrar un
      // tablero vacío si alguna vez el rol no encaja.
      if (!Plataforma.rolPermitido(ApiService.rol)) {
        await ApiService.limpiarToken();
        if (!mounted) return;
        setState(() {
          _cargando = false;
          _error = 'Este tablero es solo para administradores.';
        });
        _shake.forward(from: 0);
        return;
      }
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('rf_logged_in', true);
      await sp.setString('rf_usuario', u);
      // Si aún no hay operador configurado, usamos el nombre del usuario.
      if ((sp.getString('operador') ?? '').isEmpty) {
        await sp.setString('operador', nombre);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, a, __) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, .04), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: const RouterScreen(),
          ),
        ),
      ));
    } on ApiException catch (e) {
      setState(() {
        _cargando = false;
        _error = e.message;
      });
      _shake.forward(from: 0);
    } catch (_) {
      setState(() {
        _cargando = false;
        _error = 'No se pudo conectar con el servidor';
      });
      _shake.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fondo suave: dos manchas azules difusas arriba/abajo.
          const _SoftBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeTransition(
                        opacity: _fadeAt(0),
                        child: ScaleTransition(
                          scale: Tween(begin: .9, end: 1.0).animate(
                              CurvedAnimation(
                                  parent: _intro,
                                  curve: const Interval(0, .6,
                                      curve: Curves.easeOutBack))),
                          child: const Center(child: AppLogo(size: 56)),
                        ),
                      ),
                      const SizedBox(height: 36),
                      FadeTransition(
                        opacity: _fadeAt(.25),
                        child: SlideTransition(
                          position: _slideAt(.25),
                          child: Text('Iniciar sesión',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      FadeTransition(
                        opacity: _fadeAt(.3),
                        child: const Text(
                          'Acceso para operadores del refugio',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.gray, fontSize: 13.5),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _ShakeX(
                        controller: _shake,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FadeTransition(
                              opacity: _fadeAt(.4),
                              child: SlideTransition(
                                position: _slideAt(.4),
                                child: TextField(
                                  controller: _usuario,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.username],
                                  onSubmitted: (_) =>
                                      _claveFocus.requestFocus(),
                                  decoration: const InputDecoration(
                                    labelText: 'Usuario',
                                    prefixIcon:
                                        Icon(Icons.person_outline, size: 21),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            FadeTransition(
                              opacity: _fadeAt(.5),
                              child: SlideTransition(
                                position: _slideAt(.5),
                                child: TextField(
                                  controller: _clave,
                                  focusNode: _claveFocus,
                                  obscureText: !_verClave,
                                  autofillHints: const [AutofillHints.password],
                                  onSubmitted: (_) => _entrar(),
                                  decoration: InputDecoration(
                                    labelText: 'Clave',
                                    prefixIcon:
                                        const Icon(Icons.lock_outline, size: 21),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                          () => _verClave = !_verClave),
                                      icon: Icon(
                                        _verClave
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                        color: AppColors.gray,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Error con aparición/desaparición animada.
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: _error == null
                            ? const SizedBox(height: 0, width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFFECACA)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          size: 18,
                                          color: Color(0xFFDC2626)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(_error!,
                                            style: const TextStyle(
                                                color: Color(0xFFB91C1C),
                                                fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 22),
                      FadeTransition(
                        opacity: _fadeAt(.6),
                        child: SlideTransition(
                          position: _slideAt(.6),
                          child: _BotonEntrar(
                              cargando: _cargando, onTap: _entrar),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FadeTransition(
                        opacity: _fadeAt(.75),
                        child: const Text(
                          'Registro de damnificados · Uso interno',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: AppColors.gray, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón que se transforma en spinner mientras valida.
class _BotonEntrar extends StatelessWidget {
  const _BotonEntrar({required this.cargando, required this.onTap});
  final bool cargando;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder nos da un ancho FINITO para el estado expandido, así el
    // AnimatedContainer interpola entre dos anchos finitos (finito ↔ 52) y no
    // entre infinito y finito (que dispara el assert de BoxConstraints).
    return LayoutBuilder(
      builder: (context, constraints) {
        final anchoLleno = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 320.0; // respaldo por si el padre no acota el ancho
        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            height: 52,
            width: cargando ? 52 : anchoLleno,
            child: FilledButton(
              onPressed: cargando ? null : onTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                disabledBackgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(cargando ? 26 : 14)),
                padding: EdgeInsets.zero,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: cargando
                    ? const SizedBox(
                        key: ValueKey('spin'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Entrar',
                        key: ValueKey('txt'),
                        style: TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Sacudida horizontal (error de credenciales).
class _ShakeX extends StatelessWidget {
  const _ShakeX({required this.controller, required this.child});
  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (_, c) {
        final t = controller.value;
        final dx = math.sin(t * math.pi * 4) * (1 - t) * 9;
        return Transform.translate(offset: Offset(dx, 0), child: c);
      },
    );
  }
}

/// Fondo con dos halos azules muy suaves (sin dependencias).
class _SoftBackdrop extends StatelessWidget {
  const _SoftBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _halo(260, AppColors.blueSoft),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _halo(300, const Color(0xFFF1F5F9)),
          ),
        ],
      ),
    );
  }

  Widget _halo(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      );
}
