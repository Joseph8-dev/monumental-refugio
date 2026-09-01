# Refugio Transitorio Monumental

Registro y control de damnificados del Refugio Transitorio Monumental
(Estadio Monumental Simón Bolívar, Caracas).

Una sola base de código para dos usos:

- **APK Android** — censo de familias, control de acceso y comidas,
  bitácora del turno.
- **Tablero web** — métricas y reportes para la coordinación, publicado
  en GitHub Pages.

Backend en Node/Express sobre PostgreSQL, en `https://mlgroup.work/api`.

---

## Perfiles

| Perfil | Qué puede hacer |
| --- | --- |
| **Administrador** | Todo: tablero, reportes, expedientes, acceso |
| **Recolector** | Registrar y editar familias |
| **Vigilante** | Entrada/salida, comidas, bitácora y ayudas |

La matriz está en `lib/permisos.dart` y su espejo en
`backend/permisos.js`. Para cambiar qué ve un perfil se edita la lista de
ese rol; la barra de navegación y los botones se arman solos.

El tablero web es solo para administradores **con acceso web habilitado**
(`node usuarios.js web <usuario> on`): un permiso aparte del rol, para
que una clave filtrada de la tablet no sirva en internet.

---

## El formulario

El asistente sigue la estructura del censo oficial del campamento, que es
una ficha por persona:

1. **Familia y ubicación** — cubículo, campamento, procedencia, vivienda
   antes del sismo, vehículo, carnet de la patria
2. **Jefe/a de familia** — ficha completa
3. **Integrantes** — una ficha por persona, con los mismos campos
4. **Foto y cierre** — foto del grupo, estatus, prioridad, resumen

Los pasos 2 y 3 usan el mismo formulario (`PersonaForm`), porque en el
censo el jefe/a es una fila más.

La planilla anterior de damnificados (13 secciones sobre daños, ayuda
social y firmas) sigue en el código y se reactiva desde
`lib/modulos.dart` si vuelve a hacer falta.

---

## Puesta en marcha

### App

```bash
flutter create --platforms=android,web --org ve.monumental --project-name refugio_petare .
flutter pub get
flutter run                    # Android
flutter run -d chrome          # tablero web
flutter build apk --release
```

El `AndroidManifest.xml` necesita permiso de internet — no se inyecta
solo en release:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### Servidor

Los archivos de `backend/` van a `/root/rpetare/src/routes/`:

```bash
psql -h 127.0.0.1 -U sa -d mlgroup -f backend/schema.sql

# rutas: backend/rutas_refugio.js reemplaza src/routes/index.js
# junto a permisos.js y patologias.js

cd /root/rpetare/src/routes
node usuarios.js crear admin_web admin "Administrador Web"
node usuarios.js web admin_web on
node importar_censo.js "censo.xlsx" --dry    # simulacro
node importar_censo.js "censo.xlsx"
node backfill_patologias.js

pm2 restart rpetare-api --update-env
```

Variables del `.env`:

```bash
NODE_ENV=production
RF_USER=admin                    # admin de emergencia, sin acceso web
RF_PASS=...
RF_JWT_SECRET=...                # openssl rand -base64 48
RF_CAPACIDAD=1000                # referencia, no es un tope
RF_TIMEZONE=America/Caracas      # día del refugio para las comidas
RF_REPORTES_EMAILS=...           # destinatarios, coma para varios
RF_WEB_ORIGINS=https://usuario.github.io
GMAIL_REFUGIO_USER=...
GMAIL_REFUGIO_PASS=...           # App Password de Gmail
```

Express y nginx deben llevar el mismo límite de subida (50 MB): los
expedientes viajan con fotos en base64.

---

## Estructura

```
lib/
  config.dart          dirección del API
  permisos.dart        qué ve cada perfil
  plataforma.dart      diferencias entre Android y web
  modulos.dart         formato del formulario
  datos.dart           aviso de cambios entre pantallas
  theme.dart           paleta del manual de identidad
  models/              expediente, bitácora, catálogos
  services/            llamadas al API
  screens/             login, tablero, expedientes, acceso, asistente
  widgets/             campos, tabla de familias, fichas, bitácora
backend/               lo que va en el servidor
web/                   página del tablero
assets/                logo, icono, splash (ver LEEME.txt)
```

---

## Detalles que conviene saber

**Zona horaria.** El VPS está en Alemania. El día de las comidas se
calcula en `America/Caracas`, o una cena de las 8 PM quedaría registrada
como del día siguiente.

**Patologías.** El tablero cuenta **personas**; al tocar una condición se
listan las **familias** que la tienen, que son menos. Las etiquetas se
calculan al guardar y se normaliza el texto libre del censo en papel
(`backend/patologias.js`).

**Edades.** Se recalculan desde la fecha de nacimiento, así que un menor
pasa a adulto solo. Niño es menos de 18; adulto mayor, 60 o más. Las 57
personas del censo sin fecha conservan la edad registrada.

**Fotos.** Viajan en base64 dentro del expediente. El tablero nunca las
pide: con cientos de familias serían decenas de MB por consulta.

**Capacidad.** Las 1000 personas son una referencia de planificación. Si
se supera, el tablero lo indica pero nada bloquea el registro.

---

## Antes de compilar

```bash
python3 verificar.py    # imports, duplicados, balance de llaves
flutter analyze
```
