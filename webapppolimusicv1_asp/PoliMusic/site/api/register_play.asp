<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="../includes/config.asp" -->
<!-- #include file="../includes/db.asp" -->
<!-- #include file="../includes/security.asp" -->
<%
'=====================================================================
'  PoliMusic - api/register_play.asp
'  Suma una reproducción al contador PLAYS de TBL_SONG.
'  Lo llama el reproductor (JavaScript) al iniciar una canción.
'=====================================================================
Response.ContentType = "text/plain"
Response.Charset = "UTF-8"

Dim idSong
idSong = GetInt("id", 0)

If Not IsLoggedIn() Then
    Response.Write "nologin"
    Response.End
End If

If idSong > 0 Then
    DBOpen
    DBExec "UPDATE TBL_SONG SET PLAYS = ISNULL(PLAYS, 0) + 1 WHERE ID_SONG = ?", _
           Array(P(adInteger, 0, idSong))
    DBClose
End If

Response.Write "ok"
%>
