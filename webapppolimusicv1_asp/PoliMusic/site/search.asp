<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="includes/config.asp" -->
<!-- #include file="includes/db.asp" -->
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/ui.asp" -->
<%
'=====================================================================
'  PoliMusic - search.asp
'  Buscador global: canciones, álbumes, artistas y playlists.
'  Todas las búsquedas usan LIKE con parámetros (sin concatenar texto
'  del usuario dentro del SQL).
'=====================================================================
RequireLogin
DBOpen

Dim q, likeQ, rs, found
q     = GetStr("q", "", 80)
likeQ = "%" & q & "%"
found = 0

PageTop "Buscar", "search"
%>
<section class="hero">
    <div class="hero__art hero__art--round">
        <img src="<%= Url("/assets/img/logo.png") %>" alt="">
    </div>
    <div>
        <span class="hero__eyebrow">Buscador</span>
        <h1 class="hero__title">¿Qué quieres escuchar?</h1>
        <form class="hero__actions" method="get" action="<%= Url("/search.asp") %>">
            <div class="searchbox" style="max-width:none;flex:1 1 320px">
                <span class="ico ico--search" aria-hidden="true"></span>
                <input type="search" name="q" value="<%= E(q) %>" placeholder="Canción, álbum, artista o playlist..." autofocus>
            </div>
            <button class="btn btn--primary" type="submit">Buscar</button>
        </form>
    </div>
</section>

<% If q = "" Then %>
    <% EmptyState "Escribe algo en el buscador para encontrar música en PoliMusic." %>
<% Else %>

<!-- ---------------- Canciones ---------------- -->
<section data-queue>
    <%
    Set rs = DBQuery("SELECT TOP 12 S.ID_SONG, S.SONG_NAME, S.SONG_PATH, ISNULL(S.PLAYS,0) AS PLAYS, " & _
                     SQL_SONG_ARTISTS & " AS ARTISTS, " & SQL_SONG_COVER & " AS COVER " & _
                     "FROM TBL_SONG S WHERE S.SONG_NAME LIKE ? OR EXISTS (SELECT 1 FROM TBL_PLAYER P " & _
                     "INNER JOIN TBL_ARTIST A ON A.ID_ARTIST = P.ID_ARTIST WHERE P.ID_SONG = S.ID_SONG " & _
                     "AND (A.ARTIST_NAME LIKE ? OR ISNULL(A.ARTIST_LASTNAME,'') LIKE ?)) " & _
                     "ORDER BY S.SONG_NAME", _
                     Array(P(adVarChar, 80, likeQ), P(adVarChar, 80, likeQ), P(adVarChar, 80, likeQ)))
    %>
    <% SectionHeader "Canciones", "Coincidencias por título o intérprete", "", "" %>
    <% If rs.EOF Then %>
        <% EmptyState "Sin coincidencias en canciones." %>
    <% Else %>
    <ul class="track-list">
        <% Do While Not rs.EOF
            found = found + 1
            SongRow rs("ID_SONG"), rs("SONG_NAME"), rs("ARTISTS"), rs("COVER"), rs("PLAYS"), rs("SONG_PATH"), ""
            rs.MoveNext
        Loop %>
    </ul>
    <% End If %>
    <% RSClose rs %>
</section>

<!-- ---------------- Álbumes ---------------- -->
<section>
    <% SectionHeader "Álbumes", "Coincidencias por título", "", "" %>
    <div class="grid grid--wide">
    <%
    Set rs = DBQuery("SELECT TOP 12 A.ID_ALBUM, A.TITLE_ALBUM, A.RELEASE_YEAR, A.ALBUM_IMAGE_PATH " & _
                     "FROM TBL_ALBUM A WHERE A.TITLE_ALBUM LIKE ? ORDER BY A.TITLE_ALBUM", _
                     Array(P(adVarChar, 80, likeQ)))
    If rs.EOF Then
        EmptyState "Sin coincidencias en álbumes."
    Else
        Do While Not rs.EOF
            found = found + 1
            AlbumCard rs("ID_ALBUM"), rs("TITLE_ALBUM"), rs("RELEASE_YEAR"), rs("ALBUM_IMAGE_PATH")
            rs.MoveNext
        Loop
    End If
    RSClose rs
    %>
    </div>
</section>

<!-- ---------------- Artistas ---------------- -->
<section>
    <% SectionHeader "Artistas", "Coincidencias por nombre o apellido", "", "" %>
    <div class="grid grid--wide">
    <%
    Set rs = DBQuery("SELECT TOP 12 AR.ID_ARTIST, AR.ARTIST_NAME, AR.ARTIST_LASTNAME, AR.ARTIST_IMAGE " & _
                     "FROM TBL_ARTIST AR WHERE AR.ARTIST_NAME LIKE ? OR ISNULL(AR.ARTIST_LASTNAME,'') LIKE ? " & _
                     "ORDER BY AR.ARTIST_NAME, AR.ARTIST_LASTNAME", _
                     Array(P(adVarChar, 80, likeQ), P(adVarChar, 80, likeQ)))
    If rs.EOF Then
        EmptyState "Sin coincidencias en artistas."
    Else
        Do While Not rs.EOF
            found = found + 1
            ArtistCard rs("ID_ARTIST"), rs("ARTIST_NAME"), rs("ARTIST_LASTNAME"), rs("ARTIST_IMAGE")
            rs.MoveNext
        Loop
    End If
    RSClose rs
    %>
    </div>
</section>

<!-- ---------------- Playlists ---------------- -->
<section>
    <% SectionHeader "Playlists", "Tus listas y las públicas de otros usuarios", "", "" %>
    <div class="grid grid--wide">
    <%
    Set rs = DBQuery("SELECT TOP 12 PL.ID_PLAYLIST, PL.TITLE, PL.PHOTO, PL.TYPE, " & _
                     "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG PS WHERE PS.ID_PLAYLIST = PL.ID_PLAYLIST) AS NSONGS, " & _
                     "(SELECT U.USERNAME FROM TBL_USER U WHERE U.ID_USER = PL.ID_USER) AS OWNER " & _
                     "FROM TBL_PLAYLIST PL WHERE PL.TITLE LIKE ? AND (PL.TYPE = ? OR PL.ID_USER = ?) " & _
                     "ORDER BY PL.CREATION_DATE DESC", _
                     Array(P(adVarChar, 80, likeQ), P(adInteger, 0, PLAYLIST_PUBLIC), P(adInteger, 0, CurrentUserId())))
    If rs.EOF Then
        EmptyState "Sin coincidencias en playlists."
    Else
        Do While Not rs.EOF
            found = found + 1
            PlaylistCard rs("ID_PLAYLIST"), rs("TITLE"), rs("OWNER"), rs("PHOTO"), rs("TYPE"), rs("NSONGS")
            rs.MoveNext
        Loop
    End If
    RSClose rs
    %>
    </div>
</section>

<% If found = 0 Then %>
    <% EmptyState "No encontramos resultados para «" & q & "». Prueba con otra palabra." %>
<% End If %>

<% End If %>
<%
PageBottom
%>
