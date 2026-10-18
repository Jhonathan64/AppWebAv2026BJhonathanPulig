<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="../includes/config.asp" -->
<!-- #include file="../includes/db.asp" -->
<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/ui.asp" -->
<!-- #include file="_tabs.asp" -->
<%
'=====================================================================
'  PoliMusic - admin/users.asp
'  CRUD de TBL_USER. Permisos validados en el servidor (RequireAdmin).
'=====================================================================
RequireAdmin
DBOpen

Dim action, errMsg, q, likeQ, rs, rsCat
Dim editId, fUser, fMail, fPass, fBirth, fType, fPhoto
Dim idUser

action = LCase(GetStr("action", "", 20))
errMsg = ""
editId = 0
fType  = USER_TYPE_USER
fPhoto = AVATAR_DEFAULT

'------------------------------ Acciones POST -------------------------
If UCase(NS(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then
    CheckCsrf
    idUser = GetInt("id", 0)
    fUser  = GetStr("username", "", 50)
    fMail  = GetStr("email", "", 50)
    fPass  = GetStr("password", "", 50)
    fBirth = GetStr("birthday", "", 10)
    fType  = GetInt("type", USER_TYPE_USER)
    fPhoto = GetStr("photo", AVATAR_DEFAULT, 255)
    If fType <> USER_TYPE_ADMIN Then fType = USER_TYPE_USER

    Dim birthVal : birthVal = Null
    If fBirth <> "" Then
        If IsDate(fBirth) Then birthVal = CDate(fBirth)
    End If

    Select Case action
        Case "create"
            If Len(fUser) < 3 Then
                errMsg = "El usuario debe tener al menos 3 caracteres."
            ElseIf Len(fPass) < 8 Then
                errMsg = "La contraseña debe tener al menos 8 caracteres."
            ElseIf DBExists("SELECT 1 FROM TBL_USER WHERE USERNAME = ?", Array(P(adVarChar, 50, fUser))) Then
                errMsg = "Ya existe un usuario con ese nombre."
            Else
                DBExec "INSERT INTO TBL_USER (USERNAME, PASSWORD, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE) VALUES (?, ?, ?, ?, ?, ?)", _
                       Array(P(adVarChar, 50, fUser), P(adVarChar, 50, HashPassword(fPass)), _
                             P(adVarChar, 50, fMail), P(adDate, 0, birthVal), _
                             P(adVarChar, 255, fPhoto), P(adInteger, 0, fType))
                SetFlash "ok", "Usuario «" & fUser & "» creado."
                Response.Redirect Url("/admin/users.asp")
                Response.End
            End If

        Case "update"
            If Len(fUser) < 3 Then
                errMsg = "El usuario debe tener al menos 3 caracteres."
            ElseIf DBExists("SELECT 1 FROM TBL_USER WHERE USERNAME = ? AND ID_USER <> ?", _
                            Array(P(adVarChar, 50, fUser), P(adInteger, 0, idUser))) Then
                errMsg = "Ya existe otro usuario con ese nombre."
            ElseIf idUser = CurrentUserId() And fType <> USER_TYPE_ADMIN Then
                errMsg = "No puedes quitarte el rol de administrador a ti mismo."
            Else
                If fPass <> "" Then
                    If Len(fPass) < 8 Then
                        errMsg = "La nueva contraseña debe tener al menos 8 caracteres."
                    Else
                        DBExec "UPDATE TBL_USER SET PASSWORD = ? WHERE ID_USER = ?", _
                               Array(P(adVarChar, 50, HashPassword(fPass)), P(adInteger, 0, idUser))
                    End If
                End If
                If errMsg = "" Then
                    DBExec "UPDATE TBL_USER SET USERNAME = ?, EMAIL = ?, BIRTHDAY = ?, USER_PHOTO = ?, USER_TYPE = ? WHERE ID_USER = ?", _
                           Array(P(adVarChar, 50, fUser), P(adVarChar, 50, fMail), P(adDate, 0, birthVal), _
                                 P(adVarChar, 255, fPhoto), P(adInteger, 0, fType), P(adInteger, 0, idUser))
                    If idUser = CurrentUserId() Then Session("PM_USER") = fUser
                    SetFlash "ok", "Usuario «" & fUser & "» actualizado."
                    Response.Redirect Url("/admin/users.asp")
                    Response.End
                End If
            End If

        Case "delete"
            If idUser = CurrentUserId() Then
                SetFlash "error", "No puedes eliminar tu propia cuenta desde el panel."
                Response.Redirect Url("/admin/users.asp")
                Response.End
            End If
            On Error Resume Next
            DBBeginTrans
            ' Primero las listas y sus canciones (integridad referencial)
            DBExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST IN (SELECT ID_PLAYLIST FROM TBL_PLAYLIST WHERE ID_USER = ?)", _
                   Array(P(adInteger, 0, idUser))
            DBExec "DELETE FROM TBL_PLAYLIST WHERE ID_USER = ?", Array(P(adInteger, 0, idUser))
            DBExec "DELETE FROM TBL_USER WHERE ID_USER = ?", Array(P(adInteger, 0, idUser))
            If Err.Number <> 0 Then
                DBRollbackTrans
                On Error Goto 0
                SetFlash "error", "No se pudo eliminar el usuario: " & Err.Description
            Else
                DBCommitTrans
                On Error Goto 0
                SetFlash "ok", "Usuario eliminado junto con sus playlists."
            End If
            Response.Redirect Url("/admin/users.asp")
            Response.End
    End Select
End If

'------------------------------ Modo edición --------------------------
If GetInt("edit", 0) > 0 Then
    editId = GetInt("edit", 0)
    Set rs = DBQuery("SELECT ID_USER, USERNAME, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE FROM TBL_USER WHERE ID_USER = ?", _
                     Array(P(adInteger, 0, editId)))
    If Not rs.EOF Then
        fUser  = rs("USERNAME")
        fMail  = rs("EMAIL")
        fPhoto = NS(rs("USER_PHOTO"))
        fType  = CInt(rs("USER_TYPE"))
        If IsNull(rs("BIRTHDAY")) Then fBirth = "" Else fBirth = FormatDate(rs("BIRTHDAY"))
    End If
    RSClose rs
End If

q     = GetStr("q", "", 80)
likeQ = "%" & q & "%"

PageTop "Usuarios", "admin"
%>
<% SectionHeader "Usuarios", "Alta, consulta, edición y baja de cuentas", Url("/admin/default.asp"), "Volver al panel" %>
<% AdminTabs "Usuarios" %>

<!-- ------------------------- Formulario ------------------------- -->
<section class="panel">
    <h2 class="panel__title"><% If editId > 0 Then %>Editar usuario #<%= editId %><% Else %>Nuevo usuario<% End If %></h2>
    <p class="panel__sub">La contraseña se guarda con SHA1 (HASHBYTES de SQL Server). Déjala vacía para mantener la actual.</p>

    <% If errMsg <> "" Then %>
    <div class="flash flash--error" role="alert">
        <span class="flash__icon" aria-hidden="true"></span><span><%= E(errMsg) %></span>
    </div>
    <% End If %>

    <form method="post" action="<%= Url("/admin/users.asp") %>" data-once>
        <%= CsrfField %>
        <input type="hidden" name="action" value="<% If editId > 0 Then %>update<% Else %>create<% End If %>">
        <% If editId > 0 Then %><input type="hidden" name="id" value="<%= editId %>"><% End If %>

        <div class="form-grid">
            <div class="field">
                <label for="username">Usuario *</label>
                <input type="text" id="username" name="username" maxlength="50" required value="<%= E(fUser) %>">
            </div>
            <div class="field">
                <label for="email">Correo *</label>
                <input type="email" id="email" name="email" maxlength="50" required value="<%= E(fMail) %>">
            </div>
            <div class="field">
                <label for="password">Contraseña <% If editId > 0 Then %>(vacía = sin cambios)<% Else %>*<% End If %></label>
                <input type="password" id="password" name="password" maxlength="50" placeholder="mínimo 8 caracteres" autocomplete="new-password">
            </div>
            <div class="field">
                <label for="birthday">Fecha de nacimiento</label>
                <input type="date" id="birthday" name="birthday" value="<%= E(fBirth) %>">
            </div>
            <div class="field">
                <label for="type">Tipo de usuario *</label>
                <select id="type" name="type">
                    <%
                    Set rsCat = DBQuery("SELECT COD_CATALOG, VALUE FROM TBL_CATALOG WHERE COD_CATALOG_PARENT = ? ORDER BY COD_CATALOG", _
                                        Array(P(adVarChar, 8, "1")))
                    Do While Not rsCat.EOF
                    %>
                    <option value="<%= E(rsCat("COD_CATALOG")) %>"<%= Sel(CStr(rsCat("COD_CATALOG")), CStr(fType)) %>><%= E(rsCat("VALUE")) %></option>
                    <%
                        rsCat.MoveNext
                    Loop
                    RSClose rsCat
                    %>
                </select>
            </div>
            <div class="field">
                <label for="photo">Foto de perfil</label>
                <select id="photo" name="photo">
                    <% AvatarOptions fPhoto %>
                </select>
            </div>
        </div>

        <div class="form-actions">
            <button class="btn btn--primary" type="submit"><% If editId > 0 Then %>Guardar cambios<% Else %>Crear usuario<% End If %></button>
            <% If editId > 0 Then %><a class="btn btn--ghost" href="<%= Url("/admin/users.asp") %>">Cancelar</a><% End If %>
        </div>
    </form>
</section>

<!-- ------------------------- Listado ------------------------- -->
<section>
    <% SectionHeader "Listado de usuarios", "Busca por nombre o correo", "", "" %>

    <form class="toolbar" method="get" action="<%= Url("/admin/users.asp") %>">
        <div class="searchbox">
            <span class="ico ico--search" aria-hidden="true"></span>
            <input type="search" name="q" value="<%= E(q) %>" placeholder="Buscar usuario...">
        </div>
        <button class="btn btn--soft" type="submit">Buscar</button>
        <% If q <> "" Then %><a class="btn btn--ghost" href="<%= Url("/admin/users.asp") %>">Limpiar</a><% End If %>
    </form>

    <div class="table-wrap">
    <table class="table">
        <thead>
            <tr><th>#</th><th></th><th>Usuario</th><th>Correo</th><th>Nacimiento</th><th>Tipo</th><th class="table__actions">Acciones</th></tr>
        </thead>
        <tbody>
        <%
        Dim sqlList, params
        If q <> "" Then
            sqlList = "SELECT ID_USER, USERNAME, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE FROM TBL_USER " & _
                      "WHERE USERNAME LIKE ? OR EMAIL LIKE ? ORDER BY ID_USER"
            params = Array(P(adVarChar, 80, likeQ), P(adVarChar, 80, likeQ))
        Else
            sqlList = "SELECT TOP 100 ID_USER, USERNAME, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE FROM TBL_USER ORDER BY ID_USER"
            params = Null
        End If
        Set rs = DBQuery(sqlList, params)
        If rs.EOF Then
        %>
            <tr><td colspan="7" class="muted">No hay usuarios para mostrar.</td></tr>
        <%
        Else
            Do While Not rs.EOF
        %>
            <tr>
                <td><%= rs("ID_USER") %></td>
                <td><img class="thumb" src="<%= AssetUrl(rs("USER_PHOTO"), AVATAR_DEFAULT) %>" alt=""></td>
                <td><strong><%= E(rs("USERNAME")) %></strong></td>
                <td class="muted"><%= E(rs("EMAIL")) %></td>
                <td><%= E(FormatDate(rs("BIRTHDAY"))) %></td>
                <td><span class="pill<%= IIf(CInt(rs("USER_TYPE")) = USER_TYPE_ADMIN, " pill--admin", "") %>"><%= E(UserTypeLabel(rs("USER_TYPE"))) %></span></td>
                <td>
                    <div class="table__actions">
                        <a class="icon-btn" title="Editar" href="<%= Url("/admin/users.asp?edit=" & rs("ID_USER")) %>">
                            <span class="ico ico--edit" aria-hidden="true"></span>
                        </a>
                        <% If CLng(rs("ID_USER")) <> CurrentUserId() Then %>
                        <form method="post" action="<%= Url("/admin/users.asp") %>" style="display:inline"
                              data-confirm="¿Eliminar al usuario <%= E(rs("USERNAME")) %>? También se borrarán sus playlists.">
                            <%= CsrfField %>
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="id" value="<%= rs("ID_USER") %>">
                            <button class="icon-btn" type="submit" title="Eliminar">
                                <span class="ico ico--trash" aria-hidden="true"></span>
                            </button>
                        </form>
                        <% End If %>
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
