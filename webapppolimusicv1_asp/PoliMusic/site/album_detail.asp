<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="includes/config.asp" -->
<!-- #include file="includes/db.asp" -->
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/ui.asp" -->
<%
'=====================================================================
'  PoliMusic - album_detail.asp : detalle de un álbum y su tracklist
'=====================================================================
RequireLogin
DBOpen

Dim idAlbum, rs, ok
idAlbum = GetInt("id", 0)

Set rs = DBQuery("SELECT A.ID_ALBUM, A.TITLE_ALBUM, A.RELEASE_YEAR, A.ALBUM_IMAGE_PATH, " & _
                 "(SELECT COUNT(*) FROM TBL_TRACKLIST T WHERE T.ID_ALBUM = A.ID_ALBUM) AS NSONGS " & _
                 "FROM TBL_ALBUM A WHERE A.ID_ALBUM = ?", Array(P(adInteger, 0, idAlbum)))
ok = Not rs.EOF

If Not ok Then
    RSClose rs
    SetFlash "warn", "El álbum solicitado no existe."
    Response.Redirect Url("/albums.asp")
    Response.End
End If

Dim aTitle, aYear, aCover, aSongs
aTitle = rs("TITLE_ALBUM")
aYear  = rs("RELEASE_YEAR")
aCover = rs("ALBUM_IMAGE_PATH")
aSongs = rs("NSONGS")
RSClose rs

PageTop aTitle, "albums"
%>
<section class="hero">
    <div class="hero__art">
        <img src="<%= AssetUrl(aCover, COVER_DEFAULT) %>" alt="Carátula de <%= E(aTitle) %>">
    </div>
    <div>
        <span class="hero__eyebrow">Álbum</span>
        <h1 class="hero__title"><%= E(aTitle) %></h1>
        <div class="hero__meta">
            <span><%= E(YearLabel(aYear)) %></span>
            <span><%= aSongs %> canciones</span>
        </div>
        <div class="hero__actions">
            <button class="btn btn--primary" type="button" data-play-all>
                <span class="ico ico--play" aria-hidden="true"></span> Reproducir álbum
            </button>
            <a class="btn btn--ghost" href="<%= Url("/albums.asp") %>">
                <span class="ico ico--back" aria-hidden="true"></span> Volver a álbumes
            </a>
        </div>
    </div>
</section>

<section data-queue>
    <% SectionHeader "Canciones del álbum", "En orden de tracklist", "", "" %>
    <%
    Set rs = DBQuery("SELECT S.ID_SONG, S.SONG_NAME, S.SONG_PATH, ISNULL(S.PLAYS,0) AS PLAYS, " & _
                     SQL_SONG_ARTISTS & " AS ARTISTS, " & SQL_SONG_COVER & " AS COVER " & _
                     "FROM TBL_TRACKLIST T INNER JOIN TBL_SONG S ON S.ID_SONG = T.ID_SONG " & _
                     "WHERE T.ID_ALBUM = ? ORDER BY S.SONG_NAME", Array(P(adInteger, 0, idAlbum)))
    If rs.EOF Then
        EmptyState "Este álbum todavía no tiene canciones asignadas."
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
<%
PageBottom
%>
