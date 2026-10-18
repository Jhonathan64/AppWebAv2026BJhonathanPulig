<%
'=====================================================================
'  PoliMusic - admin/_tabs.asp
'  Navegación entre los módulos del panel de administración.
'=====================================================================
Sub AdminTabs(ByVal active)
    Dim items(4, 1), i
    items(0, 0) = "Usuarios"   : items(0, 1) = Url("/admin/users.asp")
    items(1, 0) = "Canciones"  : items(1, 1) = Url("/admin/songs.asp")
    items(2, 0) = "Álbumes"    : items(2, 1) = Url("/admin/albums.asp")
    items(3, 0) = "Artistas"   : items(3, 1) = Url("/admin/artists.asp")
    items(4, 0) = "Playlists"  : items(4, 1) = Url("/admin/playlists.asp")
%>
<nav class="admin-tabs" aria-label="Módulos de administración">
    <% For i = 0 To UBound(items, 1) %>
    <a class="<%= IsActive(active, items(i, 0)) %>" href="<%= items(i, 1) %>"><%= E(items(i, 0)) %></a>
    <% Next %>
    <a class="<%= IsActive(active, "Panel") %>" href="<%= Url("/admin/default.asp") %>">Resumen</a>
</nav>
<%
End Sub
%>
