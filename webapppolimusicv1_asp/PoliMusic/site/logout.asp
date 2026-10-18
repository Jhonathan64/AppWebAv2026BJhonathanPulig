<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="includes/config.asp" -->
<!-- #include file="includes/db.asp" -->
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/ui.asp" -->
<%
'=====================================================================
'  PoliMusic - logout.asp : cierre de sesión
'  Se destruye la sesión en el servidor y se vuelve al login.
'=====================================================================
EndSession
Response.Redirect Url("/login.asp?bye=1")
%>
