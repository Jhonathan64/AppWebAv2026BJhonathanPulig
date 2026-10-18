<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="includes/config.asp" -->
<!-- #include file="includes/db.asp" -->
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/ui.asp" -->
<%
'=====================================================================
'  PoliMusic - artist_detail.asp : detalle de artista
'  Muestra sus canciones (TBL_PLAYER) y los álbumes en los que aparece.
'=====================================================================
RequireLogin
DBOpen

Dim idArtist, rs, ok, aName, aLast, aImage
idArtist = GetInt("id", 0)

Set rs = DBQuery("SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE FROM TBL_ARTIST WHERE ID_ARTIST = ?", _
                 Array(P(adInteger, 0, idArtist)))
ok = Not rs.EOF
If ok Then
    aName  = rs("ARTIST_NAME")
    aLast  = rs("ARTIST_LASTNAME")
    aImage = rs("ARTIST_IMAGE")
End If
RSClose rs

If Not ok Then
    SetFlash "warn", "El artista solicitado no existe."
    Response.Redirect Url("/artists.asp")
    Response.End
End If

Dim fullName
fullName = aName
If NS(aLast) <> "" Then fullName = fullName & " " & aLast

PageTop fullName, "artists"
%>
<section class="hero">
    <div class="hero__art hero__art--round">
        <img src="<%= AssetUrl(aImage, COVER_DEFAULT) %>" alt="<%= E(fullName) %>">
    </div>
    <div>
        <span class="hero__eyebrow">Artista</span>
        <h1 class="hero__title"><%= E(fullName) %></h1>
        <div class="hero__meta">
            <span><%= DBScalar("SELECT COUNT(*) FROM TBL_PLAYER WHERE ID_ARTIST = ?", Array(P(adInteger, 0, idArtist)), 0) %> canciones</span>
        </div>
        <div class="hero__actions">
            <button class="btn btn--primary" type="button" data-play-all>
                <span class="ico ico--play" aria-hidden="true"></span> Reproducir sus canciones
            </button>
            <a class="btn btn--ghost" href="<%= Url("/artists.asp") %>">
                <span class="ico ico--back" aria-hidden="true"></span> Volver a artistas
            </a>
        </div>
    </div>
</section>

<section data-queue>
    <% SectionHeader "Canciones", "Interpretadas por " & fullName, "", "" %>
    <%
    Set rs = DBQuery("SELECT S.ID_SONG, S.SONG_NAME, S.SONG_PATH, ISNULL(S.PLAYS,0) AS PLAYS, " & _
                     SQL_SONG_ARTISTS & " AS ARTISTS, " & SQL_SONG_COVER & " AS COVER " & _
                     "FROM TBL_PLAYER P INNER JOIN TBL_SONG S ON S.ID_SONG = P.ID_SONG " & _
                     "WHERE P.ID_ARTIST = ? ORDER BY S.SONG_NAME", Array(P(adInteger, 0, idArtist)))
    If rs.EOF Then
        EmptyState "Este artista todavía no tiene canciones asociadas."
    Else
    %>
    <ul class="track-list">
        <% Do While Not rs.EOF %>
            <% SongRow rs("ID_SONG"), rs("SONG_NAME"), rs("ARTISTS"), rs("COVER"), rs("PLAYS"), rs("SONG_PATH"), "" %>
        <%  rs.MoveNext
        Loop %>
    </ul>
    <%
    End If
    RSClose rs
    %>
</section>

<section>
    <% SectionHeader "Álbumes", "Álbumes donde participa", "", "" %>
    <div class="grid grid--wide">
        <%
        Set rs = DBQuery("SELECT DISTINCT A.ID_ALBUM, A.TITLE_ALBUM, A.RELEASE_YEAR, A.ALBUM_IMAGE_PATH " & _
                         "FROM TBL_PLAYER P INNER JOIN TBL_TRACKLIST T ON T.ID_SONG = P.ID_SONG " & _
                         "INNER JOIN TBL_ALBUM A ON A.ID_ALBUM = T.ID_ALBUM " & _
                         "WHERE P.ID_ARTIST = ? ORDER BY A.TITLE_ALBUM", Array(P(adInteger, 0, idArtist)))
        If rs.EOF Then
            EmptyState "Sin álbumes asociados por ahora."
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
<%
PageBottom
%>
