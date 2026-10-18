<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="../includes/config.asp" -->
<!-- #include file="../includes/db.asp" -->
<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/ui.asp" -->
<!-- #include file="_tabs.asp" -->
<%
'=====================================================================
'  PoliMusic - admin/playlists.asp
'  CRUD de TBL_PLAYLIST (todas las listas, de cualquier usuario)
'  y contenido (TBL_PLAYLIST_SONG).
'=====================================================================
RequireAdmin
DBOpen

Dim action, errMsg, q, likeQ, rs
Dim editId, fTitle, fType, fPhoto, fOwner, fDate, idPl

action = LCase(GetStr("action", "", 20))
errMsg = ""
editId = 0
fType  = PLAYLIST_PUBLIC
fPhoto = COVER_PLAYLIST
fDate  = FormatDate(Now())

If UCase(NS(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then
    CheckCsrf
    idPl    = GetInt("id", 0)
    fTitle  = GetStr("TITLE", "", 50)
    fType   = GetInt("TYPE", PLAYLIST_PUBLIC)
    fPhoto  = GetStr("PHOTO", COVER_PLAYLIST, 255)
    fOwner  = GetInt("ID_USER", 0)
    fDate   = GetStr("CREATION_DATE", "", 10)
    If fType <> PLAYLIST_PRIVATE Then fType = PLAYLIST_PUBLIC

    Dim dateVal : dateVal = Now()
    If fDate <> "" Then
        If IsDate(fDate) Then dateVal = CDate(fDate) Else fDate = FormatDate(Now())
    Else
        fDate = FormatDate(Now())
    End If

    Select Case action
        Case "create"
            If Len(fTitle) < 2 Then
                errMsg = "El título debe tener al menos 2 caracteres."
            ElseIf fOwner <= 0 Then
                errMsg = "Selecciona el usuario dueño de la playlist."
            Else
                DBExec "INSERT INTO TBL_PLAYLIST (ID_USER, TITLE, CREATION_DATE, TYPE, PHOTO) VALUES (?, ?, ?, ?, ?)", _
                       Array(P(adInteger, 0, fOwner), P(adVarChar, 50, fTitle), _
                             P(adDate, 0, dateVal), P(adInteger, 0, fType), P(adVarChar, 255, fPhoto))
                SetFlash "ok", "Playlist «" & fTitle & "» creada."
                Response.Redirect Url("/admin/playlists.asp")
                Response.End
            End If

        Case "update"
            If Len(fTitle) < 2 Then
                errMsg = "El título debe tener al menos 2 caracteres."
            ElseIf fOwner <= 0 Then
                errMsg = "Selecciona el usuario dueño de la playlist."
            Else
                DBExec "UPDATE TBL_PLAYLIST SET TITLE = ?, TYPE = ?, PHOTO = ?, ID_USER = ?, CREATION_DATE = ? WHERE ID_PLAYLIST = ?", _
                       Array(P(adVarChar, 50, fTitle), P(adInteger, 0, fType), P(adVarChar, 255, fPhoto), _
                             P(adInteger, 0, fOwner), P(adDate, 0, dateVal), P(adInteger, 0, idPl))
                SetFlash "ok", "Playlist actualizada."
                Response.Redirect Url("/admin/playlists.asp?edit=" & idPl)
                Response.End
            End If

        Case "delete"
            On Error Resume Next
            DBBeginTrans
            DBExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = ?", Array(P(adInteger, 0, idPl))
            DBExec "DELETE FROM TBL_PLAYLIST WHERE ID_PLAYLIST = ?", Array(P(adInteger, 0, idPl))
            If Err.Number <> 0 Then
                DBRollbackTrans
                On Error Goto 0
                SetFlash "error", "No se pudo eliminar la playlist: " & Err.Description
            Else
                DBCommitTrans
                On Error Goto 0
                SetFlash "ok", "Playlist eliminada."
            End If
            Response.Redirect Url("/admin/playlists.asp")
            Response.End

        Case "song_remove"
            Dim idSongDel : idSongDel = GetInt("idSong", 0)
            DBExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = ? AND ID_SONG = ?", _
                   Array(P(adInteger, 0, idPl), P(adInteger, 0, idSongDel))
            SetFlash "ok", "Canción quitada de la playlist."
            Response.Redirect Url("/admin/playlists.asp?edit=" & idPl)
            Response.End

        Case "song_add"
            Dim idSongAdd : idSongAdd = GetInt("idSong", 0)
            If idSongAdd > 0 And idPl > 0 Then
                If Not DBExists("SELECT 1 FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = ? AND ID_SONG = ?", _
                                Array(P(adInteger, 0, idPl), P(adInteger, 0, idSongAdd))) Then
                    DBExec "INSERT INTO TBL_PLAYLIST_SONG (ID_PLAYLIST, ID_SONG) VALUES (?, ?)", _
                           Array(P(adInteger, 0, idPl), P(adInteger, 0, idSongAdd))
                    SetFlash "ok", "Canción agregada."
                Else
                    SetFlash "warn", "Esa canción ya está en la playlist."
                End If
            End If
            Response.Redirect Url("/admin/playlists.asp?edit=" & idPl)
            Response.End
    End Select
End If

If GetInt("edit", 0) > 0 Then
    editId = GetInt("edit", 0)
    Set rs = DBQuery("SELECT ID_PLAYLIST, ID_USER, TITLE, CREATION_DATE, TYPE, PHOTO FROM TBL_PLAYLIST WHERE ID_PLAYLIST = ?", _
                     Array(P(adInteger, 0, editId)))
    If Not rs.EOF Then
        fTitle = rs("TITLE")
        fType  = CInt(rs("TYPE"))
        fPhoto = NS(rs("PHOTO"))
        fOwner = CLng(rs("ID_USER"))
        fDate  = FormatDate(rs("CREATION_DATE"))
    End If
    RSClose rs
End If

q     = GetStr("q", "", 80)
likeQ = "%" & q & "%"

PageTop "Playlists", "admin"
%>
<% SectionHeader "Playlists", "Administración de todas las listas del sistema", Url("/admin/default.asp"), "Volver al panel" %>
<% AdminTabs "Playlists" %>

<section class="panel">
    <h2 class="panel__title"><% If editId > 0 Then %>Editar playlist #<%= editId %><% Else %>Nueva playlist<% End If %></h2>
    <p class="panel__sub">Puedes reasignar la lista a otro usuario o cambiar su visibilidad.</p>

    <% If errMsg <> "" Then %>
    <div class="flash flash--error" role="alert">
        <span class="flash__icon" aria-hidden="true"></span><span><%= E(errMsg) %></span>
    </div>
    <% End If %>

    <form method="post" action="<%= Url("/admin/playlists.asp") %>" data-once>
        <%= CsrfField %>
        <input type="hidden" name="action" value="<% If editId > 0 Then %>update<% Else %>create<% End If %>">
        <% If editId > 0 Then %><input type="hidden" name="id" value="<%= editId %>"><% End If %>

        <div class="form-grid">
            <div class="field">
                <label for="TITLE">Título *</label>
                <input type="text" id="TITLE" name="TITLE" maxlength="50" required value="<%= E(fTitle) %>">
            </div>
            <div class="field">
                <label for="ID_USER">Dueño *</label>
                <select id="ID_USER" name="ID_USER">
                    <%
                    Set rs = DBQuery("SELECT ID_USER, USERNAME FROM TBL_USER ORDER BY USERNAME", Null)
                    Do While Not rs.EOF
                    %>
                    <option value="<%= rs("ID_USER") %>"<%= Sel(CStr(rs("ID_USER")), CStr(fOwner)) %>><%= E(rs("USERNAME")) %></option>
                    <%
                        rs.MoveNext
                    Loop
                    RSClose rs
                    %>
                </select>
            </div>
            <div class="field">
                <label for="TYPE">Visibilidad *</label>
                <select id="TYPE" name="TYPE">
                    <%
                    Set rs = DBQuery("SELECT COD_CATALOG, VALUE FROM TBL_CATALOG WHERE COD_CATALOG_PARENT = ? ORDER BY COD_CATALOG", _
                                     Array(P(adVarChar, 8, "2")))
                    Do While Not rs.EOF
                    %>
                    <option value="<%= E(rs("COD_CATALOG")) %>"<%= Sel(CStr(rs("COD_CATALOG")), CStr(fType)) %>><%= E(rs("VALUE")) %></option>
                    <%
                        rs.MoveNext
                    Loop
                    RSClose rs
                    %>
                </select>
            </div>
            <div class="field">
                <label for="PHOTO">Portada</label>
                <select id="PHOTO" name="PHOTO">
                    <% PhotoOptions fPhoto %>
                </select>
            </div>
            <div class="field">
                <label for="CREATION_DATE">Fecha de creación</label>
                <input type="date" id="CREATION_DATE" name="CREATION_DATE" value="<%= E(fDate) %>">
            </div>
        </div>

        <div class="form-actions">
            <button class="btn btn--primary" type="submit"><% If editId > 0 Then %>Guardar cambios<% Else %>Crear playlist<% End If %></button>
            <% If editId > 0 Then %><a class="btn btn--ghost" href="<%= Url("/admin/playlists.asp") %>">Cancelar</a><% End If %>
        </div>
    </form>
</section>

<% If editId > 0 Then %>
<section class="panel">
    <h2 class="panel__title">Canciones de la playlist</h2>
    <p class="panel__sub">Contenido actual (TBL_PLAYLIST_SONG).</p>
    <div class="table-wrap">
    <table class="table">
        <thead><tr><th>#</th><th>Canción</th><th class="table__actions">Acción</th></tr></thead>
        <tbody>
        <%
        Set rs = DBQuery("SELECT S.ID_SONG, S.SONG_NAME FROM TBL_PLAYLIST_SONG PS " & _
                         "INNER JOIN TBL_SONG S ON S.ID_SONG = PS.ID_SONG WHERE PS.ID_PLAYLIST = ? ORDER BY S.SONG_NAME", _
                         Array(P(adInteger, 0, editId)))
        If rs.EOF Then
        %>
            <tr><td colspan="3" class="muted">La playlist está vacía.</td></tr>
        <%
        Else
            Do While Not rs.EOF
        %>
            <tr>
                <td><%= rs("ID_SONG") %></td>
                <td><strong><%= E(rs("SONG_NAME")) %></strong></td>
                <td>
                    <div class="table__actions">
                        <form method="post" action="<%= Url("/admin/playlists.asp") %>" style="display:inline">
                            <%= CsrfField %>
                            <input type="hidden" name="action" value="song_remove">
                            <input type="hidden" name="id" value="<%= editId %>">
                            <input type="hidden" name="idSong" value="<%= rs("ID_SONG") %>">
                            <button class="icon-btn" type="submit" title="Quitar">
                                <span class="ico ico--minus" aria-hidden="true"></span>
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

    <form method="post" action="<%= Url("/admin/playlists.asp") %>" class="toolbar" style="margin-top:14px">
        <%= CsrfField %>
        <input type="hidden" name="action" value="song_add">
        <input type="hidden" name="id" value="<%= editId %>">
        <div class="field" style="min-width:240px;flex:1 1 240px">
            <label for="idSongAdd">Agregar canción</label>
            <select id="idSongAdd" name="idSong">
                <%
                Set rs = DBQuery("SELECT S.ID_SONG, S.SONG_NAME FROM TBL_SONG S WHERE NOT EXISTS " & _
                                 "(SELECT 1 FROM TBL_PLAYLIST_SONG PS WHERE PS.ID_PLAYLIST = ? AND PS.ID_SONG = S.ID_SONG) " & _
                                 "ORDER BY S.SONG_NAME", Array(P(adInteger, 0, editId)))
                Do While Not rs.EOF
                %>
                <option value="<%= rs("ID_SONG") %>"><%= E(rs("SONG_NAME")) %></option>
                <%
                    rs.MoveNext
                Loop
                RSClose rs
                %>
            </select>
        </div>
        <button class="btn btn--soft" type="submit">
            <span class="ico ico--plus" aria-hidden="true"></span> Agregar
        </button>
    </form>
</section>
<% End If %>

<section>
    <% SectionHeader "Listado de playlists", "Busca por título", "", "" %>

    <form class="toolbar" method="get" action="<%= Url("/admin/playlists.asp") %>">
        <div class="searchbox">
            <span class="ico ico--search" aria-hidden="true"></span>
            <input type="search" name="q" value="<%= E(q) %>" placeholder="Buscar playlist...">
        </div>
        <button class="btn btn--soft" type="submit">Buscar</button>
        <% If q <> "" Then %><a class="btn btn--ghost" href="<%= Url("/admin/playlists.asp") %>">Limpiar</a><% End If %>
    </form>

    <div class="table-wrap">
    <table class="table">
        <thead>
            <tr><th>#</th><th></th><th>Título</th><th>Dueño</th><th>Tipo</th><th>Canciones</th><th>Creación</th><th class="table__actions">Acciones</th></tr>
        </thead>
        <tbody>
        <%
        Dim sqlList, params
        If q <> "" Then
            sqlList = "SELECT PL.ID_PLAYLIST, PL.TITLE, PL.PHOTO, PL.TYPE, PL.CREATION_DATE, " & _
                      "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG PS WHERE PS.ID_PLAYLIST = PL.ID_PLAYLIST) AS NSONGS, " & _
                      "(SELECT U.USERNAME FROM TBL_USER U WHERE U.ID_USER = PL.ID_USER) AS OWNER " & _
                      "FROM TBL_PLAYLIST PL WHERE PL.TITLE LIKE ? ORDER BY PL.ID_PLAYLIST DESC"
            params = Array(P(adVarChar, 80, likeQ))
        Else
            sqlList = "SELECT TOP 100 PL.ID_PLAYLIST, PL.TITLE, PL.PHOTO, PL.TYPE, PL.CREATION_DATE, " & _
                      "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG PS WHERE PS.ID_PLAYLIST = PL.ID_PLAYLIST) AS NSONGS, " & _
                      "(SELECT U.USERNAME FROM TBL_USER U WHERE U.ID_USER = PL.ID_USER) AS OWNER " & _
                      "FROM TBL_PLAYLIST PL ORDER BY PL.ID_PLAYLIST DESC"
            params = Null
        End If
        Set rs = DBQuery(sqlList, params)
        If rs.EOF Then
        %>
            <tr><td colspan="8" class="muted">No hay playlists para mostrar.</td></tr>
        <%
        Else
            Do While Not rs.EOF
        %>
            <tr>
                <td><%= rs("ID_PLAYLIST") %></td>
                <td><img class="thumb" src="<%= AssetUrl(rs("PHOTO"), COVER_PLAYLIST) %>" alt=""></td>
                <td><strong><%= E(rs("TITLE")) %></strong></td>
                <td class="muted"><%= E(rs("OWNER")) %></td>
                <td><span class="pill"><%= E(PlaylistTypeLabel(rs("TYPE"))) %></span></td>
                <td><%= rs("NSONGS") %></td>
                <td><%= E(FormatDate(rs("CREATION_DATE"))) %></td>
                <td>
                    <div class="table__actions">
                        <a class="icon-btn" title="Editar y contenido" href="<%= Url("/admin/playlists.asp?edit=" & rs("ID_PLAYLIST")) %>">
                            <span class="ico ico--edit" aria-hidden="true"></span>
                        </a>
                        <form method="post" action="<%= Url("/admin/playlists.asp") %>" style="display:inline"
                              data-confirm="¿Eliminar la playlist <%= E(rs("TITLE")) %>?">
                            <%= CsrfField %>
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="id" value="<%= rs("ID_PLAYLIST") %>">
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
