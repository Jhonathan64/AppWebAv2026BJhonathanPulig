<%
'=====================================================================
'  PoliMusic - includes/db.asp
'  Capa de acceso a datos. TODA consulta que recibe datos del usuario
'  se ejecuta con parámetros (ADODB.Command) para evitar inyección SQL.
'=====================================================================

Dim DB_CONN

' Abre la conexión (una por petición).
Sub DBOpen()
    If Not IsObject(DB_CONN) Then
        Set DB_CONN = Server.CreateObject("ADODB.Connection")
        DB_CONN.CursorLocation = 3      ' adUseClient
        DB_CONN.Open DB_CONN_STRING
    End If
End Sub

' Cierra y libera la conexión.
Sub DBClose()
    If IsObject(DB_CONN) Then
        On Error Resume Next            ' si quedó una transacción abierta, se descarta
        If DB_CONN.State <> 0 Then DB_CONN.RollbackTrans
        If DB_CONN.State <> 0 Then DB_CONN.Close
        On Error Goto 0
        Set DB_CONN = Nothing
    End If
End Sub

'---------------------------------------------------------------------
' Transacciones (se usan al borrar datos con tablas relacionadas)
'---------------------------------------------------------------------
Sub DBBeginTrans()
    DB_CONN.BeginTrans
End Sub
Sub DBCommitTrans()
    If DB_CONN.State <> 0 Then DB_CONN.CommitTrans
End Sub
Sub DBRollbackTrans()
    If DB_CONN.State <> 0 Then DB_CONN.RollbackTrans
End Sub

'---------------------------------------------------------------------
' Prepara un ADODB.Command con sus parámetros.
'   params = Array(P(adVarChar, 50, valor), P(adInteger, 0, valor), ...)
'---------------------------------------------------------------------
Function BuildCommand(ByVal sql, ByVal params)
    Dim cmd, i, prm
    Set cmd = Server.CreateObject("ADODB.Command")
    Set cmd.ActiveConnection = DB_CONN
    cmd.CommandType = 1                 ' adCmdText
    cmd.CommandText = sql
    If IsArray(params) Then
        For i = 0 To UBound(params)
            Set prm = cmd.CreateParameter("p" & i, CLng(params(i)(0)), adParamInput, CLng(params(i)(1)), params(i)(2))
            cmd.Parameters.Append prm
        Next
    End If
    Set BuildCommand = cmd
End Function

'---------------------------------------------------------------------
' DBQuery -> devuelve un Recordset de sólo lectura (desconectado).
'---------------------------------------------------------------------
Function DBQuery(ByVal sql, ByVal params)
    Dim cmd, rs
    Set cmd = BuildCommand(sql, params)
    Set rs = Server.CreateObject("ADODB.Recordset")
    rs.CursorLocation = 3               ' adUseClient (permite RecordCount y paginar)
    rs.Open cmd, , 3, 1                 ' adOpenStatic / adLockReadOnly
    Set DBQuery = rs
End Function

'---------------------------------------------------------------------
' DBExec -> INSERT / UPDATE / DELETE. Devuelve las filas afectadas.
'---------------------------------------------------------------------
Function DBExec(ByVal sql, ByVal params)
    Dim cmd, affected
    affected = 0
    Set cmd = BuildCommand(sql, params)
    cmd.Execute affected
    DBExec = affected
End Function

'---------------------------------------------------------------------
' DBScalar -> primer campo de la primera fila (o valor por defecto).
'---------------------------------------------------------------------
Function DBScalar(ByVal sql, ByVal params, ByVal def)
    Dim rs, v
    v = def
    Set rs = DBQuery(sql, params)
    If Not rs.EOF Then
        If IsNull(rs(0)) Then v = def Else v = rs(0)
    End If
    rs.Close
    Set rs = Nothing
    DBScalar = v
End Function

'---------------------------------------------------------------------
' DBExists -> True si la consulta devuelve al menos una fila.
'---------------------------------------------------------------------
Function DBExists(ByVal sql, ByVal params)
    Dim rs, ok
    Set rs = DBQuery(sql, params)
    ok = Not rs.EOF
    rs.Close
    Set rs = Nothing
    DBExists = ok
End Function

'---------------------------------------------------------------------
' Libera un Recordset de forma segura.
'---------------------------------------------------------------------
Sub RSClose(ByRef rs)
    If IsObject(rs) Then
        If Not rs Is Nothing Then
            If rs.State <> 0 Then rs.Close
            Set rs = Nothing
        End If
    End If
End Sub

'---------------------------------------------------------------------
' Cierra el Recordset y la conexión al final de cada página.
'---------------------------------------------------------------------
Sub DBFinish()
    DBClose
End Sub
%>
