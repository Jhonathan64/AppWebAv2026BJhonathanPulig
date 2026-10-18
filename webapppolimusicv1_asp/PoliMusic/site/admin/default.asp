<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="../includes/config.asp" -->
<!-- #include file="../includes/db.asp" -->
<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/ui.asp" -->
<!-- #include file="_tabs.asp" -->
<%
'=====================================================================
'  PoliMusic - admin/default.asp
'  Panel de administración: resumen del catálogo y accesos a módulos.
'  Acceso restringido a USER_TYPE = 1 (validado en el servidor).
'=====================================================================
RequireAdmin
DBOpen

Dim nUsers, nAdmins, nSongs, nAlbums, nArtists, nPlaylists, nPlays, rs

nUsers     = DBScalar("SELECT COUNT(*) FROM TBL_USER", Null, 0)
nAdmins    = DBScalar("SELECT COUNT(*) FROM TBL_USER WHERE USER_TYPE = ?", Array(P(adInteger, 0, USER_TYPE_ADMIN)), 0)
nSongs     = DBScalar("SELECT COUNT(*) FROM TBL_SONG", Null, 0)
nAlbums    = DBScalar("SELECT COUNT(*) FROM TBL_ALBUM", Null, 0)
nArtists   = DBScalar("SELECT COUNT(*) FROM TBL_ARTIST", Null, 0)
nPlaylists = DBScalar("SELECT COUNT(*) FROM TBL_PLAYLIST", Null, 0)
nPlays     = DBScalar("SELECT ISNULL(SUM(PLAYS), 0) FROM TBL_SONG", Null, 0)

PageTop "Panel de administración", "admin"
%>
<% SectionHeader "Panel de administración", "Gestión de usuarios, canciones, álbumes, artistas y playlists", Url("/home.asp"), "Volver al catálogo" %>
<% AdminTabs "Panel" %>

<section class="stats">
    <div class="stat"><div class="stat__num"><%= nUsers %></div><div class="stat__label">Usuarios (<%= nAdmins %> administradores)</div></div>
    <div class="stat"><div class="stat__num"><%= nSongs %></div><div class="stat__label">Canciones</div></div>
    <div class="stat"><div class="stat__num"><%= nAlbums %></div><div class="stat__label">Álbumes</div></div>
    <div class="stat"><div class="stat__num"><%= nArtists %></div><div class="stat__label">Artistas</div></div>
    <div class="stat"><div class="stat__num"><%= nPlaylists %></div><div class="stat__label">Playlists</div></div>
    <div class="stat"><div class="stat__num"><%= nPlays %></div><div class="stat__label">Reproducciones totales</div></div>
</section>

<section class="grid grid--wide">
    <a class="panel" href="<%= Url("/admin/users.asp") %>">
        <h3 class="panel__title">Usuarios</h3>
        <p class="panel__sub">Crear, editar, cambiar tipo y eliminar cuentas.</p>
        <span class="btn btn--soft btn--sm">Gestionar</span>
    </a>
    <a class="panel" href="<%= Url("/admin/songs.asp") %>">
        <h3 class="panel__title">Canciones</h3>
        <p class="panel__sub">Alta de archivos de audio y contador de reproducciones.</p>
        <span class="btn btn--soft btn--sm">Gestionar</span>
    </a>
    <a class="panel" href="<%= Url("/admin/albums.asp") %>">
        <h3 class="panel__title">Álbumes</h3>
        <p class="panel__sub">Año de lanzamiento, carátula y tracklist.</p>
        <span class="btn btn--soft btn--sm">Gestionar</span>
    </a>
    <a class="panel" href="<%= Url("/admin/artists.asp") %>">
        <h3 class="panel__title">Artistas</h3>
        <p class="panel__sub">Nombres, apellidos e imagen de perfil.</p>
        <span class="btn btn--soft btn--sm">Gestionar</span>
    </a>
    <a class="panel" href="<%= Url("/admin/playlists.asp") %>">
        <h3 class="panel__title">Playlists</h3>
        <p class="panel__sub">Listas de todos los usuarios, canciones incluidas.</p>
        <span class="btn btn--soft btn--sm">Gestionar</span>
    </a>
</section>

<section>
    <% SectionHeader "Últimas canciones registradas", "Ordenadas por ID", Url("/admin/songs.asp"), "Ver todas" %>
    <div class="table-wrap">
    <table class="table">
        <thead><tr><th>#</th><th>Canción</th><th>Archivo</th><th>Reproducciones</th></tr></thead>
        <tbody>
        <%
        Set rs = DBQuery("SELECT TOP 5 ID_SONG, SONG_NAME, SONG_PATH, ISNULL(PLAYS,0) AS PLAYS FROM TBL_SONG ORDER BY ID_SONG DESC", Null)
        If rs.EOF Then
        %>
            <tr><td colspan="4" class="muted">Sin canciones registradas.</td></tr>
        <%
        Else
            Do While Not rs.EOF
        %>
            <tr>
                <td><%= rs("ID_SONG") %></td>
                <td><strong><%= E(rs("SONG_NAME")) %></strong></td>
                <td class="muted"><%= E(rs("SONG_PATH")) %></td>
                <td><%= rs("PLAYS") %></td>
            </tr>
        <%
                rs.MoveNext
            Loop
        End If
        RSClose rs
        %>
        </tbody>
    </table>
    </div>
</section>

<section>
    <% SectionHeader "Últimos usuarios registrados", "Ordenados por ID", Url("/admin/users.asp"), "Ver todos" %>
    <div class="table-wrap">
    <table class="table">
        <thead><tr><th>#</th><th>Usuario</th><th>Correo</th><th>Tipo</th></tr></thead>
        <tbody>
        <%
        Set rs = DBQuery("SELECT TOP 5 ID_USER, USERNAME, EMAIL, USER_TYPE FROM TBL_USER ORDER BY ID_USER DESC", Null)
        Do While Not rs.EOF
        %>
            <tr>
                <td><%= rs("ID_USER") %></td>
                <td><strong><%= E(rs("USERNAME")) %></strong></td>
                <td class="muted"><%= E(rs("EMAIL")) %></td>
                <td><span class="pill<%= IIf(CInt(rs("USER_TYPE")) = USER_TYPE_ADMIN, " pill--admin", "") %>"><%= E(UserTypeLabel(rs("USER_TYPE"))) %></span></td>
            </tr>
        <%
            rs.MoveNext
        Loop
        RSClose rs
        %>
        </tbody>
    </table>
    </div>
</section>
<%
PageBottom
%>
