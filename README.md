# Refugio Transitorio Monumental

Sistema de registro y gestión para la atención de familias alojadas en el Refugio Transitorio Monumental, Caracas.

## Descripción

Aplicación multiplataforma desarrollada con Flutter para apoyar las operaciones administrativas y de atención del refugio.

El sistema proporciona herramientas para:

* Registro y gestión de familias.
* Consulta y actualización de expedientes.
* Control operativo de acceso y servicios.
* Registro de actividades.
* Panel web para visualización de información y generación de reportes.

La aplicación utiliza un backend independiente para la gestión de datos y servicios.

## Tecnologías

* **Flutter / Dart** — Aplicación Android y aplicación web.
* **Node.js / Express** — Backend y API.
* **PostgreSQL** — Persistencia de datos.
* **GitHub Actions** — Automatización de compilación y despliegue.

## Estructura

```text
lib/
├── models/       Modelos de datos
├── screens/      Pantallas de la aplicación
├── services/     Servicios y comunicación con el backend
├── widgets/      Componentes reutilizables
├── config.dart   Configuración de la aplicación
├── permisos.dart Gestión de permisos de interfaz
└── theme.dart    Configuración visual

assets/            Recursos gráficos
web/               Configuración de Flutter Web
backend/           Herramientas y recursos relacionados con el backend
.github/           Automatización y workflows
```

## Desarrollo

Requisitos:

* Flutter SDK
* Dart SDK
* Android Studio o entorno compatible
* Git

Instalar dependencias:

```bash
flutter pub get
```

Ejecutar en Android:

```bash
flutter run
```

Ejecutar la versión web:

```bash
flutter run -d chrome
```

Compilar APK:

```bash
flutter build apk --release
```

Compilar Web:

```bash
flutter build web --release
```

## Verificación

Antes de realizar cambios importantes o publicar una nueva versión:

```bash
flutter analyze
```

También puede ejecutarse el script de verificación incluido en el proyecto:

```bash
python3 verificar.py
```

## Configuración

La configuración específica del entorno debe mantenerse fuera del repositorio.

No se deben incluir en Git:

* Credenciales.
* Variables de entorno.
* Claves privadas.
* Certificados.
* Bases de datos o respaldos.
* Información personal u operacional.
* Archivos de configuración específicos de producción.

Utilice las variables y archivos de configuración correspondientes a cada entorno.

## Licencia

Uso interno. Todos los derechos reservados.
