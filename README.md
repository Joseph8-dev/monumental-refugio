# Refugio Petare — Registro digital de damnificados

App Flutter (Android APK primero) que digitaliza la **Planilla de Ingreso y Registro
de Damnificados** como asistente por pasos, con CRUD contra tu backend Node
(`https://mlgroup.work/api/`) y PostgreSQL.

- Estilo: minimalista moderno, blanco / gris / azul, Material 3, animaciones suaves.
- App ID sugerido: **`ve.petare.refugio`** · nombre del proyecto: `refugio_petare`.
- Logo: placeholder de texto ("RP · REFUGIO PETARE"), listo para reemplazar por imagen.

## 1 · Generar las carpetas de plataforma y compilar el APK

Este paquete trae `lib/`, `pubspec.yaml` y el backend. Las carpetas `android/`
etc. las genera Flutter en tu máquina:

```bash
cd refugio_petare
flutter create --org ve.petare --project-name refugio_petare .
flutter pub get
flutter run                # prueba en emulador o dispositivo
flutter build apk --release   # APK en build/app/outputs/flutter-apk/app-release.apk
```

`flutter create .` respeta el `pubspec.yaml` y `lib/` existentes; solo agrega
android/ios/web. Después de crear, edita `android/app/src/main/AndroidManifest.xml`
y confirma que el `label` sea `Refugio Petare` y que exista permiso de internet:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

(`image_picker` para cámara no requiere permisos manuales en Android moderno;
usa el intent del sistema.)

## 2 · Backend (VPS mlgroup.work · app `rpetare-api`)

En el servidor (`/root/rpetare`, escucha en `127.0.0.1:3000` detrás de nginx):

1. **Cargar el schema en la base `mlgroup`** (esto resuelve el bloqueo actual
   de base de datos vacía — al menos para este módulo):
   ```bash
   psql -h 127.0.0.1 -U sa -d mlgroup -f backend/schema.sql
   ```
   > Ojo: el error `relation "ge_usd_ves_rate" does not exist` es de las tablas
   > del sistema heredado de goevent; esas hay que restaurarlas aparte
   > (pg_dump del origen). Este schema solo crea `rf_expedientes`.

2. Copia `backend/refugio_routes.js` a `/root/rpetare/src/routes/` y móntalo
   en `src/index.js`:
   ```js
   app.use('/api/refugio', require('./routes/refugio_routes'));
   ```
   Ajusta el `require('../db')` del router a donde tengas tu pool.

3. **Límites de tamaño** — las firmas y fotos viajan en base64:
   - Express: `app.use(express.json({ limit: '15mb' }));` antes de las rutas.
   - nginx: el sitio tiene `client_max_body_size 10M`; súbelo a `15M` en
     `/etc/nginx/sites-available/mlgroup.work` y `nginx -t && systemctl reload nginx`.

4. Reiniciar (recuerda el flag si tocaste `.env`):
   ```bash
   pm2 restart rpetare-api --update-env
   ```

5. Prueba rápida:
   ```bash
   curl -s -X POST https://mlgroup.work/api/refugio/login \
     -H 'Content-Type: application/json' \
     -d '{"usuario":"admin","clave":"1234"}'

   curl -s 'https://mlgroup.work/api/refugio/expedientes'
   ```

### Login

`POST /api/refugio/login` valida contra credenciales fijas **en el servidor**
(`RF_USERS` al inicio de `refugio_routes.js`): usuario `admin`, clave `1234`.
La app nunca conoce las credenciales; solo guarda la sesión localmente.
Cuando quieras usuarios reales: tabla `rf_usuarios` + bcrypt, mismo endpoint.

Endpoints que consume la app:

| Método | Ruta | Uso |
| --- | --- | --- |
| POST | `/api/refugio/login` | Acceso (admin / 1234, definidos en el servidor) |
| GET | `/api/refugio/expedientes?search=&estatus=` | Lista + búsqueda por cédula, nombre, teléfono, refugio o código |
| GET | `/api/refugio/expedientes/:id` | Detalle |
| POST | `/api/refugio/expedientes` | Crear |
| PUT | `/api/refugio/expedientes/:id` | Actualizar |
| POST | `/api/refugio/expedientes/:id/delete` | Borrado lógico |

Si quieres proteger estas rutas con tu `authMiddleware` (Bearer TOKEN estático),
agrégalo al montar el router y coloca el mismo token en `lib/config.dart`
(`AppConfig.apiToken`).

## 3 · Estructura de la app

```
lib/
  config.dart                  → SERVER_API y headers
  theme.dart                   → paleta blanco/gris/azul, Material 3
  main.dart                    → splash animado + MaterialApp
  models/expediente.dart       → modelo completo de la planilla + catálogos + alertas
  services/api_service.dart    → CRUD HTTP
  widgets/
    app_logo.dart              → logo placeholder (swap a imagen en 2 líneas)
    form_widgets.dart          → campos, Sí/No/No sabe, chips, fechas, condicionales animados
    signature_pad.dart         → firma manuscrita → PNG base64 (sin dependencias)
  screens/
    login_screen.dart          → acceso animado (entrada escalonada, botón que
                                 se convierte en spinner, sacudida en error)
    home_screen.dart           → lista, búsqueda con debounce, filtros por estatus,
                                 cerrar sesión
    expediente_detail_screen.dart → resumen, alertas, cambio de estatus, editar, eliminar
    wizard/
      wizard_screen.dart       → asistente de 7 pasos con progreso animado y borrador
      steps.dart               → los 7 pasos (13 secciones de la planilla)
```

Los 7 pasos siguen el orden recomendado del documento: ingreso rápido → grupo
familiar → salud → vivienda y daño → necesidad y bienes → ayuda, artículos y
documentos → declaraciones, firmas y evaluación. Los bloques repetibles
(acompañantes, artículos dañados) usan hojas modales; los documentos quedan
como *pendiente/cargado* sin bloquear el ingreso humanitario; y las alertas
automáticas (niños, adulto mayor, discapacidad, enfermedad, vivienda insegura,
ayuda previa, firma pendiente) se calculan solas y se muestran en lista,
detalle y paso final.

## 4 · Cambiar el logo cuando exista

1. Coloca el archivo en `assets/logo.png`.
2. En `pubspec.yaml`, descomenta el bloque `assets:`.
3. En `lib/widgets/app_logo.dart`, cambia `_hasImageLogo` a `true`.

Nada más: splash, appbar y cualquier uso de `AppLogo` toman la imagen.

## 5 · Renombrar la app más adelante

El nombre visible vive en `AppConfig.appName` (config.dart) y en el
AndroidManifest (`android:label`). El app id (`ve.petare.refugio`) se define al
correr `flutter create --org ve.petare`; si el nombre final cambia, puedes
regenerar con otro `--org` antes de publicar.

---

# 🆕 REFUGIO TRANSITORIO MONUMENTAL (actualización)

## Qué cambió
- **Nombre**: "Refugio Transitorio Monumental" (`AppConfig.appName` + AndroidManifest label).
- **Logo**: `assets/logo.png` (blanco) siempre sobre placa Azul Medianoche `#041941`,
  como exige el manual de identidad. Colores de la app sin cambios.
- **Paso nuevo "Censo Monumental"** (paso 2 de 8) con la estructura del Excel oficial:
  apartamento/cubículo, Nº familia, campamento, brazalete, estado y parroquia de
  procedencia, condición de la vivienda antes del terremoto, color de inspección,
  condición de salud, tipo de sangre, dieta, estatura y tallas, vehículo (placa/modelo),
  carnet de la patria (código y serial), ocupación y **foto del grupo familiar**.
- **3 perfiles**: `admin`, `recolector`, `vigilante`. El login devuelve el rol y la app
  enruta sola (`RouterScreen`).
- **Vigilante**: buscar → marcar Entrada/Salida y desayuno/almuerzo/cena del día.
- **Admin**: tablero con ocupación (x/1000), familias, personas, urgentes, dentro ahora,
  barras de urgencia / tenencia de vivienda / patologías, comidas del día y fotos.

## Despliegue en el servidor
```bash
# 1) tablas nuevas (rf_movimientos, rf_comidas, rf_usuarios, refugio Monumental)
psql -h 127.0.0.1 -U sa -d mlgroup -f backend/schema.sql

# 2) pega backend/refugio_monumental_routes.js dentro de routes/index.js
#    (después de las rutas /refugio/expedientes; reemplaza el POST /refugio/login viejo)

# 3) usuarios con rol (edita las claves primero)
node backend/crear_usuarios.js

# 4) importar el censo del Excel
node backend/importar_censo.js /ruta/CAMPAMENTO_STADIUM_MONUMENTAL_29082026.xlsx

# 5) reiniciar
pm2 restart rpetare-api --update-env
```

`.env` recomendado: `RF_USER`, `RF_PASS`, `RF_JWT_SECRET`, `RF_CAPACIDAD=1000`.

## Endpoints nuevos
| Método | Ruta | Rol |
| --- | --- | --- |
| GET | `/api/refugio/estado-hoy` | todos |
| POST | `/api/refugio/movimientos` | vigilante, admin |
| POST | `/api/refugio/comidas` | vigilante, admin |
| GET | `/api/refugio/metricas` | admin |

## 🔐 Permisos por perfil (fácil de cambiar)

La matriz vive en **dos archivos espejo**:
- `lib/permisos.dart` → qué pantallas/botones **ve** cada perfil.
- `backend/permisos.js` → qué operaciones **permite** el servidor.

Para prender o apagar una pantalla, edita solo la lista del rol:

```dart
// lib/permisos.dart
'recolector': [
  Permiso.expedientes,
  Permiso.registrar,
  // Permiso.acceso,     ← descomenta para que también pueda marcar
],
```

```js
// backend/permisos.js  (mantener sincronizado)
recolector: [P.expedientes, P.registrar],
```

Configuración actual:

| Permiso | admin | recolector | vigilante |
| --- | :--: | :--: | :--: |
| `dashboard` (tablero/reportes) | ✅ | — | — |
| `expedientes` (ver listado) | ✅ | ✅ | — |
| `registrar` (censar/editar) | ✅ | ✅ | — |
| `acceso` (entrada/salida, comidas) | ✅ | — | ✅ |
| `administrar` (estatus, eliminar) | ✅ | — | — |

La barra inferior se arma sola: si un perfil tiene **un solo** permiso de
pantalla, se muestra a pantalla completa sin navegación.

## 📥 Importación del censo (verificada con el archivo real)

El Excel usa celdas combinadas: `APTO.` y `Nº` solo aparecen en la fila del
jefe/a de familia. El importador detecta una familia nueva cuando hay `Nº`
o cuando el parentesco dice "Jefe...".

Resultado verificado con `CAMPAMENTO_STADIUM_MONUMENTAL_29082026`:
**190 personas → 73 familias**, 30 sin cubículo asignado, 22 con patología.

```bash
node backend/importar_censo.js archivo.xlsx --dry   # simulacro, no escribe
node backend/importar_censo.js archivo.xlsx         # importa
```

Normaliza automáticamente: ROJA/ROJO, PROPIA/PROPIO/ARRIMADO/AL CUIDO,
SANO/SANA, ORH POSITIVO → O+, "NO POSEE"/"NO APLICA" → no, y clasifica la
condición de salud en etiquetas (HIPERTENSO, DIABÉTICO, DISCAPACITADO,
EMBARAZADA, ASMÁTICO…) que alimentan el tablero.

## 📊 Reportes (perfil admin)

Tres exportaciones, disponibles en el tablero. El servidor genera el archivo y
el navegador del dispositivo lo descarga, así queda en "Descargas" y se puede
imprimir o mandar por WhatsApp sin pasar por la app.

| Reporte | Ruta | Contenido |
| --- | --- | --- |
| Resumen ejecutivo | `/api/refugio/reportes/resumen.pdf` | Una página: cifras, urgencia, vivienda, patologías y comidas del día |
| Censo completo | `/api/refugio/reportes/censo.xlsx` | **Una fila por persona**, con las columnas del censo original |
| Comidas y accesos | `/api/refugio/reportes/comidas.xlsx` | Últimos 30 días (`?desde=&hasta=` para otro rango) |

Instalación: pega `backend/refugio_reportes_routes.js` en `routes/index.js`
después del bloque de métricas (usa `XLSX` y `PDFDocument`, que ya tienes
importados) y agrega la dependencia de la app:

```bash
flutter pub get     # instala url_launcher
```

El `AndroidManifest.xml` necesita el `<queries>` de `android.intent.action.VIEW`
con esquema `https` (ya incluido en el manifest de referencia) para que
`url_launcher` pueda abrir el navegador en Android 11+.

**Nota de seguridad:** los reportes aceptan el token por `?token=` además del
header, porque el navegador no puede enviar cabeceras. El token dura 24h y solo
lo tiene el admin, pero ten en cuenta que una URL copiada sirve hasta que expire.

### Verificación hecha
Se importó el censo real y se exportó de vuelta: **190 personas entran, 190
salen**, con nombres, cédulas, brazaletes y tallas intactos.

## 👥 Censo por acompañante

El formulario del acompañante ahora captura los mismos datos que el Excel:
sexo, condición de salud, tipo de sangre, brazalete, ocupación, dieta y —en un
bloque plegable— estatura, tallas de camisa/pantalón, calzado y gorra.

Esto importa para el tablero: las patologías se cuentan **por persona**, no por
familia. Sin estos campos, una familia con un hijo diabético registrada desde la
app no aparecería en el conteo.

El clasificador (`backend/patologias.js`) es compartido por el importador y el
tablero, de modo que el texto libre del censo viejo ("DISCAPASITADO DE UNA
PIERNA Y MANO") y la lista fija de la app cuentan bajo la misma etiqueta.


---

# 🔄 CAMBIO DE FORMATO · el censo reemplaza a la planilla

El formulario de la app **ya no es** la planilla de damnificados de 13
secciones: ahora es el **censo del Campamento Monumental**, con la misma
estructura del Excel oficial (una fila por persona).

## Asistente actual (4 pasos)

| Paso | Contenido |
| --- | --- |
| 1 · Familia y ubicación | Refugio, cubículo, Nº de familia, campamento, procedencia, vivienda antes del terremoto, color de inspección, vehículo, carnet de la patria |
| 2 · Jefe/a de familia | Ficha completa de la persona |
| 3 · Integrantes | Una ficha por integrante, con los mismos campos |
| 4 · Foto y cierre | Foto del grupo familiar, estatus, prioridad, resumen |

Los pasos 2 y 3 usan **el mismo formulario** (`PersonaForm`), porque en el
censo el jefe/a es una fila más: identificación, contacto, salud (condición,
tipo de sangre, dieta), dotación (estatura, tallas, calzado, gorra), foto de
la cédula y observaciones.

## Volver a la planilla anterior

La planilla no se borró. En `lib/modulos.dart`:

```dart
static const bool censoMonumental = true;        // formato vigente
static const bool planillaDamnificados = false;  // ← true para reactivarla
```

Si activas la planilla, sus 7 pasos se agregan **después** de los del censo,
y sus secciones vuelven a aparecer en el detalle del expediente. Con ambos en
true el asistente tiene 11 pasos.

## Dónde vive cada dato

- `responsable` → **todos** los datos personales del jefe/a (incluye salud,
  brazalete, tallas). Es lo que edita el paso 2.
- `acompanantes[]` → lo mismo para cada integrante.
- `censo` → solo datos de **familia**: cubículo, campamento, procedencia,
  condición de la vivienda, inspección, vehículo, carnet, foto familiar.

⚠️ Este reparto cambió respecto a la versión anterior (antes los datos de
salud del jefe/a estaban en `censo`). El importador, las métricas y los
reportes ya están alineados. **Si importaste el censo con la versión previa,
vuelve a importar** para que los datos queden donde el formulario los busca:

```bash
node backend/importar_censo.js archivo.xlsx    # es idempotente
```

## Verificado con datos reales

190 personas → 73 familias. Patologías contadas **por persona**:
14 discapacitados, 3 embarazadas, 2 diabéticos, 2 hipertensos,
2 salud mental, 3 otras crónicas, 1 epiléptico, 1 asmático, 1 lupus.

---

## Ajustes posteriores al primer despliegue

**Locale español.** `main()` ahora llama `initializeDateFormatting('es')`.
Sin esto, la pantalla de Acceso reventaba con `LocaleDataException` al
formatear la fecha en texto.

**Bebés con edad 0.** El importador usaba `Number(x) || null`, y como `0` es
falsy en JavaScript, los 3 bebés del censo quedaban sin edad y el formulario
los bloqueaba al editarlos. Corregido con verificación explícita.
**Requiere reimportar** para arreglar los registros ya cargados.

**Un solo refugio.** "Refugio Transitorio Monumental" viene preseleccionado
en registros nuevos; "Otros" queda disponible por si abren otra sede.

**Alertas reclasificadas.** Antes todas eran ámbar con ⚠ y se confundían.
Ahora son dos familias con color e icono distintos:

| Tipo | Color | Icono | Significado |
| --- | --- | --- | --- |
| Atención | Azul | ♡ | Quién es la familia y qué cuidado requiere: niños, adulto mayor, discapacidad, condición médica |
| Pendiente | Ámbar | ⬆ | Falta cargar algo: foto de cédula, foto familiar |

Se eliminó "Firma pendiente" (el censo no lleva firmas). Las alertas de
atención ahora consideran también al jefe/a de familia, no solo a los
acompañantes.

**Operador.** Se quitó el diálogo "Operador de turno": el operador es el
usuario que inició sesión. El icono del appbar quedó informativo.

## 🎨 Cambiar iconos y splash

Todo se cambia reemplazando archivos en `assets/` — ver `assets/LEEME.txt`
para las especificaciones de cada uno.

| Archivo | Dónde se ve | Comando después de cambiarlo |
| --- | --- | --- |
| `logo.png` | Login, appbar, splash animado | ninguno |
| `app_icon.png` | Icono en el teléfono | `flutter pub run flutter_launcher_icons` |
| `app_icon_foreground.png` | Capa del icono adaptativo Android | `flutter pub run flutter_launcher_icons` |
| `splash_logo.png` | Arranque nativo | `dart run flutter_native_splash:create` |

`logo.png` y `splash_logo.png` son PNG **blancos con transparencia**: la app
los pinta siempre sobre azul medianoche `#041941`, como pide el manual de
identidad. `app_icon.png` en cambio debe llevar fondo sólido.

## 📧 Reportes por correo (reemplaza la descarga por navegador)

La app ya no abre el navegador: encola el pedido y el servidor genera el
archivo y lo manda como adjunto, con el mismo patrón de cola con reintentos
del reporte de recargas de GoEvent.

```
POST /api/refugio/reportes/enviar
{ "tipo": "resumen"|"censo"|"comidas", "email": "...", "desde": "YYYY-MM-DD", "hasta": "YYYY-MM-DD" }
```

Responde de inmediato (`success: true`) y el envío ocurre en segundo plano,
de a uno, con hasta 2 reintentos. El periodo del selector de fechas aplica al
reporte de comidas; el resumen y el censo reflejan el estado actual.

**Configuración en `.env`** (si no se ponen, usa las credenciales de SICAT):

```
GMAIL_REFUGIO_USER=...
GMAIL_REFUGIO_PASS=...      # App Password de Gmail, no la clave normal
RF_CAPACIDAD=1000
```

Instalación: pega `backend/refugio_reportes_routes.js` en `routes/index.js`
después del bloque de métricas. Usa `XLSX`, `PDFDocument` y `nodemailer`, que
ya tienes importados.

## Otros ajustes

- **Filtro por prioridad** en la lista (Normal / Alta / Urgente), con el color
  de cada nivel. Requiere el parámetro `prioridad` en `GET /refugio/expedientes`
  (ya incluido en `index_routes_secure.js`).
- **Alertas con icono propio**: niño, adulto mayor, discapacidad, embarazo,
  condición médica, sin cédula, sin foto familiar. Se cuentan **personas**:
  una familia con 1 niño y 1 adulto mayor muestra "1 niño" y "1 adulto mayor".
- **Capacidad = referencia, no tope.** Si se superan las 1000 personas la barra
  se llena, cambia a ámbar e indica cuántas hay por encima. Nunca bloquea el
  registro.
- **Cerrar sesión** disponible también en el Tablero.

## Destinatarios de reportes (solo en el .env)

La app ya no pide a quién enviar: los destinatarios se fijan en el servidor,
así nadie puede mandarse el censo completo a un correo personal desde el
teléfono.

```
RF_REPORTES_EMAILS=director@dominio.com, coordinacion@dominio.com
```

Acepta varios separados por coma o punto y coma. Cambiarlos **no requiere
recompilar el APK**: se edita el `.env` y `pm2 restart rpetare-api --update-env`.
La app consulta `GET /api/refugio/reportes/destinatarios` solo para mostrar a
quién llegará; si la lista está vacía, los botones de envío quedan
deshabilitados con el aviso correspondiente.

## Filtros en la pestaña Acceso

Además de la búsqueda (cédula, nombre, cubículo o brazalete):

- **Presencia**: Todos · Dentro · Fuera
- **Comidas pendientes**: Falta desayuno · Falta almuerzo · Falta cena —
  muestran a quienes **aún no** han recibido esa comida hoy, que es la lista
  útil a la hora de servir.

Se aplican sobre la lista ya cargada (el estado del día vive en memoria) y la
cabecera indica cuántas familias quedan en el filtro.

## Verificación previa al build

`verificar.py` revisa el proyecto sin necesidad del SDK de Flutter. Detecta
los cuatro errores que ya han roto el build en este proyecto:

1. Símbolos usados sin importar el archivo que los define.
2. Miembros duplicados en una misma clase (un campo con el mismo nombre que
   un método, por ejemplo).
3. Imports que apuntan a archivos inexistentes.
4. Llaves, paréntesis o corchetes desbalanceados.

```bash
python3 verificar.py        # antes de compilar
```

No sustituye al compilador de Dart, que sigue siendo la verdad; solo atrapa
rápido los tropiezos más comunes al mover código entre archivos.

## Ajustes finales

**Cédula y teléfono con formato controlado.** `CedulaField` (desplegable
V/E/P + número) y `TelefonoField` (código de operadora + 7 dígitos, como en
la banca) reemplazan los campos libres. Cada uno guarda **un solo valor**
concatenado con el formato del censo: `V-22.352.324` y `0414-3782216`.

Al abrir un registro importado, los campos se separan solos — incluso los
teléfonos del Excel que venían sin el cero inicial (`4143782216`).

La búsqueda tolera ambas formas: el operador puede teclear `22352324` y
encuentra `V-22.352.324`, porque el servidor compara también solo dígitos.

**Fotos en el detalle.** Al abrir un expediente se ven la foto de la cédula
del jefe/a y la del grupo familiar. Se tocan para verlas a pantalla completa
con zoom, que es lo que hace falta para leer una cédula.

**Tablero sin fotos.** Las fotos familiares se quitaron del tablero: iban en
base64 dentro de la respuesta de métricas y con cientos de expedientes eso
son decenas de MB por consulta. En su lugar hay una lista de texto con las
**últimas 30 familias registradas** (nombre, cubículo, personas, prioridad).
Las fotos siguen viéndose en el detalle de cada expediente.

**PDF del resumen en una sola página.** El pie se escribía por debajo del
margen inferior y PDFKit abría una hoja en blanco automáticamente. Ahora el
margen se anula solo mientras se dibuja el pie, y los bloques se miden antes
de pintarse para no partirse.

## Refresco entre pantallas

`lib/datos.dart` es una señal global: cada escritura llama
`Datos.cambiaron(origen: '...')` y las pantallas abiertas recargan solas.
Antes cada una consultaba una vez y no se enteraba de lo que hacían las
otras — se cambiaba el estatus en el detalle y la lista seguía en lo viejo.

El `origen` evita que la pantalla que hizo el cambio se recargue a sí misma.
Importa en Acceso: cada marca de comida ya se refleja al instante, y una
recarga completa por toque sería un viaje a la red de más y un parpadeo.

El Tablero lo necesita especialmente porque vive dentro de un `IndexedStack`
y no se reconstruye al cambiar de pestaña.

## Detalle del expediente

Muestra la ficha completa de cada persona (jefe/a e integrantes por
separado), incluidos los campos condicionales que antes se capturaban pero
no se veían: **detalle de la dieta**, descripción de la condición de salud,
correo, tallas, gorra y observaciones. Los campos vacíos se omiten en vez de
mostrar guiones.

---

# 🌐 Tablero web (GitHub Pages)

El tablero administrativo se publica como página web compilando **la misma
app** a Flutter web. No es una reimplementación en HTML: mismo código,
mismos widgets, mismo logo y mismos colores, así que el navegador y la
tablet nunca se desincronizan.

## Qué se ve en web

Solo el perfil **administrador** y solo el **Tablero** (`lib/plataforma.dart`).
El registro de personas y el control de acceso siguen siendo del teléfono:
requieren cámara y se hacen junto a la familia. Si alguien con perfil
recolector o vigilante intenta entrar desde el navegador, el login lo
rechaza con un mensaje.

## Publicar

1. Sube el proyecto a un repositorio de GitHub (el `.gitignore` ya excluye
   `android/`, `build/` y el `.env`).
2. En el repo: **Settings → Pages → Build and deployment → Source:
   GitHub Actions**.
3. Cada push a `main` compila y publica solo. Queda en:
   `https://<usuario>.github.io/<repositorio>/`

El workflow (`.github/workflows/deploy-web.yml`) se encarga del `--base-href`
correcto, del `.nojekyll` y del `404.html`; sin esos tres detalles GitHub
Pages muestra una página en blanco.

## Probar localmente

```bash
flutter create --platforms=web .
flutter pub get
flutter run -d chrome
```

## Requisito del servidor

La API debe aceptar peticiones desde otro dominio. Ya lo hace:
`app.use(cors())` en `src/index.js`.

Si más adelante quieres restringirlo solo a tu página (recomendable), en el
servidor:

```js
app.use(cors({ origin: ['https://<usuario>.github.io'] }));
```

## Advertencia de seguridad

GitHub Pages es **público**: cualquiera con la URL ve la pantalla de login.
Los datos siguen protegidos por usuario, clave y JWT, pero el tablero queda
expuesto a intentos de acceso desde cualquier parte del mundo, no solo desde
el refugio. Recomendaciones:

- Clave de administrador larga y distinta de la del APK.
- Repositorio **privado** (Pages sigue funcionando en cuentas con plan que
  lo permita; si es gratuito, el repo debe ser público — pero entonces
  **jamás** subas el `.env` ni claves).
- Considerar restringir CORS al dominio de la página, como arriba.

El `noindex` del `index.html` evita que la página salga en buscadores, pero
eso no es una medida de seguridad: solo reduce la exposición.

## Tablero en pantalla ancha

El tablero se adapta al ancho disponible:

- **Menos de 980 px** (teléfono, tablet vertical): una columna, como
  siempre.
- **980 px o más** (navegador de escritorio): **dos columnas** repartiendo
  los bloques alternadamente, con tope de 1500 px. Antes quedaba una
  columna angosta centrada y media pantalla vacía a los lados.

### Familias registradas (solo web)

En el navegador no hay pestaña de Expedientes, así que el tablero necesita
poder recorrer todas las familias. La tabla:

- Trae **10 por página** del servidor (`?limit=&offset=`), no todas de
  golpe.
- Tiene búsqueda por nombre, cédula, cubículo o brazalete.
- Al hacer clic en una fila abre una **ventana emergente** con la ficha
  completa: censo, jefe/a de familia, cada integrante, alertas y las fotos
  de cédula y grupo familiar.

La ficha sale de `lib/widgets/ficha.dart`, compartido con la pantalla de
detalle del teléfono: al agregar un campo aparece en los dos lados, sin
riesgo de que uno se quede atrás.

En el teléfono el tablero sigue mostrando las últimas 30 en texto, porque
allí el listado completo ya tiene su propia pestaña.

## Nota sobre la búsqueda

Las cédulas y teléfonos se guardan con formato (`V-22.352.324`,
`0414-3782216`) pero el operador los teclea sin puntos ni guion, así que la
consulta compara además solo los dígitos de ambos lados.

Esa comparación **solo se agrega cuando lo buscado contiene números**. Una
versión anterior usaba un comodín con byte NUL para "no coincidir con
nada"; PostgreSQL rechaza el NUL en texto, y cualquier búsqueda sin dígitos
(por ejemplo "test") tumbaba la consulta completa con
`invalid byte sequence for encoding "UTF8": 0x00`.
