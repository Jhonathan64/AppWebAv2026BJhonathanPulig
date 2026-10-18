<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="includes/config.asp" -->
<!-- #include file="includes/db.asp" -->
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/ui.asp" -->
<%
'=====================================================================
'  PoliMusic - playlist_detail.asp
'  Detalle de playlist: reproducir, agregar y quitar canciones.
'  Los permisos se validan en el servidor (sólo el dueño o un admin
'  pueden modificar; las listas privadas no son visibles para otros).
'=====================================================================
RequireLogin
DBOpen

Dim idPl, action, errMsg, canEdit, rs, ok
Dim plTitle, plPhoto, plType, plDate, plOwner, plOwnerId

idPl   = GetInt("id", 0)
action = LCase(GetStr("action", "", 20))
errMsg = ""

' --- Datos de la playlist -------------------------------------------
Set rs = DBQuery("SELECT PL.ID_PLAYLIST, PL.TITLE, PL.PHOTO, PL.TYPE, PL.CREATION_DATE, PL.ID_USER, " & _
                 "(SELECT U.USERNAME FROM TBL_USER U WHERE U.ID_USER = PL.ID_USER) AS OWNER " & _
                 "FROM TBL_PLAYLIST PL WHERE PL.ID_PLAYLIST = ?", Array(P(adInteger, 0, idPl)))
ok = Not rs.EOF
If ok Then
    plTitle   = rs("TITLE")
    plPhoto   = rs("PHOTO")
    plType    = CInt(rs("TYPE"))
    plDate    = rs("CREATION_DATE")
    plOwner   = rs("OWNER")
    plOwnerId = CLng(rs("ID_USER"))
End If
RSClose rs

If Not ok Then
    SetFlash "warn", "La playlist solicitada no existe."
    Response.Redirect Url("/playlists.asp")
    Response.End
End If

canEdit = OwnsPlaylist(idPl)          ' dueño o administrador
If Not canEdit And plType = PLAYLIST_PRIVATE Then
    AccessDenied "Esta playlist es privada y pertenece a otro usuario."
End If

' --- Acciones -------------------------------------------------------
If UCase(NS(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then
    CheckCsrf
    Dim idSong : idSong = GetInt("idSong", 0)

    If Not canEdit Then AccessDenied "No tienes permisos para modificar esta playlist."

    Select Case action
        Case "add"
            If idSong <= 0 Then
                errMsg = "Selecciona una canción válida."
            ElseIf DBExists("SELECT 1 FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = ? AND ID_SONG = ?", _
                            Array(P(adInteger, 0, idPl), P(adInteger, 0, idSong))) Then
                errMsg = "Esa canción ya está en la playlist."
            Else
                DBExec "INSERT INTO TBL_PLAYLIST_SONG (ID_PLAYLIST, ID_SONG) VALUES (?, ?)", _
                       Array(P(adInteger, 0, idPl), P(adInteger, 0, idSong))
                SetFlash "ok", "Canción agregada a la playlist."
                Response.Redirect Url("/playlist_detail.asp?id=" & idPl)
                Response.End
            End If

        Case "remove"
            If idSong > 0 Then
                DBExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = ? AND ID_SONG = ?", _
                       Array(P(adInteger, 0, idPl), P(adInteger, 0, idSong))
                SetFlash "ok", "Canción eliminada de la playlist."
            End If
            Response.Redirect Url("/playlist_detail.asp?id=" & idPl)
            Response.End
    End Select
End If

PageTop plTitle, "playlists"
%>
<section class="hero">
    <div class="hero__art">
        <img src="<%= AssetUrl(plPhoto, COVER_PLAYLIST) %>" alt="Portada de <%= E(plTitle) %>">
    </div>
    <div>
        <span class="hero__eyebrow">Playlist <%= E(PlaylistTypeLabel(plType)) %></span>
        <h1 class="hero__title"><%= E(plTitle) %></h1>
        <div class="hero__meta">
            <span>De <%= E(plOwner) %></span>
            <span>Creada el <%= E(FormatDate(plDate)) %></span>
            <span><%= DBScalar("SELECT COUNT(*) FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = ?", Array(P(adInteger, 0, idPl)), 0) %> canciones</span>
        </div>
        <div class="hero__actions">
            <button class="btn btn--primary" type="button" data-play-all>
                <span class="ico ico--play" aria-hidden="true"></span> Reproducir lista
            </button>
            <% If canEdit Then %>
            <a class="btn btn--soft" href="<%= Url("/playlists.asp?edit=" & idPl) %>">
                <span class="ico ico--edit" aria-hidden="true"></span> Editar datos
            </a>
            <% End If %>
            <a class="btn btn--ghost" href="<%= Url("/playlists.asp") %>">
                <span class="ico ico--back" aria-hidden="true"></span> Volver
            </a>
        </div>
    </div>
</section>

<% If errMsg <> "" Then %>
<div class="flash flash--error" role="alert">
    <span class="flash__icon" aria-hidden="true"></span><span><%= E(errMsg) %></span>
</div>
<% End If %>

<!-- ---------- Canciones de la playlist ---------- -->
<section data-queue>
    <% SectionHeader "Canciones de la lista", "En el orden en que se agregaron", "", "" %>
    <%
    Set rs = DBQuery("SELECT S.ID_SONG, S.SONG_NAME, S.SONG_PATH, ISNULL(S.PLAYS,0) AS PLAYS, " & _
                     SQL_SONG_ARTISTS & " AS ARTISTS, " & SQL_SONG_COVER & " AS COVER " & _
                     "FROM TBL_PLAYLIST_SONG PS INNER JOIN TBL_SONG S ON S.ID_SONG = PS.ID_SONG " & _
                     "WHERE PS.ID_PLAYLIST = ? ORDER BY S.SONG_NAME", Array(P(adInteger, 0, idPl)))
    If rs.EOF Then
        EmptyState "Esta playlist está vacía. Agrega canciones desde el catálogo de abajo."
    Else
    %>
    <ul class="track-list">
        <% Do While Not rs.EOF
            Dim acc
            acc = ""
            If canEdit Then
                acc = "<form method=""post"" action=""" & Url("/playlist_detail.asp?id=" & idPl) & """ style=""display:inline"">" & _
                      CsrfField & _
                      "<input type=""hidden"" name=""action"" value=""remove"">" & _
                      "<input type=""hidden"" name=""idSong"" value=""" & rs("ID_SONG") & """>" & _
                      "<button class=""icon-btn"" type=""submit"" title=""Quitar de la lista"">" & _
                      "<span class=""ico ico--minus"" aria-hidden=""true""></span></button></form>"
            End If
            SongRow rs("ID_SONG"), rs("SONG_NAME"), rs("ARTISTS"), rs("COVER"), rs("PLAYS"), rs("SONG_PATH"), acc
            rs.MoveNext
        Loop %>
    </ul>
    <%
    End If
    RSClose rs
    %>
</section>

<% If canEdit Then %>
<!-- ---------- Agregar canciones del catálogo ---------- -->
<section>
    <% SectionHeader "Agregar canciones", "Catálogo disponible que aún no está en la lista", "", "" %>
    <div class="table-wrap">
    <table class="table">
        <thead>
            <tr><th>Canción</th><th>Artista(s)</th><th class="table__actions">Acción</th></tr>
        </thead>
        <tbody>
        <%
        Set rs = DBQuery("SELECT S.ID_SONG, S.SONG_NAME, " & SQL_SONG_ARTISTS & " AS ARTISTS " & _
                         "FROM TBL_SONG S WHERE NOT EXISTS (SELECT 1 FROM TBL_PLAYLIST_SONG PS " & _
                         "WHERE PS.ID_PLAYLIST = ? AND PS.ID_SONG = S.ID_SONG) ORDER BY S.SONG_NAME", _
                         Array(P(adInteger, 0, idPl)))
        If rs.EOF Then
        %>
            <tr><td colspan="3" class="muted">Todas las canciones del catálogo ya están en esta playlist.</td></tr>
        <%
        Else
            Do While Not rs.EOF
        %>
            <tr>
                <td><strong><%= E(rs("SONG_NAME")) %></strong></td>
                <td class="muted"><%= E(rs("ARTISTS")) %></td>
                <td>
                    <div class="table__actions">
                        <form method="post" action="<%= Url("/playlist_detail.asp?id=" & idPl) %>">
                            <%= CsrfField %>
                            <input type="hidden" name="action" value="add">
                            <input type="hidden" name="idSong" value="<%= rs("ID_SONG") %>">
                            <button class="btn btn--soft btn--sm" type="submit">
                                <span class="ico ico--plus" aria-hidden="true"></span> Agregar
                            </button>
                        </form>
                    </div>
                </td>
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
<% End If %>
<%
PageBottom
%>
