<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="includes/config.asp" -->
<!-- #include file="includes/db.asp" -->
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/ui.asp" -->
<%
'=====================================================================
'  PoliMusic - default.asp : puerta de entrada
'=====================================================================
If IsLoggedIn() Then
    Response.Redirect Url("/home.asp")
Else
    Response.Redirect Url("/login.asp")
End If
%>
