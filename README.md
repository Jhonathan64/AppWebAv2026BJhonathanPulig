# PoliMusic — Laboratorio de ASP clásico

**Autor:** Jhonathan Pulig  
**Repositorio:** https://github.com/Jhonathan64/AppWebAv2026BJhonathanPulig

## Qué es

PoliMusic es una aplicación web de música desarrollada con **ASP clásico (VBScript), SQL Server, HTML, CSS y JavaScript**. Permite iniciar sesión, consultar canciones, álbumes y artistas, reproducir audio y gestionar playlists. Incluye un panel administrativo con permisos por rol.

El proyecto está en `webapppolimusicv1_asp/PoliMusic/`. La carpeta que se publica en IIS es únicamente `site/`.

## Funcionalidades

- Registro, inicio y cierre de sesión.
- Catálogo dinámico, búsqueda y paginación.
- Reproductor HTML5 con cola, pausa, cambio de pista, progreso y volumen.
- Playlists personales y consulta de listas públicas.
- CRUD administrativo de usuarios, canciones, álbumes, artistas y playlists.
- Interfaz adaptable con desplazamiento del contenido y del menú lateral.

## Estructura

```text
AppWebAv2026BJhonathanPulig/
├── README.md                         Documentación general
└── webapppolimusicv1_asp/
    └── PoliMusic/
        ├── PoliMusic.sln             Solución para Visual Studio
        ├── database/
        │   ├── BDD_PoliMusic.sql      Estructura y datos iniciales
        │   └── 02_datos_extra.sql     Datos adicionales de ejemplo
        ├── site/                     Raíz del sitio en IIS
        │   ├── includes/
        │   │   ├── config.asp        Configuración y helpers
        │   │   ├── config.local.asp  Conexión privada; excluida de Git
        │   │   ├── config.local.example.asp  Plantilla de conexión
        │   │   ├── db.asp            Acceso a datos mediante ADO
        │   │   ├── security.asp      Autenticación, sesión y permisos
        │   │   └── ui.asp            Plantilla y componentes visuales
        │   ├── default.asp           Entrada a la aplicación
        │   ├── login.asp / logout.asp / register.asp
        │   ├── home.asp / songs.asp / search.asp
        │   ├── albums.asp / album_detail.asp
        │   ├── artists.asp / artist_detail.asp
        │   ├── playlists.asp / playlist_detail.asp
        │   ├── admin/                CRUD administrativo
        │   ├── api/register_play.asp Registro de reproducciones
        │   ├── assets/
        │   │   ├── css/              Estilos
        │   │   ├── js/               Reproductor e interacción
        │   │   └── img/              Logo y recursos de interfaz
        │   ├── songFiles/            Archivos MP3
        │   ├── albumImages/          Portadas de álbumes
        │   ├── ArtistImages/         Imágenes de artistas
        │   ├── userImages/           Avatares
        │   └── playlistImages/       Portadas de playlists
        ├── docs/                     Vista previa y capturas
        └── tools/                    Lanzador local y verificadores
```

## Recursos y rutas

Los audios están en `site/songFiles/`. Las imágenes se distribuyen entre `assets/img/` y las carpetas por categoría. Esta implementación no utiliza `assets/audio/` ni `assets/images/`.

La base guarda rutas como `~/songFiles/bensound-adventure.mp3`. El helper `AssetUrl` las transforma en URLs relativas a la raíz del sitio. `SITE_ROOT`, en `includes/config.asp`, debe estar vacío para un sitio raíz o contener el alias, por ejemplo `/PoliMusic`, si se publica como aplicación.

Se incluyen cinco MP3; cuatro son copias del audio de ejemplo. Los recursos de Bensound conservan las condiciones de licencia de su proveedor.

## Base de datos y conexión

| Parámetro local | Valor |
|---|---|
| Contenedor | `sql-server2025` |
| Servidor desde Windows | `127.0.0.1,14333` |
| Base de datos | `BDD_PoliMusic` |
| Usuario SQL | `sa` |
| Contraseña | La configurada en el contenedor; guardada en `config.local.asp` |

`config.asp` incluye `config.local.asp`; `db.asp` abre la conexión y ejecuta consultas parametrizadas mediante `ADODB.Command`.

En otra máquina, copia `site/includes/config.local.example.asp` como `site/includes/config.local.asp` y configura la contraseña correspondiente. El archivo local está excluido de Git.

Las tablas principales son `TBL_USER`, `TBL_SONG`, `TBL_ALBUM`, `TBL_ARTIST`, `TBL_PLAYLIST` y sus tablas de relación. `TBL_CATALOG` contiene los tipos utilizados por la aplicación.

**El script `database/BDD_PoliMusic.sql` contiene `DROP DATABASE`: recrea la base y elimina sus datos anteriores. No lo ejecutes de nuevo sobre la base local existente para iniciar la aplicación.** Para una instalación nueva, prepara la base con ese script y después, si corresponde, ejecuta `02_datos_extra.sql`.

## Autenticación, sesión y roles

`login.asp` valida contra `TBL_USER` mediante `Authenticate`. Cuando las credenciales son correctas, `StartSession` guarda `Session("username")`, `Session("role")` y el identificador del usuario. `logout.asp` elimina la sesión y vuelve al login.

| Rol | Valor en base | Valor de sesión | Permisos |
|---|---|---|---|
| Normal | `USER_TYPE = 0` | `user` | Consultar y reproducir música; gestionar sus propias playlists |
| Administrador | `USER_TYPE = 1` | `admin` | Acceso adicional al CRUD administrativo global |

Las vistas privadas llaman a `RequireLogin`. Las páginas administrativas llaman a `RequireAdmin` antes de ejecutar operaciones. Los enlaces administrativos se muestran únicamente si `IsAdmin` devuelve verdadero.

Por compatibilidad con los datos del laboratorio, se admiten las claves originales en texto plano y hashes SHA1. Este mecanismo de demostración debe modernizarse antes de un uso en producción.

## Ejecutar con IIS Express

Requisitos: Windows, IIS Express instalado y SQL Server disponible en Docker. Desde la raíz del repositorio:

```powershell
cd .\webapppolimusicv1_asp\PoliMusic
powershell -ExecutionPolicy Bypass -File .\tools\start-local.ps1
```

Mantén la consola abierta y visita **http://localhost:8085/login.asp**. Ctrl+C detiene el servidor. Si una instancia ya ocupa ese puerto, utiliza la existente o detenla antes de iniciar otra.

## Configurar IIS local

1. Activa IIS, ASP, Extensiones ISAPI y Contenido estático en las características de Windows.
2. Abre el Administrador de IIS como administrador y crea un sitio con ruta física a `PoliMusic\site`, puerto libre `8085` y un grupo de aplicaciones con «Sin código administrado».
3. Concede permisos de lectura y ejecución a `IIS_IUSRS` e `IUSR` sobre `site`.
4. En la característica ASP del sitio, habilita **Enable Parent Paths** para los includes administrativos con `../includes`.
5. Conserva `SITE_ROOT = ""` para ese sitio raíz y abre http://localhost:8085/login.asp.

IIS Express e IIS no deben ocupar simultáneamente el mismo puerto. Live Server y abrir un archivo ASP directamente no ejecutan VBScript.

## Cuentas y comprobación funcional

| Usuario de prueba | Contraseña inicial | Rol |
|---|---|---|
| `userAdmin` | `12345678` | Administrador |
| `userNormal` | `12345678` | Normal |

La base local también contiene la cuenta personal **`Jhonathan.Pulig`**, de tipo normal. Utiliza esa cuenta para mostrar tu nombre en la captura.

- Entrar con credenciales válidas y comprobar que una contraseña incorrecta se rechaza.
- Abrir `/songs.asp`: verificar saludo, catálogo y reproducción audible con avance de la barra.
- Comparar los accesos visibles para administrador y usuario normal.
- Intentar `/admin/songs.asp` como normal: debe redirigir al inicio.
- Cerrar sesión y visitar `/songs.asp`: debe redirigir al login.
- Comprobar desplazamiento y acceso a «Cerrar sesión» sin reducir el zoom. Tras cambios de estilos, recargar con Ctrl+F5.

Los verificadores opcionales requieren Python y se ejecutan desde `PoliMusic`:

```powershell
python tools/check_asp.py
python tools/check_args.py
```

Estas revisiones estáticas no sustituyen la ejecución de las páginas en IIS. `docs/preview.html` es una vista previa estática, no evidencia de conexión con SQL Server.

## Documento de entrega del laboratorio

1. **Portada y objetivo:** autor, asignatura, docente, laboratorio y fecha.
2. **Arquitectura:** estructura del proyecto, conexión, autenticación y control de roles.
3. **SSMS:** capturas de `BDD_PoliMusic`, tablas y consultas de usuarios/roles y canciones, sin mostrar contraseñas.
4. **GitHub:** enlace al repositorio y captura de los archivos finales publicados y su commit.
5. **Interfaz funcional:** sesión de `Jhonathan.Pulig`, catálogo, reproductor y comparación admin/normal.
6. **Resultados y conclusión:** pruebas realizadas, resultados observados y limitaciones.

Para las evidencias en SSMS:

```sql
USE BDD_PoliMusic;
SELECT ID_USER, USERNAME, USER_TYPE FROM dbo.TBL_USER;
SELECT ID_SONG, SONG_NAME, SONG_PATH, PLAYS FROM dbo.TBL_SONG;
```

Numera las capturas y explica brevemente qué demuestra cada una. Comprueba que los cambios estén publicados en GitHub antes de entregar; configurar un remoto no publica los archivos. Contrasta esta guía con la rúbrica oficial del docente.