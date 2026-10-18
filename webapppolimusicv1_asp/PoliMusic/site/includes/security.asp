<%
'=====================================================================
'  PoliMusic - includes/security.asp
'  Autenticación, control de permisos en el SERVIDOR, CSRF y mensajes.
'=====================================================================

'---------------------------------------------------------------------
' Sesión
'---------------------------------------------------------------------
Function IsLoggedIn()
    IsLoggedIn = (NS(Session("PM_ID")) <> "" And IsNumeric(Session("PM_ID")))
End Function

Function CurrentUserId()
    If IsLoggedIn() Then CurrentUserId = CLng(Session("PM_ID")) Else CurrentUserId = 0
End Function

Function CurrentUserName()
    CurrentUserName = NS(Session("username"))
End Function

Function CurrentUserPhoto()
    CurrentUserPhoto = NS(Session("PM_PHOTO"))
End Function

' USER_TYPE: 1 = administrador (TBL_CATALOG COD_CATALOG_PARENT='1')
Function IsAdmin()
    IsAdmin = (IsLoggedIn() And NS(Session("role")) = "admin")
End Function

' Guarda los datos del usuario en la sesión.
Sub StartSession(ByVal idUser, ByVal username, ByVal userType, ByVal photo)
    Session.Timeout = 120
    Session("PM_ID")    = CStr(idUser)
    Session("PM_USER")  = username
    Session("username") = username
    Session("role") = "user"
    If CStr(userType) = CStr(USER_TYPE_ADMIN) Then Session("role") = "admin"
    Session("PM_TYPE")  = CStr(userType)
    Session("PM_PHOTO") = NS(photo)
    Session("PM_FAILS") = "0"
End Sub

Sub EndSession()
    Session.Contents.Remove("username")
    Session.Contents.Remove("role")
    Session.Contents.Remove("PM_ID")
    Session.Contents.Remove("PM_USER")
    Session.Contents.Remove("PM_TYPE")
    Session.Contents.Remove("PM_PHOTO")
    Session.Contents.Remove("PM_FAILS")
    Session.Abandon
End Sub

'---------------------------------------------------------------------
' Contraseñas
'   El hash se calcula con HASHBYTES('SHA1') de SQL Server, de modo que
'   la aplicación nunca concatena la contraseña dentro del SQL.
'   Las cuentas creadas por el script original (userAdmin / userNormal)
'   guardan la clave en texto plano: se acepta para no romper esos datos.
'---------------------------------------------------------------------
Function HashPassword(ByVal plain)
    Dim rs, h
    Set rs = DBQuery("SELECT CONVERT(varchar(40), HASHBYTES('SHA1', ?), 2)", Array(P(adVarChar, 100, plain)))
    If Not rs.EOF Then h = LCase(NS(rs(0))) Else h = ""
    rs.Close : Set rs = Nothing
    HashPassword = h
End Function

Function IsHex40(ByVal s)
    Dim i, c
    IsHex40 = False
    If Len(s) <> 40 Then Exit Function
    For i = 1 To 40
        c = LCase(Mid(s, i, 1))
        If Not ((c >= "0" And c <= "9") Or (c >= "a" And c <= "f")) Then Exit Function
    Next
    IsHex40 = True
End Function

Function VerifyPassword(ByVal stored, ByVal plain)
    Dim s
    VerifyPassword = False
    s = LCase(NS(stored))
    If s = "" Then Exit Function
    If IsHex40(s) Then
        VerifyPassword = (s = HashPassword(plain))
    Else
        ' Compatibilidad con los registros originales en texto plano.
        VerifyPassword = (NS(stored) = plain)
    End If
End Function

'---------------------------------------------------------------------
' Autenticación contra TBL_USER (consulta parametrizada)
'---------------------------------------------------------------------
Function Authenticate(ByVal username, ByVal password, ByRef outId, ByRef outType, ByRef outPhoto)
    Dim rs
    Authenticate = False
    outId = 0 : outType = USER_TYPE_USER : outPhoto = AVATAR_DEFAULT
    Set rs = DBQuery("SELECT ID_USER, PASSWORD, USER_TYPE, USER_PHOTO FROM TBL_USER WHERE USERNAME = ?", _
                     Array(P(adVarChar, 50, username)))
    If Not rs.EOF Then
        If VerifyPassword(rs("PASSWORD"), password) Then
            outId    = CLng(rs("ID_USER"))
            outType  = CInt(rs("USER_TYPE"))
            outPhoto = NS(rs("USER_PHOTO"))
            If outPhoto = "" Then outPhoto = AVATAR_DEFAULT
            Authenticate = True
        End If
    End If
    rs.Close : Set rs = Nothing
End Function

'---------------------------------------------------------------------
' Control de acceso (SIEMPRE en el servidor)
'---------------------------------------------------------------------
Sub RequireLogin()
    Dim back
    If IsLoggedIn() Then Exit Sub
    back = Request.ServerVariables("SCRIPT_NAME")
    If NS(Request.ServerVariables("QUERY_STRING")) <> "" Then
        back = back & "?" & Request.ServerVariables("QUERY_STRING")
    End If
    SetFlash "warn", "Inicia sesión para acceder a esa sección."
    Response.Redirect Url("/login.asp?next=" & Server.URLEncode(back))
    Response.End
End Sub

Sub RequireAdmin()
    RequireLogin
    If IsAdmin() Then Exit Sub
    SetFlash "error", "No tienes permisos para entrar al panel de administración."
    Response.Redirect Url("/home.asp")
    Response.End
End Sub

' Devuelve True si la playlist pertenece al usuario actual (o es admin).
Function OwnsPlaylist(ByVal idPlaylist)
    OwnsPlaylist = False
    If Not IsLoggedIn() Then Exit Function
    If IsAdmin() Then OwnsPlaylist = True : Exit Function
    OwnsPlaylist = DBExists("SELECT 1 FROM TBL_PLAYLIST WHERE ID_PLAYLIST = ? AND ID_USER = ?", _
                            Array(P(adInteger, 0, CLng(idPlaylist)), P(adInteger, 0, CurrentUserId())))
End Function

' Detiene la petición con un mensaje de acceso denegado.
Sub AccessDenied(ByVal msg)
    Response.Status = "403 Forbidden"
    SetFlash "error", msg
    Response.Redirect Url("/home.asp")
    Response.End
End Sub

'---------------------------------------------------------------------
' Protección CSRF para todos los formularios POST
'---------------------------------------------------------------------
Function RandomToken(ByVal n)
    Dim chars, i, s
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    Randomize
    s = ""
    For i = 1 To n
        s = s & Mid(chars, Int(Rnd * Len(chars)) + 1, 1)
    Next
    RandomToken = s
End Function

Function CsrfToken()
    If NS(Session("PM_CSRF")) = "" Then Session("PM_CSRF") = RandomToken(32)
    CsrfToken = Session("PM_CSRF")
End Function

' Campo oculto listo para imprimir dentro de un <form>.
Function CsrfField()
    CsrfField = "<input type=""hidden"" name=""csrf"" value=""" & E(CsrfToken()) & """>"
End Function

Sub CheckCsrf()
    If UCase(NS(Request.ServerVariables("REQUEST_METHOD"))) <> "POST" Then Exit Sub
    If NS(Request.Form("csrf")) <> NS(Session("PM_CSRF")) Then
        Response.Status = "400 Bad Request"
        SetFlash "error", "El formulario expiró o es inválido. Intenta de nuevo."
        Response.Redirect Url("/home.asp")
        Response.End
    End If
End Sub

'---------------------------------------------------------------------
' Mensajes flash (se muestran una sola vez)
'---------------------------------------------------------------------
Sub SetFlash(ByVal kind, ByVal msg)
    Session("PM_FLASH")      = msg
    Session("PM_FLASH_KIND") = kind     ' ok | warn | error
End Sub

Sub RenderFlash()
    Dim msg, kind
    msg  = NS(Session("PM_FLASH"))
    kind = NS(Session("PM_FLASH_KIND"))
    If kind = "" Then kind = "ok"
    Session.Contents.Remove("PM_FLASH")
    Session.Contents.Remove("PM_FLASH_KIND")
%>
    <% If msg <> "" Then %>
    <div class="flash flash--<%= kind %>" role="status">
        <span class="flash__icon" aria-hidden="true"></span>
        <span><%= E(msg) %></span>
        <button type="button" class="flash__close" aria-label="Cerrar">&times;</button>
    </div>
    <% End If %>
<%
End Sub
%>
