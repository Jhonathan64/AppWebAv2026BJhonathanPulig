<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="includes/config.asp" -->
<!-- #include file="includes/db.asp" -->
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/ui.asp" -->
<%
'=====================================================================
'  PoliMusic - login.asp
'  Inicio de sesión. Valida en el servidor contra TBL_USER usando
'  una consulta parametrizada.
'=====================================================================
Dim errMsg, nextUrl, username, byeMsg

If IsLoggedIn() Then Response.Redirect Url("/home.asp")

If GetStr("bye", "", 5) = "1" Then byeMsg = "Sesión cerrada correctamente."

DBOpen

errMsg  = ""
nextUrl = GetStr("next", "", 255)
If Request.Form("next").Count > 0 Then nextUrl = GetStr("next", "", 255)

' La redirección sólo puede apuntar a una ruta interna del sitio.
If nextUrl = "" Or Left(nextUrl, 1) <> "/" Or Left(nextUrl, 2) = "//" Then nextUrl = "/home.asp"

If UCase(NS(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then
    CheckCsrf

    username = GetStr("username", "", 50)
    Dim password : password = GetStr("password", "", 50)

    ' Pequeña protección contra fuerza bruta por sesión.
    If CLng("0" & NS(Session("PM_FAILS"))) >= 6 Then
        errMsg = "Demasiados intentos fallidos. Espera un momento y vuelve a intentarlo."
    ElseIf username = "" Or password = "" Then
        errMsg = "Escribe tu usuario y tu contraseña."
    Else
        Dim uid, utype, uphoto
        If Authenticate(username, password, uid, utype, uphoto) Then
            StartSession uid, username, utype, uphoto
            SetFlash "ok", "¡Bienvenido de nuevo, " & username & "!"
            Response.Redirect Url(nextUrl)
            Response.End
        Else
            Session("PM_FAILS") = CStr(CLng("0" & NS(Session("PM_FAILS"))) + 1)
            errMsg = "Usuario o contraseña incorrectos."
        End If
    End If
End If

AuthTop "Iniciar sesión"
%>
<div class="auth-card">
    <h1>Entrar a PoliMusic</h1>
    <p class="lead">Escucha tu música, organiza tus playlists y descubre nuevos artistas.</p>

    <% RenderFlash %>
    <% If byeMsg <> "" Then %>
    <div class="flash flash--ok" role="status">
        <span class="flash__icon" aria-hidden="true"></span><span><%= E(byeMsg) %></span>
    </div>
    <% End If %>
    <% If errMsg <> "" Then %>
    <div class="flash flash--error" role="alert">
        <span class="flash__icon" aria-hidden="true"></span><span><%= E(errMsg) %></span>
    </div>
    <% End If %>

    <form method="post" action="<%= Url("/login.asp") %>" data-once>
        <%= CsrfField %>
        <input type="hidden" name="next" value="<%= E(nextUrl) %>">

        <div class="form-grid">
            <div class="field">
                <label for="username">Usuario</label>
                <input type="text" id="username" name="username" maxlength="50" required autofocus
                       value="<%= E(username) %>" autocomplete="username">
            </div>
            <div class="field">
                <label for="password">Contraseña</label>
                <input type="password" id="password" name="password" maxlength="50" required
                       autocomplete="current-password">
            </div>
        </div>

        <div class="form-actions">
            <button class="btn btn--primary btn--block" type="submit">Entrar</button>
        </div>
    </form>

    <p class="auth-alt">¿No tienes cuenta? <a href="<%= Url("/register.asp") %>">Crear una cuenta</a></p>

    <div class="auth-hint">
        Cuentas de prueba creadas por el script de base de datos:<br>
        <b>userAdmin</b> / 12345678 (administrador)<br>
        <b>userNormal</b> / 12345678 (usuario)
    </div>
</div>
<%
AuthBottom
%>
