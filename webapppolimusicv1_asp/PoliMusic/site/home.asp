<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="includes/config.asp" -->
<!-- #include file="includes/db.asp" -->
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/ui.asp" -->
<%
'=====================================================================
'  PoliMusic - home.asp
'  Pantalla principal: bienvenida, catálogo destacado y playlists.
'=====================================================================
RequireLogin
DBOpen

Dim hora, saludo
hora = Hour(Now())
If hora < 12 Then
    saludo = "Buenos días"
ElseIf hora < 19 Then
    saludo = "Buenas tardes"
Else
    saludo = "Buenas noches"
End If

Dim rs, totalSongs, totalAlbums, totalArtists
totalSongs   = DBScalar("SELECT COUNT(*) FROM TBL_SONG", Null, 0)
totalAlbums  = DBScalar("SELECT COUNT(*) FROM TBL_ALBUM", Null, 0)
totalArtists = DBScalar("SELECT COUNT(*) FROM TBL_ARTIST", Null, 0)

PageTop "Inicio", "home"
%>
<section class="hero">
    <div class="hero__art hero__art--round">
        <img src="<%= AssetUrl(CurrentUserPhoto(), AVATAR_DEFAULT) %>" alt="">
    </div>
    <div>
        <span class="hero__eyebrow">Tu biblioteca</span>
        <h1 class="hero__title"><%= E(saludo) %>, <%= E(CurrentUserName()) %></h1>
        <div class="hero__meta">
            <span><%= totalSongs %> canciones</span>
            <span><%= totalAlbums %> álbumes</span>
            <span><%= totalArtists %> artistas</span>
        </div>
        <div class="hero__actions">
            <a class="btn btn--primary" href="<%= Url("/songs.asp") %>">
                <span class="ico ico--play" aria-hidden="true"></span> Explorar canciones
            </a>
            <a class="btn btn--soft" href="<%= Url("/playlists.asp") %>">Mis playlists</a>
            <% If IsAdmin() Then %>
            <a class="btn btn--ghost" href="<%= Url("/admin/default.asp") %>">Panel de administración</a>
            <% End If %>
        </div>
    </div>
</section>

<!-- ---------- Canciones más escuchadas ---------- -->
<section>
    <% SectionHeader "Más escuchadas", "Las canciones con más reproducciones del catálogo", Url("/songs.asp"), "Ver todas" %>
    <div class="grid" data-queue>
        <%
        Set rs = DBQuery("SELECT TOP 10 S.ID_SONG, S.SONG_NAME, S.SONG_PATH, ISNULL(S.PLAYS,0) AS PLAYS, " & _
                         SQL_SONG_ARTISTS & " AS ARTISTS, " & SQL_SONG_COVER & " AS COVER " & _
                         "FROM TBL_SONG S ORDER BY ISNULL(S.PLAYS,0) DESC, S.SONG_NAME", Null)
        If rs.EOF Then
            EmptyState "Todavía no hay canciones en el catálogo."
        Else
            Do While Not rs.EOF
                SongCard rs("ID_SONG"), rs("SONG_NAME"), rs("ARTISTS"), rs("COVER"), rs("PLAYS"), rs("SONG_PATH"), Url("/songs.asp#song" & rs("ID_SONG"))
                rs.MoveNext
            Loop
        End If
        RSClose rs
        %>
    </div>
</section>

<!-- ---------- Álbumes ---------- -->
<section>
    <% SectionHeader "Álbumes", "Colecciones publicadas por año", Url("/albums.asp"), "Ver todos" %>
    <div class="grid">
        <%
        Set rs = DBQuery("SELECT TOP 6 A.ID_ALBUM, A.TITLE_ALBUM, A.RELEASE_YEAR, A.ALBUM_IMAGE_PATH, " & _
                         "(SELECT COUNT(*) FROM TBL_TRACKLIST T WHERE T.ID_ALBUM = A.ID_ALBUM) AS NSONGS " & _
                         "FROM TBL_ALBUM A ORDER BY A.TITLE_ALBUM", Null)
        If rs.EOF Then
            EmptyState "No hay álbumes registrados."
        Else
            Do While Not rs.EOF
                AlbumCard rs("ID_ALBUM"), rs("TITLE_ALBUM"), rs("RELEASE_YEAR"), rs("ALBUM_IMAGE_PATH")
                rs.MoveNext
            Loop
        End If
        RSClose rs
        %>
    </div>
</section>

<!-- ---------- Artistas ---------- -->
<section>
    <% SectionHeader "Artistas", "Intérpretes disponibles en PoliMusic", Url("/artists.asp"), "Ver todos" %>
    <div class="grid">
        <%
        Set rs = DBQuery("SELECT TOP 6 AR.ID_ARTIST, AR.ARTIST_NAME, AR.ARTIST_LASTNAME, AR.ARTIST_IMAGE, " & _
                         "(SELECT COUNT(*) FROM TBL_PLAYER P WHERE P.ID_ARTIST = AR.ID_ARTIST) AS NSONGS " & _
                         "FROM TBL_ARTIST AR ORDER BY AR.ARTIST_NAME, AR.ARTIST_LASTNAME", Null)
        If rs.EOF Then
            EmptyState "No hay artistas registrados."
        Else
            Do While Not rs.EOF
                ArtistCard rs("ID_ARTIST"), rs("ARTIST_NAME"), rs("ARTIST_LASTNAME"), rs("ARTIST_IMAGE")
                rs.MoveNext
            Loop
        End If
        RSClose rs
        %>
    </div>
</section>

<!-- ---------- Playlists del usuario ---------- -->
<section>
    <% SectionHeader "Mis playlists", "Crea listas y agrega tus canciones favoritas", Url("/playlists.asp"), "Administrar" %>
    <div class="grid">
        <%
        Set rs = DBQuery("SELECT TOP 6 PL.ID_PLAYLIST, PL.TITLE, PL.PHOTO, PL.TYPE, PL.CREATION_DATE, " & _
                         "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG PS WHERE PS.ID_PLAYLIST = PL.ID_PLAYLIST) AS NSONGS, " & _
                         "(SELECT U.USERNAME FROM TBL_USER U WHERE U.ID_USER = PL.ID_USER) AS OWNER " & _
                         "FROM TBL_PLAYLIST PL WHERE PL.ID_USER = ? ORDER BY PL.CREATION_DATE DESC", _
                         Array(P(adInteger, 0, CurrentUserId())))
        If rs.EOF Then
            EmptyState "Aún no tienes playlists. Crea una desde «Mis playlists»."
        Else
            Do While Not rs.EOF
                PlaylistCard rs("ID_PLAYLIST"), rs("TITLE"), rs("OWNER"), rs("PHOTO"), rs("TYPE"), rs("NSONGS")
                rs.MoveNext
            Loop
        End If
        RSClose rs
        %>
    </div>
</section>

<!-- ---------- Playlists públicas de la comunidad ---------- -->
<section>
    <% SectionHeader "Listas públicas", "Compartidas por otros usuarios de PoliMusic", Url("/playlists.asp?ver=publicas"), "Ver listas públicas" %>
    <div class="grid">
        <%
        Set rs = DBQuery("SELECT TOP 6 PL.ID_PLAYLIST, PL.TITLE, PL.PHOTO, PL.TYPE, " & _
                         "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG PS WHERE PS.ID_PLAYLIST = PL.ID_PLAYLIST) AS NSONGS, " & _
                         "(SELECT U.USERNAME FROM TBL_USER U WHERE U.ID_USER = PL.ID_USER) AS OWNER " & _
                         "FROM TBL_PLAYLIST PL WHERE PL.TYPE = ? AND PL.ID_USER <> ? ORDER BY PL.CREATION_DATE DESC", _
                         Array(P(adInteger, 0, PLAYLIST_PUBLIC), P(adInteger, 0, CurrentUserId())))
        If rs.EOF Then
            EmptyState "Todavía no hay listas públicas de otros usuarios."
        Else
            Do While Not rs.EOF
                PlaylistCard rs("ID_PLAYLIST"), rs("TITLE"), rs("OWNER"), rs("PHOTO"), rs("TYPE"), rs("NSONGS")
                rs.MoveNext
            Loop
        End If
        RSClose rs
        %>
    </div>
</section>
<%
PageBottom
%>
