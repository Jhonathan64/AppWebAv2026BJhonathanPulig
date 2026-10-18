<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="includes/config.asp" -->
<!-- #include file="includes/db.asp" -->
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/ui.asp" -->
<%
'=====================================================================
'  PoliMusic - artists.asp : catálogo de artistas
'=====================================================================
RequireLogin
DBOpen

Dim rs, total
total = DBScalar("SELECT COUNT(*) FROM TBL_ARTIST", Null, 0)

PageTop "Artistas", "artists"
%>
<% SectionHeader "Artistas", total & " artistas registrados", "", "" %>

<div class="grid grid--wide">
    <%
    Set rs = DBQuery("SELECT AR.ID_ARTIST, AR.ARTIST_NAME, AR.ARTIST_LASTNAME, AR.ARTIST_IMAGE, " & _
                     "(SELECT COUNT(*) FROM TBL_PLAYER P WHERE P.ID_ARTIST = AR.ID_ARTIST) AS NSONGS, " & _
                     "(SELECT COUNT(DISTINCT T.ID_ALBUM) FROM TBL_PLAYER P2 " & _
                     "  INNER JOIN TBL_TRACKLIST T ON T.ID_SONG = P2.ID_SONG WHERE P2.ID_ARTIST = AR.ID_ARTIST) AS NALBUMS " & _
                     "FROM TBL_ARTIST AR ORDER BY AR.ARTIST_NAME, AR.ARTIST_LASTNAME", Null)
    If rs.EOF Then
        EmptyState "Todavía no hay artistas registrados."
    Else
        Do While Not rs.EOF
            ArtistCard rs("ID_ARTIST"), rs("ARTIST_NAME"), rs("ARTIST_LASTNAME"), rs("ARTIST_IMAGE")
            rs.MoveNext
        Loop
    End If
    RSClose rs
    %>
</div>
<%
PageBottom
%>
