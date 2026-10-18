<%
'=====================================================================
'  PoliMusic - includes/config.asp
'  Configuración general, constantes y helpers de formato.
'  (Este archivo se incluye con <!-- #include file="..." -->)
'=====================================================================

'---------------------------------------------------------------------
' 1. Conexión a SQL Server
'    Docker: 127.0.0.1,14333 / BDD_PoliMusic / sa.
'    La clave local se guarda en config.local.asp, excluido de Git.
%>
<!-- #include file="config.local.asp" -->
<%

'---------------------------------------------------------------------
' 2. Raíz del sitio
'    "" si PoliMusic se publica como sitio raíz (http://localhost/).
'    "/PoliMusic" si se publica como aplicación/virtual directory.
'---------------------------------------------------------------------
Const SITE_ROOT = ""

'---------------------------------------------------------------------
' 3. Constantes de la aplicación
'---------------------------------------------------------------------
Const APP_NAME       = "PoliMusic"
Const PAGE_SIZE      = 12          ' resultados por página en el buscador
Const COVER_DEFAULT  = "~/albumImages/album1.png"
Const AVATAR_DEFAULT = "~/userImages/default.jpg"
Const COVER_PLAYLIST = "~/playlistImages/default.jpg"

' Tipos de usuario  (TBL_CATALOG, COD_CATALOG_PARENT = '1')
Const USER_TYPE_USER  = 0
Const USER_TYPE_ADMIN = 1

' Tipos de playlist (TBL_CATALOG, COD_CATALOG_PARENT = '2')
Const PLAYLIST_PUBLIC  = 0
Const PLAYLIST_PRIVATE = 1

' Tipos de datos ADO (se declaran aquí para no depender de adovbs.inc)
Const adInteger     = 3
Const adVarChar     = 200
Const adBoolean     = 11
Const adDate        = 7
Const adDBTimeStamp = 135
Const adParamInput  = 1

'---------------------------------------------------------------------
' 4. Codificación (todo el sitio trabaja en UTF-8)
'---------------------------------------------------------------------
Response.CodePage = 65001
Response.Charset  = "UTF-8"
Session.CodePage  = 65001
Response.Buffer   = True

'---------------------------------------------------------------------
' 5. Fragmentos SQL reutilizables
'    TBL_SONG no tiene carátula propia: se toma la del primer álbum
'    al que pertenece la canción (alias obligatorio de la canción: S).
'---------------------------------------------------------------------
Dim SQL_SONG_ARTISTS
SQL_SONG_ARTISTS = "ISNULL(STUFF((SELECT ', ' + (A.ARTIST_NAME + ISNULL(' ' + A.ARTIST_LASTNAME, '')) " & _
                         "FROM TBL_PLAYER P INNER JOIN TBL_ARTIST A ON A.ID_ARTIST = P.ID_ARTIST " & _
                         "WHERE P.ID_SONG = S.ID_SONG FOR XML PATH(''), TYPE).value('.', 'varchar(max)'), 1, 2, ''), 'Artista desconocido')"

Dim SQL_SONG_COVER
SQL_SONG_COVER = "ISNULL((SELECT TOP 1 AL.ALBUM_IMAGE_PATH FROM TBL_TRACKLIST TL " & _
                       "INNER JOIN TBL_ALBUM AL ON AL.ID_ALBUM = TL.ID_ALBUM " & _
                       "WHERE TL.ID_SONG = S.ID_SONG ORDER BY TL.ID_ALBUM), '" & COVER_DEFAULT & "')"

'---------------------------------------------------------------------
' 6. Helpers de salida y formato
'---------------------------------------------------------------------

' VBScript no incluye IIf de Visual Basic.
Function IIf(ByVal condition, ByVal whenTrue, ByVal whenFalse)
    If condition Then IIf = whenTrue Else IIf = whenFalse
End Function

' Devuelve texto seguro para HTML (evita XSS).
Function E(ByVal v)
    If IsNull(v) Then
        E = ""
    Else
        E = Server.HTMLEncode(CStr(v))
    End If
End Function

' Convierte NULL en cadena vacía (útil al leer campos opcionales).
Function NS(ByVal v)
    If IsNull(v) Then NS = "" Else NS = CStr(v)
End Function

' Construye un parámetro para consultas preparadas: P(tipo, tamaño, valor)
Function P(ByVal adoType, ByVal size, ByVal value)
    P = Array(CLng(adoType), CLng(size), value)
End Function

' Convierte rutas de la BD ("~/songFiles/x.mp3") en URL válidas del sitio.
Function AssetUrl(ByVal dbPath, ByVal fallback)
    Dim p
    p = NS(dbPath)
    If p = "" Then p = NS(fallback)
    If p = "" Then p = COVER_DEFAULT
    If Left(p, 2) = "~/" Then
        p = Mid(p, 2)
    ElseIf Left(p, 1) = "~" Then
        p = Mid(p, 2)
    End If
    If Left(p, 1) <> "/" Then p = "/" & p
    AssetUrl = SITE_ROOT & p
End Function

' URL absoluta dentro del sitio.
Function Url(ByVal relative)
    If Left(relative, 1) <> "/" Then relative = "/" & relative
    Url = SITE_ROOT & relative
End Function

' Formato de fecha legible (aaaa-mm-dd) o "-" si no hay valor.
Function FormatDate(ByVal v)
    If IsNull(v) Or NS(v) = "" Then
        FormatDate = "-"
    Else
        FormatDate = Year(v) & "-" & Right("0" & Month(v), 2) & "-" & Right("0" & Day(v), 2)
    End If
End Function

' Lee un entero desde QueryString/Form con valor por defecto.
Function GetInt(ByVal name, ByVal def)
    Dim v
    v = Trim(NS(Request(name)))
    If v = "" Or Not IsNumeric(v) Then
        GetInt = def
    Else
        GetInt = CLng(v)
    End If
End Function

' Lee texto desde QueryString/Form, recortado y limitado.
Function GetStr(ByVal name, ByVal def, ByVal maxLen)
    Dim v
    v = Trim(NS(Request(name)))
    If v = "" Then
        GetStr = def
    ElseIf maxLen > 0 And Len(v) > maxLen Then
        GetStr = Left(v, maxLen)
    Else
        GetStr = v
    End If
End Function
%>
