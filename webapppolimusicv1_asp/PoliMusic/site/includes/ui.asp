<%
'=====================================================================
'  PoliMusic - includes/ui.asp
'  Plantilla común (cabecera, navegación, pie, reproductor) y
'  componentes reutilizables: tarjetas de canción, álbum, artista,
'  playlist y filas de lista.
'=====================================================================

'---------------------------------------------------------------------
' Cabecera estándar de la aplicación
'   title  : título de la pestaña
'   active : sección resaltada (home|search|songs|albums|artists|playlists|admin)
'---------------------------------------------------------------------
Sub PageTop(ByVal title, ByVal active)
    Dim q
    active_section = active      ' se reutiliza en PageBottom (tabbar)
    q = GetStr("q", "", 80)
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><%= E(title) %> · <%= APP_NAME %></title>
    <meta name="description" content="PoliMusic: tu biblioteca musical en la nube.">
    <link rel="icon" href="<%= Url("/assets/img/logo.png") %>">
    <link rel="stylesheet" href="<%= Url("/assets/css/polimusic.css?v=20261018-scroll") %>">
</head>
<body class="app" data-root="<%= E(SITE_ROOT) %>">
<a class="skip-link" href="#contenido">Saltar al contenido</a>

<div class="layout">
    <!-- ============ Barra lateral (escritorio / tablet) ============ -->
    <aside class="sidebar" id="sidebar">
        <a class="brand" href="<%= Url("/home.asp") %>">
            <span class="brand__mark" aria-hidden="true"></span>
            <span class="brand__text">Poli<b>Music</b></span>
        </a>

        <nav class="nav" aria-label="Navegación principal">
            <a class="nav__item<%= IsActive(active, "home") %>" href="<%= Url("/home.asp") %>">
                <span class="ico ico--home" aria-hidden="true"></span><span>Inicio</span>
            </a>
            <a class="nav__item<%= IsActive(active, "search") %>" href="<%= Url("/search.asp") %>">
                <span class="ico ico--search" aria-hidden="true"></span><span>Buscar</span>
            </a>
            <a class="nav__item<%= IsActive(active, "songs") %>" href="<%= Url("/songs.asp") %>">
                <span class="ico ico--song" aria-hidden="true"></span><span>Canciones</span>
            </a>
            <a class="nav__item<%= IsActive(active, "albums") %>" href="<%= Url("/albums.asp") %>">
                <span class="ico ico--album" aria-hidden="true"></span><span>Álbumes</span>
            </a>
            <a class="nav__item<%= IsActive(active, "artists") %>" href="<%= Url("/artists.asp") %>">
                <span class="ico ico--artist" aria-hidden="true"></span><span>Artistas</span>
            </a>
            <a class="nav__item<%= IsActive(active, "playlists") %>" href="<%= Url("/playlists.asp") %>">
                <span class="ico ico--list" aria-hidden="true"></span><span>Mis playlists</span>
            </a>
            <% If IsAdmin() Then %>
            <a class="nav__item nav__item--admin<%= IsActive(active, "admin") %>" href="<%= Url("/admin/default.asp") %>">
                <span class="ico ico--admin" aria-hidden="true"></span><span>Administración</span>
            </a>
            <% End If %>
        </nav>

        <div class="sidebar__foot">
            <a class="user-chip" href="<%= Url("/playlists.asp") %>">
                <img class="avatar" src="<%= AssetUrl(CurrentUserPhoto(), AVATAR_DEFAULT) %>" alt="">
                <span class="user-chip__name"><%= E(CurrentUserName()) %></span>
            </a>
            <a class="btn btn--ghost btn--sm" href="<%= Url("/logout.asp") %>">Cerrar sesión</a>
        </div>
    </aside>

    <!-- ============ Contenido ============ -->
    <div class="main">
        <header class="topbar">
            <button class="icon-btn topbar__menu" type="button" id="btnMenu" aria-label="Mostrar menú">
                <span></span><span></span><span></span>
            </button>

            <form class="searchbox" action="<%= Url("/search.asp") %>" method="get" role="search">
                <span class="ico ico--search" aria-hidden="true"></span>
                <input type="search" name="q" value="<%= E(q) %>" placeholder="Busca canciones, álbumes, artistas..." aria-label="Buscar">
            </form>

            <div class="topbar__right">
                <% If IsAdmin() Then %>
                <a class="badge-admin" href="<%= Url("/admin/default.asp") %>">Admin</a>
                <% End If %>
                <a class="user-chip user-chip--top" href="<%= Url("/playlists.asp") %>">
                    <img class="avatar" src="<%= AssetUrl(CurrentUserPhoto(), AVATAR_DEFAULT) %>" alt="">
                    <span class="user-chip__name"><%= E(CurrentUserName()) %></span>
                </a>
            </div>
        </header>

        <main class="content" id="contenido">
            <% RenderFlash %>
<%
End Sub

'---------------------------------------------------------------------
' Pie estándar: cierra el contenido, imprime el reproductor y los JS.
'---------------------------------------------------------------------
Sub PageBottom()
%>
        </main>

        <!-- ============ Reproductor ============ -->
        <div class="player" id="player" data-empty="true">
            <audio id="audio" preload="metadata"></audio>

            <div class="player__now">
                <img class="player__cover" id="playerCover" src="<%= Url("/assets/img/logo.png") %>" alt="">
                <div class="player__meta">
                    <strong id="playerTitle">Selecciona una canción</strong>
                    <span id="playerArtist">PoliMusic</span>
                </div>
            </div>

            <div class="player__controls">
                <div class="player__buttons">
                    <button class="icon-btn" type="button" id="btnPrev" title="Anterior" aria-label="Anterior">
                        <span class="ico ico--prev" aria-hidden="true"></span>
                    </button>
                    <button class="play-btn" type="button" id="btnPlay" title="Reproducir" aria-label="Reproducir">
                        <span class="ico ico--play" aria-hidden="true"></span>
                    </button>
                    <button class="icon-btn" type="button" id="btnNext" title="Siguiente" aria-label="Siguiente">
                        <span class="ico ico--next" aria-hidden="true"></span>
                    </button>
                </div>
                <div class="player__bar">
                    <span class="player__time" id="timeCur">0:00</span>
                    <input class="seek" type="range" id="seek" min="0" max="1000" value="0" step="1" aria-label="Progreso">
                    <span class="player__time" id="timeDur">0:00</span>
                </div>
            </div>

            <div class="player__volume">
                <span class="ico ico--vol" aria-hidden="true"></span>
                <input class="vol" type="range" id="vol" min="0" max="100" value="80" aria-label="Volumen">
            </div>
        </div>

        <!-- ============ Navegación inferior (móvil) ============ -->
        <nav class="tabbar" aria-label="Navegación móvil">
            <a class="tabbar__item<%= IsActive(active_section, "home") %>" href="<%= Url("/home.asp") %>">
                <span class="ico ico--home" aria-hidden="true"></span><span>Inicio</span>
            </a>
            <a class="tabbar__item<%= IsActive(active_section, "search") %>" href="<%= Url("/search.asp") %>">
                <span class="ico ico--search" aria-hidden="true"></span><span>Buscar</span>
            </a>
            <a class="tabbar__item<%= IsActive(active_section, "playlists") %>" href="<%= Url("/playlists.asp") %>">
                <span class="ico ico--list" aria-hidden="true"></span><span>Listas</span>
            </a>
            <% If IsAdmin() Then %>
            <a class="tabbar__item<%= IsActive(active_section, "admin") %>" href="<%= Url("/admin/default.asp") %>">
                <span class="ico ico--admin" aria-hidden="true"></span><span>Admin</span>
            </a>
            <% End If %>
        </nav>
    </div>
</div>

<div class="scrim" id="scrim" hidden></div>

<script src="<%= Url("/assets/js/player.js") %>"></script>
<script src="<%= Url("/assets/js/polimusic.js?v=20261018-scroll") %>"></script>
</body>
</html>
<%
    DBFinish
End Sub

'---------------------------------------------------------------------
' Plantilla para páginas públicas (login / registro)
'---------------------------------------------------------------------
Sub AuthTop(ByVal title)
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><%= E(title) %> · <%= APP_NAME %></title>
    <link rel="icon" href="<%= Url("/assets/img/logo.png") %>">
    <link rel="stylesheet" href="<%= Url("/assets/css/polimusic.css?v=20261018-scroll") %>">
</head>
<body class="auth-body" data-root="<%= E(SITE_ROOT) %>">
    <div class="auth">
        <a class="brand brand--big" href="<%= Url("/default.asp") %>">
            <span class="brand__mark" aria-hidden="true"></span>
            <span class="brand__text">Poli<b>Music</b></span>
        </a>
<%
End Sub

Sub AuthBottom()
%>
    </div>
<script src="<%= Url("/assets/js/polimusic.js?v=20261018-scroll") %>"></script>
</body>
</html>
<%
    DBFinish
End Sub

'---------------------------------------------------------------------
' Utilidades de plantilla
'---------------------------------------------------------------------
Dim active_section
Function IsActive(ByVal current, ByVal section)
    If LCase(NS(current)) = LCase(section) Then IsActive = " is-active" Else IsActive = ""
End Function

' Encabezado de sección con acción opcional a la derecha.
Sub SectionHeader(ByVal title, ByVal subtitle, ByVal actionUrl, ByVal actionText)
%>
    <header class="section-head">
        <div>
            <h1 class="section-title"><%= E(title) %></h1>
            <% If subtitle <> "" Then %><p class="section-sub"><%= E(subtitle) %></p><% End If %>
        </div>
        <% If actionUrl <> "" Then %>
        <a class="btn btn--soft" href="<%= E(actionUrl) %>"><%= E(actionText) %></a>
        <% End If %>
    </header>
<%
End Sub

' Estado vacío reutilizable.
Sub EmptyState(ByVal msg)
%>
    <div class="empty">
        <span class="empty__ico" aria-hidden="true"></span>
        <p><%= E(msg) %></p>
    </div>
<%
End Sub

'---------------------------------------------------------------------
' Tarjeta de canción (reproducible). Los atributos data-* los usa el
' reproductor en JavaScript.
'---------------------------------------------------------------------
Sub SongCard(ByVal idSong, ByVal songName, ByVal artists, ByVal cover, ByVal plays, ByVal src, ByVal detailUrl)
%>
    <article class="card" data-queue-item
             data-id="<%= idSong %>" data-title="<%= E(songName) %>"
             data-artist="<%= E(artists) %>"
             data-src="<%= E(AssetUrl(src, "")) %>"
             data-cover="<%= E(AssetUrl(cover, COVER_DEFAULT)) %>">
        <div class="card__art">
            <img src="<%= AssetUrl(cover, COVER_DEFAULT) %>" alt="Carátula de <%= E(songName) %>" loading="lazy">
            <button class="card__play" type="button" data-play="<%= idSong %>" aria-label="Reproducir <%= E(songName) %>">
                <span class="ico ico--play" aria-hidden="true"></span>
            </button>
        </div>
        <h3 class="card__title">
            <% If detailUrl <> "" Then %><a href="<%= E(detailUrl) %>"><%= E(songName) %></a><% Else %><%= E(songName) %><% End If %>
        </h3>
        <p class="card__meta"><%= E(artists) %></p>
        <p class="card__hint"><%= plays %> reproducciones</p>
    </article>
<%
End Sub

'---------------------------------------------------------------------
' Tarjeta de álbum
'---------------------------------------------------------------------
Sub AlbumCard(ByVal idAlbum, ByVal title, ByVal year, ByVal cover)
%>
    <a class="card card--album" href="<%= Url("/album_detail.asp?id=" & idAlbum) %>">
        <div class="card__art">
            <img src="<%= AssetUrl(cover, COVER_DEFAULT) %>" alt="Carátula de <%= E(title) %>" loading="lazy">
        </div>
        <h3 class="card__title"><%= E(title) %></h3>
        <p class="card__meta"><%= E(YearLabel(year)) %></p>
    </a>
<%
End Sub

Function YearLabel(ByVal year)
    If IsNull(year) Or NS(year) = "" Then YearLabel = "Año desconocido" Else YearLabel = CStr(year)
End Function

'---------------------------------------------------------------------
' Tarjeta de artista
'---------------------------------------------------------------------
Sub ArtistCard(ByVal idArtist, ByVal name, ByVal lastname, ByVal image)
    Dim full
    full = name
    If NS(lastname) <> "" Then full = full & " " & lastname
%>
    <a class="card card--artist" href="<%= Url("/artist_detail.asp?id=" & idArtist) %>">
        <div class="card__art card__art--round">
            <img src="<%= AssetUrl(image, COVER_DEFAULT) %>" alt="<%= E(full) %>" loading="lazy">
        </div>
        <h3 class="card__title"><%= E(full) %></h3>
        <p class="card__meta">Artista</p>
    </a>
<%
End Sub

'---------------------------------------------------------------------
' Tarjeta de playlist
'---------------------------------------------------------------------
Sub PlaylistCard(ByVal idPlaylist, ByVal title, ByVal owner, ByVal photo, ByVal ptype, ByVal songCount)
%>
    <a class="card card--playlist" href="<%= Url("/playlist_detail.asp?id=" & idPlaylist) %>">
        <div class="card__art">
            <img src="<%= AssetUrl(photo, COVER_PLAYLIST) %>" alt="Portada de <%= E(title) %>" loading="lazy">
        </div>
        <h3 class="card__title"><%= E(title) %></h3>
        <p class="card__meta"><%= E(owner) %> · <%= songCount %> canciones</p>
        <p class="card__badge"><%= E(PlaylistTypeLabel(ptype)) %></p>
    </a>
<%
End Sub

Function PlaylistTypeLabel(ByVal t)
    If CInt("0" & NS(t)) = PLAYLIST_PRIVATE Then PlaylistTypeLabel = "Privada" Else PlaylistTypeLabel = "Pública"
End Function

Function UserTypeLabel(ByVal t)
    If CInt("0" & NS(t)) = USER_TYPE_ADMIN Then UserTypeLabel = "Administrador" Else UserTypeLabel = "Usuario"
End Function

'---------------------------------------------------------------------
' Fila de canción (listas de reproducción, álbumes, playlists).
'   actions: HTML extra impreso a la derecha (ej. botón "quitar")
'---------------------------------------------------------------------
Sub SongRow(ByVal idSong, ByVal songName, ByVal artists, ByVal cover, ByVal plays, ByVal src, ByVal actions)
%>
    <li class="track" data-queue-item
        data-id="<%= idSong %>" data-title="<%= E(songName) %>" data-artist="<%= E(artists) %>"
        data-src="<%= E(AssetUrl(src, "")) %>" data-cover="<%= E(AssetUrl(cover, COVER_DEFAULT)) %>">
        <button class="track__play" type="button" data-play="<%= idSong %>" aria-label="Reproducir <%= E(songName) %>">
            <span class="ico ico--play" aria-hidden="true"></span>
        </button>
        <img class="track__art" src="<%= AssetUrl(cover, COVER_DEFAULT) %>" alt="" loading="lazy">
        <div class="track__info">
            <span class="track__title"><%= E(songName) %></span>
            <span class="track__artist"><%= E(artists) %></span>
        </div>
        <span class="track__plays"><%= plays %> <span class="muted">repros</span></span>
        <span class="track__actions"><%= actions %></span>
    </li>
<%
End Sub

'---------------------------------------------------------------------
' Selector de portada para playlists (imágenes incluidas en el proyecto)
'---------------------------------------------------------------------
Sub PhotoOptions(ByVal selected)
    Dim opts, i, v
    opts = Array("~/playlistImages/default.jpg", "~/playlistImages/playlist1.png", _
                 "~/playlistImages/playlist2.png", "~/playlistImages/playlist3.png", _
                 "~/playlistImages/playlist4.png", "~/playlistImages/playlist5.png")
    For i = 0 To UBound(opts)
        v = opts(i)
%>
        <option value="<%= E(v) %>"<%= Sel(v, selected) %>><%= E(Mid(v, InStrRev(v, "/") + 1)) %></option>
<%
    Next
End Sub

' Selector de imagen de artista (imágenes incluidas en el proyecto)
Sub ArtistOptions(ByVal selected)
    Dim opts, i, v
    opts = Array("~/ArtistImages/artist1.jpg", "~/ArtistImages/artist2.jpg", _
                 "~/ArtistImages/artist3.jpg", "~/ArtistImages/artist4.jpg", _
                 "~/ArtistImages/artist5.png")
    For i = 0 To UBound(opts)
        v = opts(i)
%>
        <option value="<%= E(v) %>"<%= Sel(v, selected) %>><%= E(Mid(v, InStrRev(v, "/") + 1)) %></option>
<%
    Next
End Sub

' Selector de carátula de álbum (imágenes incluidas en el proyecto)
Sub AlbumOptions(ByVal selected)
    Dim opts, i, v
    opts = Array("~/albumImages/album1.png", "~/albumImages/album2.png", _
                 "~/albumImages/album3.png", "~/albumImages/album4.png", _
                 "~/albumImages/album5.png")
    For i = 0 To UBound(opts)
        v = opts(i)
%>
        <option value="<%= E(v) %>"<%= Sel(v, selected) %>><%= E(Mid(v, InStrRev(v, "/") + 1)) %></option>
<%
    Next
End Sub

' Selector de avatar para usuarios (imágenes incluidas en el proyecto)
Sub AvatarOptions(ByVal selected)
    Dim opts, i, v
    opts = Array("~/userImages/default.jpg", "~/userImages/root.png", _
                 "~/userImages/username1.png", "~/userImages/jpulig.png")
    For i = 0 To UBound(opts)
        v = opts(i)
%>
        <option value="<%= E(v) %>"<%= Sel(v, selected) %>><%= E(Mid(v, InStrRev(v, "/") + 1)) %></option>
<%
    Next
End Sub

Function Sel(ByVal a, ByVal b)
    If NS(a) = NS(b) Then Sel = " selected" Else Sel = ""
End Function

'---------------------------------------------------------------------
' Paginador
'---------------------------------------------------------------------
Sub Pager(ByVal total, ByVal page, ByVal pageSize, ByVal baseUrl)
    Dim pages, i, sep
    pages = Int((total + pageSize - 1) / pageSize)
    If pages <= 1 Then Exit Sub
    sep = "?"
    If InStr(baseUrl, "?") > 0 Then sep = "&"
%>
    <nav class="pager" aria-label="Paginación">
        <% If page > 1 Then %>
        <a class="pager__link" href="<%= E(baseUrl & sep & "page=" & (page - 1)) %>">&laquo; Anterior</a>
        <% End If %>
        <% For i = 1 To pages %>
            <% If i = page Then %>
            <span class="pager__link is-active"><%= i %></span>
            <% Else %>
            <a class="pager__link" href="<%= E(baseUrl & sep & "page=" & i) %>"><%= i %></a>
            <% End If %>
        <% Next %>
        <% If page < pages Then %>
        <a class="pager__link" href="<%= E(baseUrl & sep & "page=" & (page + 1)) %>">Siguiente &raquo;</a>
        <% End If %>
    </nav>
<%
End Sub
%>
