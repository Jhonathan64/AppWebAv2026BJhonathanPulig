<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="includes/config.asp" -->
<!-- #include file="includes/db.asp" -->
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/ui.asp" -->
<%
'=====================================================================
'  PoliMusic - albums.asp : catálogo de álbumes
'=====================================================================
RequireLogin
DBOpen

Dim rs, total
total = DBScalar("SELECT COUNT(*) FROM TBL_ALBUM", Null, 0)

PageTop "Álbumes", "albums"
%>
<% SectionHeader "Álbumes", total & " álbumes disponibles", "", "" %>

<div class="grid grid--wide">
    <%
    Set rs = DBQuery("SELECT A.ID_ALBUM, A.TITLE_ALBUM, A.RELEASE_YEAR, A.ALBUM_IMAGE_PATH, " & _
                     "(SELECT COUNT(*) FROM TBL_TRACKLIST T WHERE T.ID_ALBUM = A.ID_ALBUM) AS NSONGS " & _
                     "FROM TBL_ALBUM A ORDER BY ISNULL(A.RELEASE_YEAR, 0) DESC, A.TITLE_ALBUM", Null)
    If rs.EOF Then
        EmptyState "Todavía no hay álbumes en el catálogo."
    Else
        Do While Not rs.EOF
            AlbumCard rs("ID_ALBUM"), rs("TITLE_ALBUM"), rs("RELEASE_YEAR"), rs("ALBUM_IMAGE_PATH")
            rs.MoveNext
        Loop
    End If
    RSClose rs
    %>
</div>
<%
PageBottom
%>
