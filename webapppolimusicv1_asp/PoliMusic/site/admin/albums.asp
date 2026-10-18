<%@ Language=VBScript CodePage=65001 %>
<% Option Explicit %>
<!-- #include file="../includes/config.asp" -->
<!-- #include file="../includes/db.asp" -->
<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/ui.asp" -->
<!-- #include file="_tabs.asp" -->
<%
'=====================================================================
'  PoliMusic - admin/albums.asp
'  CRUD de TBL_ALBUM + administración del tracklist (TBL_TRACKLIST).
'=====================================================================
RequireAdmin
DBOpen

Dim action, errMsg, q, likeQ, rs
Dim editId, fTitle, fYear, fImage, idAlbum, yearVal

action = LCase(GetStr("action", "", 20))
errMsg = ""
editId = 0

If UCase(NS(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then
    CheckCsrf
    idAlbum = GetInt("id", 0)
    fTitle  = GetStr("TITLE_ALBUM", "", 50)
    fYear   = GetStr("RELEASE_YEAR", "", 4)
    fImage  = GetStr("ALBUM_IMAGE_PATH", "~/albumImages/album1.png", 255)
    yearVal = Null
    If fYear <> "" Then
        If IsNumeric(fYear) Then yearVal = CInt(fYear) Else errMsg = "El año debe ser numérico."
    End If

    Select Case action
        Case "create"
            If fTitle = "" Then
                errMsg = "El título del álbum es obligatorio."
            ElseIf errMsg = "" Then
                DBExec "INSERT INTO TBL_ALBUM (TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH) VALUES (?, ?, ?)", _
                       Array(P(adVarChar, 50, fTitle), P(adInteger, 0, yearVal), P(adVarChar, 255, fImage))
                SetFlash "ok", "Álbum «" & fTitle & "» creado."
                Response.Redirect Url("/admin/albums.asp")
                Response.End
            End If

        Case "update"
            If fTitle = "" Then
                errMsg = "El título del álbum es obligatorio."
            ElseIf errMsg = "" Then
                DBExec "UPDATE TBL_ALBUM SET TITLE_ALBUM = ?, RELEASE_YEAR = ?, ALBUM_IMAGE_PATH = ? WHERE ID_ALBUM = ?", _
                       Array(P(adVarChar, 50, fTitle), P(adInteger, 0, yearVal), _
                             P(adVarChar, 255, fImage), P(adInteger, 0, idAlbum))
                SetFlash "ok", "Álbum actualizado."
                Response.Redirect Url("/admin/albums.asp?edit=" & idAlbum)
                Response.End
            End If

        Case "delete"
            On Error Resume Next
            DBBeginTrans
            DBExec "DELETE FROM TBL_TRACKLIST WHERE ID_ALBUM = ?", Array(P(adInteger, 0, idAlbum))
            DBExec "DELETE FROM TBL_ALBUM WHERE ID_ALBUM = ?", Array(P(adInteger, 0, idAlbum))
            If Err.Number <> 0 Then
                DBRollbackTrans
                On Error Goto 0
                SetFlash "error", "No se pudo eliminar el álbum: " & Err.Description
            Else
                DBCommitTrans
                On Error Goto 0
                SetFlash "ok", "Álbum eliminado."
            End If
            Response.Redirect Url("/admin/albums.asp")
            Response.End

        Case "track_add"
            Dim idSongAdd : idSongAdd = GetInt("idSong", 0)
            If idSongAdd > 0 And idAlbum > 0 Then
                If Not DBExists("SELECT 1 FROM TBL_TRACKLIST WHERE ID_ALBUM = ? AND ID_SONG = ?", _
                                Array(P(adInteger, 0, idAlbum), P(adInteger, 0, idSongAdd))) Then
                    DBExec "INSERT INTO TBL_TRACKLIST (ID_ALBUM, ID_SONG) VALUES (?, ?)", _
                           Array(P(adInteger, 0, idAlbum), P(adInteger, 0, idSongAdd))
                    SetFlash "ok", "Canción agregada al tracklist."
                Else
                    SetFlash "warn", "Esa canción ya está en el álbum."
                End If
            End If
            Response.Redirect Url("/admin/albums.asp?edit=" & idAlbum)
            Response.End

        Case "track_remove"
            Dim idSongDel : idSongDel = GetInt("idSong", 0)
            DBExec "DELETE FROM TBL_TRACKLIST WHERE ID_ALBUM = ? AND ID_SONG = ?", _
                   Array(P(adInteger, 0, idAlbum), P(adInteger, 0, idSongDel))
            SetFlash "ok", "Canción quitada del tracklist."
            Response.Redirect Url("/admin/albums.asp?edit=" & idAlbum)
            Response.End
    End Select
End If

If GetInt("edit", 0) > 0 Then
    editId = GetInt("edit", 0)
    Set rs = DBQuery("SELECT ID_ALBUM, TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH FROM TBL_ALBUM WHERE ID_ALBUM = ?", _
                     Array(P(adInteger, 0, editId)))
    If Not rs.EOF Then
        fTitle = rs("TITLE_ALBUM")
        If IsNull(rs("RELEASE_YEAR")) Then fYear = "" Else fYear = CStr(rs("RELEASE_YEAR"))
        fImage = NS(rs("ALBUM_IMAGE_PATH"))
    End If
    RSClose rs
End If

q     = GetStr("q", "", 80)
likeQ = "%" & q & "%"

PageTop "Álbumes", "admin"
%>
<% SectionHeader "Álbumes", "Alta, consulta, edición, baja y tracklist", Url("/admin/default.asp"), "Volver al panel" %>
<% AdminTabs "Álbumes" %>

<section class="panel">
    <h2 class="panel__title"><% If editId > 0 Then %>Editar álbum #<%= editId %><% Else %>Nuevo álbum<% End If %></h2>
    <p class="panel__sub">La carátula se usa también como portada de las canciones del álbum.</p>

    <% If errMsg <> "" Then %>
    <div class="flash flash--error" role="alert">
        <span class="flash__icon" aria-hidden="true"></span><span><%= E(errMsg) %></span>
    </div>
    <% End If %>

    <form method="post" action="<%= Url("/admin/albums.asp") %>" data-once>
        <%= CsrfField %>
        <input type="hidden" name="action" value="<% If editId > 0 Then %>update<% Else %>create<% End If %>">
        <% If editId > 0 Then %><input type="hidden" name="id" value="<%= editId %>"><% End If %>

        <div class="form-grid">
            <div class="field">
                <label for="TITLE_ALBUM">Título *</label>
                <input type="text" id="TITLE_ALBUM" name="TITLE_ALBUM" maxlength="50" required value="<%= E(fTitle) %>">
            </div>
            <div class="field">
                <label for="RELEASE_YEAR">Año de lanzamiento</label>
                <input type="number" id="RELEASE_YEAR" name="RELEASE_YEAR" min="1900" max="2100" value="<%= E(fYear) %>">
            </div>
            <div class="field">
                <label for="ALBUM_IMAGE_PATH">Carátula</label>
                <select id="ALBUM_IMAGE_PATH" name="ALBUM_IMAGE_PATH">
                    <% AlbumOptions fImage %>
                </select>
            </div>
        </div>

        <div class="form-actions">
            <button class="btn btn--primary" type="submit"><% If editId > 0 Then %>Guardar cambios<% Else %>Crear álbum<% End If %></button>
            <% If editId > 0 Then %><a class="btn btn--ghost" href="<%= Url("/admin/albums.asp") %>">Cancelar</a><% End If %>
        </div>
    </form>
</section>

<% If editId > 0 Then %>
<!-- ---------------- Tracklist del álbum en edición ---------------- -->
<section class="panel">
    <h2 class="panel__title">Tracklist de «<%= E(fTitle) %>»</h2>
    <p class="panel__sub">Agrega o quita canciones de este álbum (TBL_TRACKLIST).</p>

    <div class="table-wrap">
    <table class="table">
        <thead><tr><th>#</th><th>Canción</th><th class="table__actions">Acción</th></tr></thead>
        <tbody>
        <%
        Set rs = DBQuery("SELECT S.ID_SONG, S.SONG_NAME FROM TBL_TRACKLIST T " & _
                         "INNER JOIN TBL_SONG S ON S.ID_SONG = T.ID_SONG WHERE T.ID_ALBUM = ? ORDER BY S.SONG_NAME", _
                         Array(P(adInteger, 0, editId)))
        If rs.EOF Then
        %>
            <tr><td colspan="3" class="muted">Este álbum no tiene canciones todavía.</td></tr>
        <%
        Else
            Do While Not rs.EOF
        %>
            <tr>
                <td><%= rs("ID_SONG") %></td>
                <td><strong><%= E(rs("SONG_NAME")) %></strong></td>
                <td>
                    <div class="table__actions">
                        <form method="post" action="<%= Url("/admin/albums.asp") %>" style="display:inline">
                            <%= CsrfField %>
                            <input type="hidden" name="action" value="track_remove">
                            <input type="hidden" name="id" value="<%= editId %>">
                            <input type="hidden" name="idSong" value="<%= rs("ID_SONG") %>">
                            <button class="icon-btn" type="submit" title="Quitar del álbum">
                                <span class="ico ico--minus" aria-hidden="true"></span>
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

    <form method="post" action="<%= Url("/admin/albums.asp") %>" class="toolbar" style="margin-top:14px">
        <%= CsrfField %>
        <input type="hidden" name="action" value="track_add">
        <input type="hidden" name="id" value="<%= editId %>">
        <div class="field" style="min-width:240px;flex:1 1 240px">
            <label for="idSong">Agregar canción</label>
            <select id="idSong" name="idSong">
                <%
                Set rs = DBQuery("SELECT S.ID_SONG, S.SONG_NAME FROM TBL_SONG S WHERE NOT EXISTS " & _
                                 "(SELECT 1 FROM TBL_TRACKLIST T WHERE T.ID_ALBUM = ? AND T.ID_SONG = S.ID_SONG) " & _
                                 "ORDER BY S.SONG_NAME", Array(P(adInteger, 0, editId)))
                Do While Not rs.EOF
                %>
                <option value="<%= rs("ID_SONG") %>"><%= E(rs("SONG_NAME")) %></option>
                <%
                    rs.MoveNext
                Loop
                RSClose rs
                %>
            </select>
        </div>
        <button class="btn btn--soft" type="submit">
            <span class="ico ico--plus" aria-hidden="true"></span> Agregar
        </button>
    </form>
</section>
<% End If %>

<section>
    <% SectionHeader "Listado de álbumes", "Busca por título", "", "" %>

    <form class="toolbar" method="get" action="<%= Url("/admin/albums.asp") %>">
        <div class="searchbox">
            <span class="ico ico--search" aria-hidden="true"></span>
            <input type="search" name="q" value="<%= E(q) %>" placeholder="Buscar álbum...">
        </div>
        <button class="btn btn--soft" type="submit">Buscar</button>
        <% If q <> "" Then %><a class="btn btn--ghost" href="<%= Url("/admin/albums.asp") %>">Limpiar</a><% End If %>
    </form>

    <div class="table-wrap">
    <table class="table">
        <thead>
            <tr><th>#</th><th></th><th>Álbum</th><th>Año</th><th>Canciones</th><th class="table__actions">Acciones</th></tr>
        </thead>
        <tbody>
        <%
        Dim sqlList, params
        If q <> "" Then
            sqlList = "SELECT A.ID_ALBUM, A.TITLE_ALBUM, A.RELEASE_YEAR, A.ALBUM_IMAGE_PATH, " & _
                      "(SELECT COUNT(*) FROM TBL_TRACKLIST T WHERE T.ID_ALBUM = A.ID_ALBUM) AS NSONGS " & _
                      "FROM TBL_ALBUM A WHERE A.TITLE_ALBUM LIKE ? ORDER BY A.TITLE_ALBUM"
            params = Array(P(adVarChar, 80, likeQ))
        Else
            sqlList = "SELECT A.ID_ALBUM, A.TITLE_ALBUM, A.RELEASE_YEAR, A.ALBUM_IMAGE_PATH, " & _
                      "(SELECT COUNT(*) FROM TBL_TRACKLIST T WHERE T.ID_ALBUM = A.ID_ALBUM) AS NSONGS " & _
                      "FROM TBL_ALBUM A ORDER BY A.ID_ALBUM"
            params = Null
        End If
        Set rs = DBQuery(sqlList, params)
        If rs.EOF Then
        %>
            <tr><td colspan="6" class="muted">No hay álbumes para mostrar.</td></tr>
        <%
        Else
            Do While Not rs.EOF
        %>
            <tr>
                <td><%= rs("ID_ALBUM") %></td>
                <td><img class="thumb" src="<%= AssetUrl(rs("ALBUM_IMAGE_PATH"), COVER_DEFAULT) %>" alt=""></td>
                <td><strong><%= E(rs("TITLE_ALBUM")) %></strong></td>
                <td><%= E(YearLabel(rs("RELEASE_YEAR"))) %></td>
                <td><%= rs("NSONGS") %></td>
                <td>
                    <div class="table__actions">
                        <a class="icon-btn" title="Editar y ver tracklist" href="<%= Url("/admin/albums.asp?edit=" & rs("ID_ALBUM")) %>">
                            <span class="ico ico--edit" aria-hidden="true"></span>
                        </a>
                        <form method="post" action="<%= Url("/admin/albums.asp") %>" style="display:inline"
                              data-confirm="¿Eliminar el álbum <%= E(rs("TITLE_ALBUM")) %>?">
                            <%= CsrfField %>
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="id" value="<%= rs("ID_ALBUM") %>">
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
