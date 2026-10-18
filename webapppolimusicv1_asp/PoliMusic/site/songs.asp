<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="includes/config.asp" -->
<!-- #include file="includes/db.asp" -->
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/ui.asp" -->
<%
'=====================================================================
'  PoliMusic - songs.asp
'  Catálogo completo de canciones (con paginación y filtro opcional).
'=====================================================================
RequireLogin
DBOpen

Dim q, page, total, pages, fromRow, toRow, rs, base
q    = GetStr("q", "", 80)
page = GetInt("page", 1)
If page < 1 Then page = 1

' WHERE parametrizado (opcional)
Dim whereSql, params, likeQ
whereSql = ""
likeQ    = "%" & q & "%"

If q <> "" Then
    whereSql = " WHERE S.SONG_NAME LIKE ? OR EXISTS (SELECT 1 FROM TBL_PLAYER P " & _
               "INNER JOIN TBL_ARTIST A ON A.ID_ARTIST = P.ID_ARTIST WHERE P.ID_SONG = S.ID_SONG " & _
               "AND (A.ARTIST_NAME LIKE ? OR ISNULL(A.ARTIST_LASTNAME, '') LIKE ?))"
    params = Array(P(adVarChar, 80, likeQ), P(adVarChar, 80, likeQ), P(adVarChar, 80, likeQ))
Else
    params = Null
End If

total = CLng(DBScalar("SELECT COUNT(*) FROM TBL_SONG S" & whereSql, params, 0))
pages = Int((total + PAGE_SIZE - 1) / PAGE_SIZE)
If pages < 1 Then pages = 1
If page > pages Then page = pages

fromRow = (page - 1) * PAGE_SIZE + 1
toRow   = page * PAGE_SIZE

' Paginación con ROW_NUMBER(): compatible con SQL Server 2008 en adelante.
Dim sql, fullParams
sql = "SELECT * FROM (SELECT S.ID_SONG, S.SONG_NAME, S.SONG_PATH, ISNULL(S.PLAYS,0) AS PLAYS, " & _
      SQL_SONG_ARTISTS & " AS ARTISTS, " & SQL_SONG_COVER & " AS COVER, " & _
      "ROW_NUMBER() OVER (ORDER BY S.SONG_NAME) AS RN FROM TBL_SONG S" & whereSql & _
      ") X WHERE X.RN BETWEEN ? AND ? ORDER BY X.RN"

If IsArray(params) Then
    fullParams = Array(params(0), params(1), params(2), P(adInteger, 0, fromRow), P(adInteger, 0, toRow))
Else
    fullParams = Array(P(adInteger, 0, fromRow), P(adInteger, 0, toRow))
End If

base = Url("/songs.asp")
If q <> "" Then base = base & "?q=" & Server.URLEncode(q)

PageTop "Canciones", "songs"
%>
<p class="lead">Hola, <strong><%= E(CurrentUserName()) %></strong>. Disfruta tu música.</p>
<% If IsAdmin() Then
    SectionHeader "Canciones", total & " canciones en el catálogo", Url("/admin/songs.asp"), "Administrar canciones"
Else
    SectionHeader "Canciones", total & " canciones en el catálogo", "", ""
End If %>

<form class="toolbar" method="get" action="<%= Url("/songs.asp") %>">
    <div class="searchbox">
        <span class="ico ico--search" aria-hidden="true"></span>
        <input type="search" name="q" value="<%= E(q) %>" placeholder="Filtrar por título o artista...">
    </div>
    <button class="btn btn--soft" type="submit">Filtrar</button>
    <% If q <> "" Then %><a class="btn btn--ghost" href="<%= Url("/songs.asp") %>">Quitar filtro</a><% End If %>
    <button class="btn btn--primary" type="button" data-play-all>
        <span class="ico ico--play" aria-hidden="true"></span> Reproducir todo
    </button>
</form>

<div data-queue>
<%
Set rs = DBQuery(sql, fullParams)
If rs.EOF Then
    EmptyState "No se encontraron canciones con ese criterio."
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
</div>

<% Pager total, page, PAGE_SIZE, base %>

<p class="muted">Consejo: pulsa el botón de reproducción de cualquier canción para encolar toda la lista.</p>
<%
PageBottom
%>
