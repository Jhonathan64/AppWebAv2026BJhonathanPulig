<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="../includes/config.asp" -->
<!-- #include file="../includes/db.asp" -->
<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/ui.asp" -->
<!-- #include file="_tabs.asp" -->
<%
'=====================================================================
'  PoliMusic - admin/artists.asp
'  CRUD de TBL_ARTIST (nombre, apellido, imagen).
'=====================================================================
RequireAdmin
DBOpen

Dim action, errMsg, q, likeQ, rs
Dim editId, fName, fLast, fImage, idArtist

action = LCase(GetStr("action", "", 20))
errMsg = ""
editId = 0

If UCase(NS(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then
    CheckCsrf
    idArtist = GetInt("id", 0)
    fName    = GetStr("ARTIST_NAME", "", 100)
    fLast    = GetStr("ARTIST_LASTNAME", "", 100)
    fImage   = GetStr("ARTIST_IMAGE", "~/ArtistImages/artist1.jpg", 255)

    Select Case action
        Case "create"
            If fName = "" Then
                errMsg = "El nombre del artista es obligatorio."
            Else
                DBExec "INSERT INTO TBL_ARTIST (ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE) VALUES (?, ?, ?)", _
                       Array(P(adVarChar, 100, fName), P(adVarChar, 100, fLast), P(adVarChar, 255, fImage))
                SetFlash "ok", "Artista «" & fName & "» creado."
                Response.Redirect Url("/admin/artists.asp")
                Response.End
            End If

        Case "update"
            If fName = "" Then
                errMsg = "El nombre del artista es obligatorio."
            Else
                DBExec "UPDATE TBL_ARTIST SET ARTIST_NAME = ?, ARTIST_LASTNAME = ?, ARTIST_IMAGE = ? WHERE ID_ARTIST = ?", _
                       Array(P(adVarChar, 100, fName), P(adVarChar, 100, fLast), _
                             P(adVarChar, 255, fImage), P(adInteger, 0, idArtist))
                SetFlash "ok", "Artista actualizado."
                Response.Redirect Url("/admin/artists.asp")
                Response.End
            End If

        Case "delete"
            On Error Resume Next
            DBBeginTrans
            DBExec "DELETE FROM TBL_PLAYER WHERE ID_ARTIST = ?", Array(P(adInteger, 0, idArtist))
            DBExec "DELETE FROM TBL_ARTIST WHERE ID_ARTIST = ?", Array(P(adInteger, 0, idArtist))
            If Err.Number <> 0 Then
                DBRollbackTrans
                On Error Goto 0
                SetFlash "error", "No se pudo eliminar el artista: " & Err.Description
            Else
                DBCommitTrans
                On Error Goto 0
                SetFlash "ok", "Artista eliminado."
            End If
            Response.Redirect Url("/admin/artists.asp")
            Response.End
    End Select
End If

If GetInt("edit", 0) > 0 Then
    editId = GetInt("edit", 0)
    Set rs = DBQuery("SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE FROM TBL_ARTIST WHERE ID_ARTIST = ?", _
                     Array(P(adInteger, 0, editId)))
    If Not rs.EOF Then
        fName  = rs("ARTIST_NAME")
        fLast  = NS(rs("ARTIST_LASTNAME"))
        fImage = NS(rs("ARTIST_IMAGE"))
    End If
    RSClose rs
End If

q     = GetStr("q", "", 80)
likeQ = "%" & q & "%"

PageTop "Artistas", "admin"
%>
<% SectionHeader "Artistas", "Alta, consulta, edición y baja de artistas", Url("/admin/default.asp"), "Volver al panel" %>
<% AdminTabs "Artistas" %>

<section class="panel">
    <h2 class="panel__title"><% If editId > 0 Then %>Editar artista #<%= editId %><% Else %>Nuevo artista<% End If %></h2>
    <p class="panel__sub">La relación artista ↔ canción se guarda en TBL_PLAYER.</p>

    <% If errMsg <> "" Then %>
    <div class="flash flash--error" role="alert">
        <span class="flash__icon" aria-hidden="true"></span><span><%= E(errMsg) %></span>
    </div>
    <% End If %>

    <form method="post" action="<%= Url("/admin/artists.asp") %>" data-once>
        <%= CsrfField %>
        <input type="hidden" name="action" value="<% If editId > 0 Then %>update<% Else %>create<% End If %>">
        <% If editId > 0 Then %><input type="hidden" name="id" value="<%= editId %>"><% End If %>

        <div class="form-grid">
            <div class="field">
                <label for="ARTIST_NAME">Nombre *</label>
                <input type="text" id="ARTIST_NAME" name="ARTIST_NAME" maxlength="100" required value="<%= E(fName) %>">
            </div>
            <div class="field">
                <label for="ARTIST_LASTNAME">Apellido</label>
                <input type="text" id="ARTIST_LASTNAME" name="ARTIST_LASTNAME" maxlength="100" value="<%= E(fLast) %>">
            </div>
            <div class="field">
                <label for="ARTIST_IMAGE">Imagen</label>
                <select id="ARTIST_IMAGE" name="ARTIST_IMAGE">
                    <% ArtistOptions fImage %>
                </select>
            </div>
        </div>

        <div class="form-actions">
            <button class="btn btn--primary" type="submit"><% If editId > 0 Then %>Guardar cambios<% Else %>Crear artista<% End If %></button>
            <% If editId > 0 Then %><a class="btn btn--ghost" href="<%= Url("/admin/artists.asp") %>">Cancelar</a><% End If %>
        </div>
    </form>
</section>

<section>
    <% SectionHeader "Listado de artistas", "Busca por nombre o apellido", "", "" %>

    <form class="toolbar" method="get" action="<%= Url("/admin/artists.asp") %>">
        <div class="searchbox">
            <span class="ico ico--search" aria-hidden="true"></span>
            <input type="search" name="q" value="<%= E(q) %>" placeholder="Buscar artista...">
        </div>
        <button class="btn btn--soft" type="submit">Buscar</button>
        <% If q <> "" Then %><a class="btn btn--ghost" href="<%= Url("/admin/artists.asp") %>">Limpiar</a><% End If %>
    </form>

    <div class="table-wrap">
    <table class="table">
        <thead>
            <tr><th>#</th><th></th><th>Artista</th><th>Canciones</th><th class="table__actions">Acciones</th></tr>
        </thead>
        <tbody>
        <%
        Dim sqlList, params
        If q <> "" Then
            sqlList = "SELECT AR.ID_ARTIST, AR.ARTIST_NAME, AR.ARTIST_LASTNAME, AR.ARTIST_IMAGE, " & _
                      "(SELECT COUNT(*) FROM TBL_PLAYER P WHERE P.ID_ARTIST = AR.ID_ARTIST) AS NSONGS " & _
                      "FROM TBL_ARTIST AR WHERE AR.ARTIST_NAME LIKE ? OR ISNULL(AR.ARTIST_LASTNAME,'') LIKE ? " & _
                      "ORDER BY AR.ARTIST_NAME, AR.ARTIST_LASTNAME"
            params = Array(P(adVarChar, 80, likeQ), P(adVarChar, 80, likeQ))
        Else
            sqlList = "SELECT AR.ID_ARTIST, AR.ARTIST_NAME, AR.ARTIST_LASTNAME, AR.ARTIST_IMAGE, " & _
                      "(SELECT COUNT(*) FROM TBL_PLAYER P WHERE P.ID_ARTIST = AR.ID_ARTIST) AS NSONGS " & _
                      "FROM TBL_ARTIST AR ORDER BY AR.ID_ARTIST"
            params = Null
        End If
        Set rs = DBQuery(sqlList, params)
        If rs.EOF Then
        %>
            <tr><td colspan="5" class="muted">No hay artistas para mostrar.</td></tr>
        <%
        Else
            Do While Not rs.EOF
        %>
            <tr>
                <td><%= rs("ID_ARTIST") %></td>
                <td><img class="thumb" src="<%= AssetUrl(rs("ARTIST_IMAGE"), COVER_DEFAULT) %>" alt=""></td>
                <td><strong><%= E(rs("ARTIST_NAME") & " " & NS(rs("ARTIST_LASTNAME"))) %></strong></td>
                <td><%= rs("NSONGS") %></td>
                <td>
                    <div class="table__actions">
                        <a class="icon-btn" title="Editar" href="<%= Url("/admin/artists.asp?edit=" & rs("ID_ARTIST")) %>">
                            <span class="ico ico--edit" aria-hidden="true"></span>
                        </a>
                        <form method="post" action="<%= Url("/admin/artists.asp") %>" style="display:inline"
                              data-confirm="¿Eliminar al artista <%= E(rs("ARTIST_NAME")) %>?">
                            <%= CsrfField %>
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="id" value="<%= rs("ID_ARTIST") %>">
                            <button class="icon-btn" type="submit" title="Eliminar">
                                <span class="ico ico--trash" aria-hidden="true"></span>
                            </button>
                        </form>
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
