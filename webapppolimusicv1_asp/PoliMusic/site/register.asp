<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="includes/config.asp" -->
<!-- #include file="includes/db.asp" -->
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/ui.asp" -->
<%
'=====================================================================
'  PoliMusic - register.asp
'  Registro de usuarios normales (USER_TYPE = 0).
'=====================================================================
Dim errMsg, okMsg
Dim fUser, fMail, fPass, fPass2, fBirth
Dim re, birthVal

If IsLoggedIn() Then Response.Redirect Url("/home.asp")

DBOpen

errMsg  = ""
fUser   = GetStr("username", "", 50)
fMail   = GetStr("email", "", 50)
fPass   = GetStr("password", "", 50)
fPass2  = GetStr("password2", "", 50)
fBirth  = GetStr("birthday", "", 10)
birthVal = Null

If UCase(NS(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then
    CheckCsrf
    Set re = Server.CreateObject("VBScript.RegExp")
    re.IgnoreCase = True

    If Len(fUser) < 3 Then
        errMsg = "El usuario debe tener al menos 3 caracteres."
    Else
        re.Pattern = "^[A-Za-z0-9 ._-]+$"
        If Not re.Test(fUser) Then
            errMsg = "El usuario sólo puede contener letras, números, espacios, puntos, guiones y guiones bajos."
        End If
    End If

    If errMsg = "" Then
        re.Pattern = "^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$"
        If Not re.Test(fMail) Then errMsg = "Escribe un correo electrónico válido."
    End If

    If errMsg = "" And Len(fPass) < 8 Then
        errMsg = "La contraseña debe tener al menos 8 caracteres."
    End If

    If errMsg = "" And fPass <> fPass2 Then
        errMsg = "Las contraseñas no coinciden."
    End If

    ' Fecha de nacimiento (opcional)
    If errMsg = "" And fBirth <> "" Then
        If IsDate(fBirth) Then
            birthVal = CDate(fBirth)
        Else
            errMsg = "La fecha de nacimiento no es válida (formato AAAA-MM-DD)."
        End If
    End If

    ' ¿Usuario o correo ya registrados? (consultas parametrizadas)
    If errMsg = "" Then
        If DBExists("SELECT 1 FROM TBL_USER WHERE USERNAME = ?", Array(P(adVarChar, 50, fUser))) Then
            errMsg = "Ese nombre de usuario ya está en uso."
        ElseIf DBExists("SELECT 1 FROM TBL_USER WHERE EMAIL = ?", Array(P(adVarChar, 50, fMail))) Then
            errMsg = "Ya existe una cuenta con ese correo."
        End If
    End If

    If errMsg = "" Then
        Dim newId
        DBExec "INSERT INTO TBL_USER (USERNAME, PASSWORD, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE) " & _
               "VALUES (?, ?, ?, ?, ?, ?)", _
               Array(P(adVarChar, 50, fUser), _
                     P(adVarChar, 50, HashPassword(fPass)), _
                     P(adVarChar, 50, fMail), _
                     P(adDate, 0, birthVal), _
                     P(adVarChar, 255, AVATAR_DEFAULT), _
                     P(adInteger, 0, USER_TYPE_USER))
        newId = CLng(DBScalar("SELECT SCOPE_IDENTITY()", Null, 0))
        StartSession newId, fUser, USER_TYPE_USER, AVATAR_DEFAULT
        SetFlash "ok", "Cuenta creada. ¡Bienvenido a PoliMusic, " & fUser & "!"
        Response.Redirect Url("/home.asp")
        Response.End
    End If
End If

AuthTop "Crear cuenta"
%>
<div class="auth-card">
    <h1>Crear tu cuenta</h1>
    <p class="lead">Registro de usuarios. Podrás reproducir música y administrar tus propias playlists.</p>

    <% RenderFlash %>
    <% If errMsg <> "" Then %>
    <div class="flash flash--error" role="alert">
        <span class="flash__icon" aria-hidden="true"></span><span><%= E(errMsg) %></span>
    </div>
    <% End If %>

    <form method="post" action="<%= Url("/register.asp") %>" data-once>
        <%= CsrfField %>
        <div class="form-grid">
            <div class="field">
                <label for="username">Usuario *</label>
                <input type="text" id="username" name="username" maxlength="50" required
                       value="<%= E(fUser) %>" placeholder="ej. Jhonathan Pulig">
            </div>
            <div class="field">
                <label for="email">Correo electrónico *</label>
                <input type="email" id="email" name="email" maxlength="50" required
                       value="<%= E(fMail) %>" placeholder="tu@correo.com">
            </div>
            <div class="field">
                <label for="password">Contraseña *</label>
                <input type="password" id="password" name="password" maxlength="50" required
                       autocomplete="new-password">
                <small>Mínimo 8 caracteres.</small>
            </div>
            <div class="field">
                <label for="password2">Repite la contraseña *</label>
                <input type="password" id="password2" name="password2" maxlength="50" required
                       autocomplete="new-password">
            </div>
            <div class="field">
                <label for="birthday">Fecha de nacimiento</label>
                <input type="date" id="birthday" name="birthday" value="<%= E(fBirth) %>">
                <small>Opcional.</small>
            </div>
        </div>

        <div class="form-actions">
            <button class="btn btn--primary btn--block" type="submit">Registrarse</button>
        </div>
    </form>

    <p class="auth-alt">¿Ya tienes cuenta? <a href="<%= Url("/login.asp") %>">Iniciar sesión</a></p>
</div>
<%
AuthBottom
%>
