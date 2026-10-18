<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="includes/config.asp" -->
<!-- #include file="includes/db.asp" -->
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/ui.asp" -->
<%
'=====================================================================
'  PoliMusic - playlists.asp
'  CRUD de las playlists PROPIAS del usuario autenticado
'  (crear, consultar, actualizar, eliminar).
'=====================================================================
RequireLogin
DBOpen

Dim action, errMsg, editId, editTitle, editType, editPhoto
Dim idPl, title, ptype, photo

action    = LCase(GetStr("action", "", 20))
errMsg    = ""
editId    = 0
editTitle = ""
editType  = PLAYLIST_PUBLIC
editPhoto = COVER_PLAYLIST

'--------------------------- POST: crear / actualizar / eliminar -------
If UCase(NS(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then
    CheckCsrf
    idPl  = GetInt("id", 0)
    title = GetStr("title", "", 50)
    ptype = GetInt("type", PLAYLIST_PUBLIC)
    photo = GetStr("photo", COVER_PLAYLIST, 255)
    If ptype <> PLAYLIST_PRIVATE Then ptype = PLAYLIST_PUBLIC

    Select Case action
        Case "create"
            If Len(title) < 2 Then
                errMsg = "El título de la playlist debe tener al menos 2 caracteres."
            Else
                DBExec "INSERT INTO TBL_PLAYLIST (ID_USER, TITLE, CREATION_DATE, TYPE, PHOTO) VALUES (?, ?, ?, ?, ?)", _
                       Array(P(adInteger, 0, CurrentUserId()), P(adVarChar, 50, title), _
                             P(adDate, 0, Now()), P(adInteger, 0, ptype), P(adVarChar, 255, photo))
                SetFlash "ok", "Playlist «" & title & "» creada."
                Response.Redirect Url("/playlists.asp")
                Response.End
            End If

        Case "update"
            If Not OwnsPlaylist(idPl) Then AccessDenied "No puedes modificar una playlist que no es tuya."
            If Len(title) < 2 Then
                errMsg = "El título de la playlist debe tener al menos 2 caracteres."
            Else
                DBExec "UPDATE TBL_PLAYLIST SET TITLE = ?, TYPE = ?, PHOTO = ? WHERE ID_PLAYLIST = ? AND ID_USER = ?", _
                       Array(P(adVarChar, 50, title), P(adInteger, 0, ptype), P(adVarChar, 255, photo), _
                             P(adInteger, 0, idPl), P(adInteger, 0, CurrentUserId()))
                SetFlash "ok", "Playlist actualizada."
                Response.Redirect Url("/playlists.asp")
                Response.End
            End If

        Case "delete"
            If Not OwnsPlaylist(idPl) Then AccessDenied "No puedes eliminar una playlist que no es tuya."
            On Error Resume Next
            DBBeginTrans
            DBExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = ?", Array(P(adInteger, 0, idPl))
            DBExec "DELETE FROM TBL_PLAYLIST WHERE ID_PLAYLIST = ? AND ID_USER = ?", _
                   Array(P(adInteger, 0, idPl), P(adInteger, 0, CurrentUserId()))
            If Err.Number <> 0 Then
                DBRollbackTrans
                On Error Goto 0
                SetFlash "error", "No se pudo eliminar la playlist: " & Err.Description
            Else
                DBCommitTrans
                On Error Goto 0
                SetFlash "ok", "Playlist eliminada."
            End If
            Response.Redirect Url("/playlists.asp")
            Response.End
    End Select
End If

'--------------------------- GET: modo edición ------------------------
If GetInt("edit", 0) > 0 Then
    editId = GetInt("edit", 0)
    If Not OwnsPlaylist(editId) Then AccessDenied "No puedes editar una playlist que no es tuya."
    Dim rsE
    Set rsE = DBQuery("SELECT TITLE, TYPE, PHOTO FROM TBL_PLAYLIST WHERE ID_PLAYLIST = ?", Array(P(adInteger, 0, editId)))
    If Not rsE.EOF Then
        editTitle = rsE("TITLE")
        editType  = CInt(rsE("TYPE"))
        editPhoto = NS(rsE("PHOTO"))
    End If
    RSClose rsE
End If

PageTop "Mis playlists", "playlists"
%>
<% SectionHeader "Mis playlists", "Crea, edita y elimina tus propias listas de reproducción", "", "" %>

<!-- ------------------- Formulario (crear / editar) ------------------- -->
<section class="panel">
    <h2 class="panel__title"><% If editId > 0 Then %>Editar playlist<% Else %>Nueva playlist<% End If %></h2>
    <p class="panel__sub">Sólo tú (o un administrador) puedes modificar tus listas.</p>

    <% If errMsg <> "" Then %>
    <div class="flash flash--error" role="alert">
        <span class="flash__icon" aria-hidden="true"></span><span><%= E(errMsg) %></span>
    </div>
    <% End If %>

    <form method="post" action="<%= Url("/playlists.asp") %>" data-once>
        <%= CsrfField %>
        <input type="hidden" name="action" value="<% If editId > 0 Then %>update<% Else %>create<% End If %>">
        <% If editId > 0 Then %><input type="hidden" name="id" value="<%= editId %>"><% End If %>

        <div class="form-grid">
            <div class="field">
                <label for="title">Título *</label>
                <input type="text" id="title" name="title" maxlength="50" required
                       value="<%= E(editTitle) %>" placeholder="ej. Rock para estudiar">
            </div>
            <div class="field">
                <label for="type">Visibilidad</label>
                <select id="type" name="type">
                    <option value="<%= PLAYLIST_PUBLIC %>"<%= Sel(CStr(PLAYLIST_PUBLIC), CStr(editType)) %>>Pública</option>
                    <option value="<%= PLAYLIST_PRIVATE %>"<%= Sel(CStr(PLAYLIST_PRIVATE), CStr(editType)) %>>Privada</option>
                </select>
            </div>
            <div class="field">
                <label for="photo">Portada</label>
                <select id="photo" name="photo">
                    <% PhotoOptions editPhoto %>
                </select>
            </div>
        </div>

        <div class="form-actions">
            <button class="btn btn--primary" type="submit">
                <% If editId > 0 Then %>Guardar cambios<% Else %>Crear playlist<% End If %>
            </button>
            <% If editId > 0 Then %>
            <a class="btn btn--ghost" href="<%= Url("/playlists.asp") %>">Cancelar</a>
            <% End If %>
        </div>
    </form>
</section>

<!-- ------------------- Mis listas ------------------- -->
<section>
    <% SectionHeader "Mis listas", "Resultado de TBL_PLAYLIST filtrado por tu usuario", "", "" %>
    <div class="grid grid--wide">
        <%
        Dim rs
        Set rs = DBQuery("SELECT PL.ID_PLAYLIST, PL.TITLE, PL.PHOTO, PL.TYPE, PL.CREATION_DATE, " & _
                         "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG PS WHERE PS.ID_PLAYLIST = PL.ID_PLAYLIST) AS NSONGS, " & _
                         "(SELECT U.USERNAME FROM TBL_USER U WHERE U.ID_USER = PL.ID_USER) AS OWNER " & _
                         "FROM TBL_PLAYLIST PL WHERE PL.ID_USER = ? ORDER BY PL.CREATION_DATE DESC", _
                         Array(P(adInteger, 0, CurrentUserId())))
        If rs.EOF Then
            EmptyState "Todavía no has creado ninguna playlist. Usa el formulario de arriba."
        Else
            Do While Not rs.EOF
        %>
        <div class="card card--playlist">
            <a href="<%= Url("/playlist_detail.asp?id=" & rs("ID_PLAYLIST")) %>">
                <div class="card__art">
                    <img src="<%= AssetUrl(rs("PHOTO"), COVER_PLAYLIST) %>" alt="Portada de <%= E(rs("TITLE")) %>" loading="lazy">
                </div>
                <h3 class="card__title"><%= E(rs("TITLE")) %></h3>
                <p class="card__meta"><%= rs("NSONGS") %> canciones · <%= E(Year(rs("CREATION_DATE"))) %></p>
                <p class="card__badge"><%= E(PlaylistTypeLabel(rs("TYPE"))) %></p>
            </a>
            <div class="card__tools">
                <a class="icon-btn" title="Editar" href="<%= Url("/playlists.asp?edit=" & rs("ID_PLAYLIST")) %>">
                    <span class="ico ico--edit" aria-hidden="true"></span>
                </a>
                <form method="post" action="<%= Url("/playlists.asp") %>" style="display:inline"
                      data-confirm="¿Eliminar la playlist «<%= E(rs("TITLE")) %>»? Esta acción no se puede deshacer.">
                    <%= CsrfField %>
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="id" value="<%= rs("ID_PLAYLIST") %>">
                    <button class="icon-btn" type="submit" title="Eliminar">
                        <span class="ico ico--trash" aria-hidden="true"></span>
                    </button>
                </form>
            </div>
        </div>
        <%
                rs.MoveNext
            Loop
        End If
        RSClose rs
        %>
    </div>
</section>

<!-- ------------------- Listas públicas de otros ------------------- -->
<section>
    <% SectionHeader "Listas públicas de la comunidad", "Puedes reproducirlas, pero no modificarlas", "", "" %>
    <div class="grid grid--wide">
        <%
        Set rs = DBQuery("SELECT PL.ID_PLAYLIST, PL.TITLE, PL.PHOTO, PL.TYPE, " & _
                         "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG PS WHERE PS.ID_PLAYLIST = PL.ID_PLAYLIST) AS NSONGS, " & _
                         "(SELECT U.USERNAME FROM TBL_USER U WHERE U.ID_USER = PL.ID_USER) AS OWNER " & _
                         "FROM TBL_PLAYLIST PL WHERE PL.TYPE = ? AND PL.ID_USER <> ? ORDER BY PL.CREATION_DATE DESC", _
                         Array(P(adInteger, 0, PLAYLIST_PUBLIC), P(adInteger, 0, CurrentUserId())))
        If rs.EOF Then
            EmptyState "Nadie ha compartido listas públicas todavía."
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
