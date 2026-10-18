<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="../includes/config.asp" -->
<!-- #include file="../includes/db.asp" -->
<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/ui.asp" -->
<!-- #include file="_tabs.asp" -->
<%
'=====================================================================
'  PoliMusic - admin/songs.asp
'  CRUD de TBL_SONG (nombre, ruta del archivo, reproducciones).
'=====================================================================
RequireAdmin
DBOpen

Dim action, errMsg, q, likeQ, rs
Dim editId, fName, fPath, fPlays, idSong

action = LCase(GetStr("action", "", 20))
errMsg = ""
editId = 0

If UCase(NS(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then
    CheckCsrf
    idSong = GetInt("id", 0)
    fName  = GetStr("SONG_NAME", "", 50)
    fPath  = GetStr("SONG_PATH", "", 255)
    fPlays = GetInt("PLAYS", 0)
    If fPlays < 0 Then fPlays = 0

    Select Case action
        Case "create"
            If fName = "" Or fPath = "" Then
                errMsg = "El nombre y la ruta del archivo son obligatorios."
            Else
                DBExec "INSERT INTO TBL_SONG (SONG_NAME, SONG_PATH, PLAYS) VALUES (?, ?, ?)", _
                       Array(P(adVarChar, 50, fName), P(adVarChar, 255, fPath), P(adInteger, 0, fPlays))
                SetFlash "ok", "Canción «" & fName & "» agregada al catálogo."
                Response.Redirect Url("/admin/songs.asp")
                Response.End
            End If

        Case "update"
            If fName = "" Or fPath = "" Then
                errMsg = "El nombre y la ruta del archivo son obligatorios."
            Else
                DBExec "UPDATE TBL_SONG SET SONG_NAME = ?, SONG_PATH = ?, PLAYS = ? WHERE ID_SONG = ?", _
                       Array(P(adVarChar, 50, fName), P(adVarChar, 255, fPath), _
                             P(adInteger, 0, fPlays), P(adInteger, 0, idSong))
                SetFlash "ok", "Canción actualizada."
                Response.Redirect Url("/admin/songs.asp")
                Response.End
            End If

        Case "delete"
            On Error Resume Next
            DBBeginTrans
            DBExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_SONG = ?", Array(P(adInteger, 0, idSong))
            DBExec "DELETE FROM TBL_TRACKLIST WHERE ID_SONG = ?", Array(P(adInteger, 0, idSong))
            DBExec "DELETE FROM TBL_PLAYER WHERE ID_SONG = ?", Array(P(adInteger, 0, idSong))
            DBExec "DELETE FROM TBL_SONG WHERE ID_SONG = ?", Array(P(adInteger, 0, idSong))
            If Err.Number <> 0 Then
                DBRollbackTrans
                On Error Goto 0
                SetFlash "error", "No se pudo eliminar la canción: " & Err.Description
            Else
                DBCommitTrans
                On Error Goto 0
                SetFlash "ok", "Canción eliminada del catálogo."
            End If
            Response.Redirect Url("/admin/songs.asp")
            Response.End
    End Select
End If

If GetInt("edit", 0) > 0 Then
    editId = GetInt("edit", 0)
    Set rs = DBQuery("SELECT ID_SONG, SONG_NAME, SONG_PATH, ISNULL(PLAYS,0) AS PLAYS FROM TBL_SONG WHERE ID_SONG = ?", _
                     Array(P(adInteger, 0, editId)))
    If Not rs.EOF Then
        fName  = rs("SONG_NAME")
        fPath  = rs("SONG_PATH")
        fPlays = CLng(rs("PLAYS"))
    End If
    RSClose rs
End If

q     = GetStr("q", "", 80)
likeQ = "%" & q & "%"

PageTop "Canciones", "admin"
%>
<% SectionHeader "Canciones", "Administra los archivos del catálogo", Url("/admin/default.asp"), "Volver al panel" %>
<% AdminTabs "Canciones" %>

<section class="panel">
    <h2 class="panel__title"><% If editId > 0 Then %>Editar canción #<%= editId %><% Else %>Nueva canción<% End If %></h2>
    <p class="panel__sub">La ruta se guarda igual que en el script original: <code>~/songFiles/archivo.mp3</code></p>

    <% If errMsg <> "" Then %>
    <div class="flash flash--error" role="alert">
        <span class="flash__icon" aria-hidden="true"></span><span><%= E(errMsg) %></span>
    </div>
    <% End If %>

    <form method="post" action="<%= Url("/admin/songs.asp") %>" data-once>
        <%= CsrfField %>
        <input type="hidden" name="action" value="<% If editId > 0 Then %>update<% Else %>create<% End If %>">
        <% If editId > 0 Then %><input type="hidden" name="id" value="<%= editId %>"><% End If %>

        <div class="form-grid">
            <div class="field">
                <label for="SONG_NAME">Nombre *</label>
                <input type="text" id="SONG_NAME" name="SONG_NAME" maxlength="50" required value="<%= E(fName) %>">
            </div>
            <div class="field">
                <label for="SONG_PATH">Ruta del archivo *</label>
                <input type="text" id="SONG_PATH" name="SONG_PATH" maxlength="255" required
                       value="<%= E(fPath) %>" placeholder="~/songFiles/bensound-adventure.mp3">
                <small>Archivos incluidos: bensound-adventure, -dreams, -energy, -scifi, -tomorrow.</small>
            </div>
            <div class="field">
                <label for="PLAYS">Reproducciones</label>
                <input type="number" id="PLAYS" name="PLAYS" min="0" value="<%= fPlays %>">
            </div>
        </div>

        <div class="form-actions">
            <button class="btn btn--primary" type="submit"><% If editId > 0 Then %>Guardar cambios<% Else %>Agregar canción<% End If %></button>
            <% If editId > 0 Then %><a class="btn btn--ghost" href="<%= Url("/admin/songs.asp") %>">Cancelar</a><% End If %>
        </div>
    </form>
</section>

<section>
    <% SectionHeader "Catálogo", "Canciones registradas", "", "" %>

    <form class="toolbar" method="get" action="<%= Url("/admin/songs.asp") %>">
        <div class="searchbox">
            <span class="ico ico--search" aria-hidden="true"></span>
            <input type="search" name="q" value="<%= E(q) %>" placeholder="Buscar canción...">
        </div>
        <button class="btn btn--soft" type="submit">Buscar</button>
        <% If q <> "" Then %><a class="btn btn--ghost" href="<%= Url("/admin/songs.asp") %>">Limpiar</a><% End If %>
    </form>

    <div class="table-wrap">
    <table class="table">
        <thead>
            <tr><th>#</th><th>Canción</th><th>Archivo</th><th>Repros</th><th>Álbumes</th><th>Artistas</th><th class="table__actions">Acciones</th></tr>
        </thead>
        <tbody>
        <%
        Dim sqlList, params
        If q <> "" Then
            sqlList = "SELECT S.ID_SONG, S.SONG_NAME, S.SONG_PATH, ISNULL(S.PLAYS,0) AS PLAYS, " & _
                      "(SELECT COUNT(*) FROM TBL_TRACKLIST T WHERE T.ID_SONG = S.ID_SONG) AS NALB, " & _
                      "(SELECT COUNT(*) FROM TBL_PLAYER P WHERE P.ID_SONG = S.ID_SONG) AS NART " & _
                      "FROM TBL_SONG S WHERE S.SONG_NAME LIKE ? ORDER BY S.SONG_NAME"
            params = Array(P(adVarChar, 80, likeQ))
        Else
            sqlList = "SELECT S.ID_SONG, S.SONG_NAME, S.SONG_PATH, ISNULL(S.PLAYS,0) AS PLAYS, " & _
                      "(SELECT COUNT(*) FROM TBL_TRACKLIST T WHERE T.ID_SONG = S.ID_SONG) AS NALB, " & _
                      "(SELECT COUNT(*) FROM TBL_PLAYER P WHERE P.ID_SONG = S.ID_SONG) AS NART " & _
                      "FROM TBL_SONG S ORDER BY S.ID_SONG"
            params = Null
        End If
        Set rs = DBQuery(sqlList, params)
        If rs.EOF Then
        %>
            <tr><td colspan="7" class="muted">No hay canciones para mostrar.</td></tr>
        <%
        Else
            Do While Not rs.EOF
        %>
            <tr>
                <td><%= rs("ID_SONG") %></td>
                <td><strong><%= E(rs("SONG_NAME")) %></strong></td>
                <td class="muted"><%= E(rs("SONG_PATH")) %></td>
                <td><%= rs("PLAYS") %></td>
                <td><%= rs("NALB") %></td>
                <td><%= rs("NART") %></td>
                <td>
                    <div class="table__actions">
                        <a class="icon-btn" title="Editar" href="<%= Url("/admin/songs.asp?edit=" & rs("ID_SONG")) %>">
                            <span class="ico ico--edit" aria-hidden="true"></span>
                        </a>
                        <form method="post" action="<%= Url("/admin/songs.asp") %>" style="display:inline"
                              data-confirm="¿Eliminar <%= E(rs("SONG_NAME")) %>? Se quitará de álbumes, artistas y playlists.">
                            <%= CsrfField %>
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="id" value="<%= rs("ID_SONG") %>">
                            <button class="icon-btn" type="submit" title="Eliminar">
                                <span class="ico ico--trash" aria-hidden="true"></span>
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
<%
PageBottom
%>
