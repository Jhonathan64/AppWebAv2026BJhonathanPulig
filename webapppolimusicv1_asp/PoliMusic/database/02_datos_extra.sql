/* =====================================================================
   PoliMusic - 02_datos_extra.sql
   Ejecutar DESPUÉS de BDD_PoliMusic.sql.
   Agrega el usuario normal solicitado (Jhonathan Pulig) y un juego de
   playlists de ejemplo. No modifica la estructura de la base de datos:
   sólo inserta registros respetando las tablas existentes.

   Nota: la contraseña se guarda como SHA1 en texto hexadecimal
   (HASHBYTES('SHA1','12345678') = 7C222FB2927D828AF22F592134E8932480637C0D),
   igual que el usuario "username1" del script original.
   ===================================================================== */
USE [BDD_PoliMusic];
GO

/* ---------- 1. Usuario normal: Jhonathan Pulig ---------- */
IF NOT EXISTS (SELECT 1 FROM TBL_USER WHERE USERNAME = 'Jhonathan Pulig')
BEGIN
    INSERT INTO TBL_USER (USERNAME, PASSWORD, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE)
    VALUES ('Jhonathan Pulig',
            '7C222FB2927D828AF22F592134E8932480637C0D',   -- 12345678
            'jhonathan.pulig@epn.edu.ec',
            '2001-05-20',
            '~/userImages/jpulig.png',
            0);                                            -- 0 = USER
END
GO

/* ---------- 2. Playlists de ejemplo para ese usuario ---------- */
DECLARE @idUser INT;
SELECT @idUser = ID_USER FROM TBL_USER WHERE USERNAME = 'Jhonathan Pulig';

IF @idUser IS NOT NULL
BEGIN
    -- 2.1 Lista pública "Para programar"
    IF NOT EXISTS (SELECT 1 FROM TBL_PLAYLIST WHERE ID_USER = @idUser AND TITLE = 'Para programar')
    BEGIN
        INSERT INTO TBL_PLAYLIST (ID_USER, TITLE, CREATION_DATE, TYPE, PHOTO)
        VALUES (@idUser, 'Para programar', GETDATE(), 0, '~/playlistImages/playlist1.png');

        INSERT INTO TBL_PLAYLIST_SONG (ID_PLAYLIST, ID_SONG)
        SELECT SCOPE_IDENTITY(), ID_SONG FROM TBL_SONG
        WHERE SONG_NAME IN ('Adventure', 'Energy', 'Scifi');
    END

    -- 2.2 Lista privada "Mis favoritas"
    IF NOT EXISTS (SELECT 1 FROM TBL_PLAYLIST WHERE ID_USER = @idUser AND TITLE = 'Mis favoritas')
    BEGIN
        INSERT INTO TBL_PLAYLIST (ID_USER, TITLE, CREATION_DATE, TYPE, PHOTO)
        VALUES (@idUser, 'Mis favoritas', GETDATE(), 1, '~/playlistImages/playlist3.png');

        INSERT INTO TBL_PLAYLIST_SONG (ID_PLAYLIST, ID_SONG)
        SELECT SCOPE_IDENTITY(), ID_SONG FROM TBL_SONG
        WHERE SONG_NAME IN ('Dreams', 'Tomorrow');
    END
END
GO

/* ---------- 3. Verificación ---------- */
SELECT U.ID_USER, U.USERNAME, U.EMAIL, U.USER_TYPE,
       C.VALUE AS TIPO_USUARIO
FROM TBL_USER U
LEFT JOIN TBL_CATALOG C ON C.COD_CATALOG_PARENT = '1'
      AND C.COD_CATALOG = CONVERT(varchar(8), U.USER_TYPE)
ORDER BY U.ID_USER;

SELECT PL.ID_PLAYLIST, PL.TITLE, PL.TYPE, U.USERNAME AS OWNER,
       (SELECT COUNT(*) FROM TBL_PLAYLIST_SONG PS WHERE PS.ID_PLAYLIST = PL.ID_PLAYLIST) AS CANCIONES
FROM TBL_PLAYLIST PL INNER JOIN TBL_USER U ON U.ID_USER = PL.ID_USER
ORDER BY PL.ID_PLAYLIST;
GO
