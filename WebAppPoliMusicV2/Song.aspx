<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebAppPoliMusicV2.Song" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>PoliMusic - Song Player</title>
    <style type="text/css">
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #0a1929 0%, #0d2847 40%, #102a56 100%);
            color: #e0e7ff;
            min-height: 100vh;
        }
        .header {
            background: linear-gradient(90deg, #0d47a1 0%, #1565c0 50%, #1976d2 100%);
            padding: 18px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 4px 20px rgba(0, 42, 92, 0.5);
            position: sticky;
            top: 0;
            z-index: 100;
        }
        .header-left {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .header-left .logo {
            font-size: 28px;
            color: #4fc3f7;
        }
        .header-left h1 {
            font-size: 22px;
            font-weight: 600;
            color: #e3f2fd;
            letter-spacing: 1px;
        }
        .header-right {
            display: flex;
            align-items: center;
            gap: 20px;
        }
        .welcome-text {
            font-size: 14px;
            color: #b3e5fc;
        }
        .welcome-text strong {
            color: #4fc3f7;
            font-size: 15px;
        }
        .logout-link {
            background: #0288d1;
            color: #ffffff;
            padding: 8px 20px;
            border-radius: 25px;
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.3s ease;
            display: inline-block;
        }
        .logout-link:hover {
            background: #03a9f4;
            box-shadow: 0 0 15px rgba(79, 195, 247, 0.6);
            transform: translateY(-1px);
        }
        .main-container {
            max-width: 1200px;
            margin: 30px auto;
            padding: 0 20px;
        }
        .page-title {
            font-size: 32px;
            font-weight: 700;
            color: #4fc3f7;
            margin-bottom: 8px;
            text-shadow: 0 2px 10px rgba(79, 195, 247, 0.3);
        }
        .page-subtitle {
            font-size: 15px;
            color: #82b1ff;
            margin-bottom: 30px;
        }
        .grid-container {
            background: rgba(13, 40, 71, 0.6);
            border: 1px solid rgba(79, 195, 247, 0.15);
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
            backdrop-filter: blur(10px);
        }
        .song-grid {
            width: 100%;
            border-collapse: collapse;
        }
        .song-grid th {
            background: linear-gradient(90deg, #0d47a1, #1565c0);
            color: #e3f2fd;
            padding: 14px 18px;
            text-align: left;
            font-size: 13px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border-bottom: 2px solid #0288d1;
        }
        .song-grid td {
            padding: 16px 18px;
            border-bottom: 1px solid rgba(79, 195, 247, 0.08);
            font-size: 14px;
            color: #c5cae9;
        }
        .song-grid tr:nth-child(even) td {
            background: rgba(10, 25, 41, 0.3);
        }
        .song-grid tr:hover td {
            background: rgba(2, 136, 209, 0.12);
            transition: background 0.2s ease;
        }
        .song-name {
            color: #4fc3f7;
            font-weight: 600;
            font-size: 15px;
        }
        .song-plays {
            color: #82b1ff;
            font-size: 13px;
        }
        .song-plays .play-count {
            font-size: 18px;
            font-weight: 700;
            color: #29b6f6;
        }
        .audio-player {
            width: 300px;
            height: 36px;
            border-radius: 20px;
        }
        .audio-player::-webkit-media-controls-panel {
            background: linear-gradient(90deg, #e3f2fd, #b3e5fc);
            border-radius: 20px;
        }
        /* Music-library layout */
        body {
            background: #070d18;
            color: #dce8f7;
        }
        .sidebar {
            position: fixed;
            left: 0;
            top: 0;
            bottom: 0;
            width: 205px;
            padding: 22px 14px;
            background: #0a1424;
            border-right: 1px solid #17263b;
            z-index: 20;
        }
        .sidebar-brand {
            color: #55b9ff;
            font-size: 19px;
            font-weight: 700;
            margin: 0 12px 30px;
        }
        .sidebar-link {
            display: block;
            color: #91a6c0;
            padding: 11px 13px;
            margin: 4px 0;
            border-radius: 7px;
            text-decoration: none;
            font-size: 13px;
        }
        .sidebar-link:hover, .sidebar-link.active {
            color: #ffffff;
            background: #123362;
        }
        .header {
            margin-left: 205px;
            height: 58px;
            padding: 0 30px;
            background: #080f1c;
            border-bottom: 1px solid #17263b;
            box-shadow: none;
        }
        .header-left h1 { font-size: 17px; }
        .search-box {
            width: 280px;
            margin-left: 35px;
            padding: 9px 16px;
            border-radius: 20px;
            background: #142238;
            color: #7189a7;
            font-size: 12px;
        }
        .main-container {
            margin: 0 0 0 205px;
            max-width: none;
            padding: 30px 42px 50px;
        }
        .hero {
            display: flex;
            align-items: center;
            min-height: 160px;
            padding: 25px 30px;
            border-radius: 12px;
            background: linear-gradient(120deg, #122d70, #0d1b32 65%);
            border: 1px solid #1b355c;
            margin-bottom: 30px;
        }
        .hero-avatar {
            width: 112px;
            height: 112px;
            margin-right: 24px;
            border-radius: 50%;
            background: linear-gradient(145deg, #e7edf3, #8994a1);
            border: 4px solid rgba(255,255,255,.75);
            text-align: center;
            line-height: 112px;
            color: #6b7480;
            font-size: 58px;
        }
        .hero small { color: #65bfff; text-transform: uppercase; letter-spacing: 1px; }
        .hero h2 { margin: 7px 0 12px; color: #ffffff; font-size: 26px; }
        .hero p { margin: 0; color: #91a6c0; font-size: 12px; }
        .hero-actions { margin-top: 16px; }
        .hero-button {
            display: inline-block;
            padding: 8px 15px;
            margin-right: 8px;
            border-radius: 18px;
            background: #1687df;
            color: #ffffff;
            text-decoration: none;
            font-size: 12px;
            font-weight: 600;
        }
        .hero-button.secondary { background: #173b67; }
        .page-title { font-size: 20px; margin-bottom: 5px; }
        .page-subtitle { margin-bottom: 17px; }
        .grid-container { background: transparent; border: 0; box-shadow: none; overflow: visible; }
        .song-grid { display: block; width: 100%; border-spacing: 0; }
        .song-grid thead,
        .song-grid tbody > tr:first-child { display: none !important; }
        .song-grid tbody { display: grid; grid-template-columns: repeat(auto-fill, minmax(210px, 1fr)); gap: 16px; }
        .song-grid tr { display: block; height: auto; min-height: 0; padding: 15px; border: 1px solid #1b355c; border-radius: 10px; background: #0d1a2c; vertical-align: top; }
        .song-grid tr:hover { background: #122541; transform: translateY(-2px); transition: .2s; }
        .song-grid td { display: block; padding: 5px 0; border: 0; width: auto !important; }
        .song-grid td:first-child { color: #637d9e; font-size: 11px; }
        .song-grid .song-name { color: #ffffff; font-size: 16px; padding-bottom: 10px; }
        .album-art {
            height: 125px;
            margin-bottom: 10px;
            border-radius: 7px;
            background: linear-gradient(145deg, #274e9b, #0b255d);
            color: rgba(255,255,255,.92);
            font-size: 38px;
            font-weight: 700;
            line-height: 125px;
            text-align: center;
            box-shadow: inset 0 0 30px rgba(75,154,255,.28);
        }
        .song-title { color: #ffffff; font-size: 15px; font-weight: 600; }
        .song-grid .audio-player { width: 100%; height: 36px; margin-top: 8px; }
        .song-grid .song-plays { color: #6fbfff; font-size: 12px; }
        @media (max-width: 500px) {
            .sidebar { position: static; width: auto; height: auto; padding: 12px; }
            .sidebar-link { display: inline-block; }
            .header, .main-container { margin-left: 0; }
            .main-container { padding: 20px 15px 40px; }
            .hero { padding: 20px; }
            .hero-avatar { width: 75px; height: 75px; line-height: 75px; font-size: 38px; }
        }
        .empty-message {
            text-align: center;
            padding: 60px 20px;
            color: #82b1ff;
            font-size: 18px;
        }
        @media (max-width: 500px) {
            .header {
                flex-direction: column;
                gap: 12px;
                padding: 15px;
            }
            .header-right {
                flex-direction: column;
                gap: 10px;
            }
            .page-title {
                font-size: 24px;
            }
            .song-grid th,
            .song-grid td {
                padding: 10px 12px;
                font-size: 12px;
            }
            .audio-player {
                width: 220px;
            }
        }
    </style>
</head>
<body>
    <form id="formSong" runat="server">
        <aside class="sidebar">
            <div class="sidebar-brand">♫ PoliMusic</div>
            <a class="sidebar-link active" href="Song.aspx">⌂&nbsp; Inicio</a>
            <a class="sidebar-link" href="Song.aspx">⌕&nbsp; Buscar</a>
            <a class="sidebar-link" href="Song.aspx">♫&nbsp; Canciones</a>
            <a class="sidebar-link" href="Song.aspx">▣&nbsp; Álbumes</a>
            <a class="sidebar-link" href="Song.aspx">♬&nbsp; Artistas</a>
            <a class="sidebar-link" href="Song.aspx">☷&nbsp; Mis playlists</a>
        </aside>
        <div class="header">
            <div class="header-left">
                <span class="logo">&#9835;</span>
                <h1>PoliMusic</h1>
            </div>
            <div class="search-box">⌕&nbsp; Buscar canciones, álbumes, artistas...</div>
            <div class="header-right">
                <asp:Label ID="lblWelcome" runat="server" CssClass="welcome-text"></asp:Label>
                <asp:HyperLink ID="lnkLogout" runat="server" NavigateUrl="~/Logout.aspx" CssClass="logout-link">Logout</asp:HyperLink>
            </div>
        </div>
        <div class="main-container">
            <section class="hero">
                <div class="hero-avatar">●</div>
                <div>
                    <small>Tu biblioteca</small>
                    <h2>Buenas tardes, <asp:Literal ID="litUserName" runat="server" /></h2>
                    <p>Escucha tus canciones favoritas y descubre nueva música.</p>
                    <div class="hero-actions">
                        <a class="hero-button" href="#songs">▶ Explorar canciones</a>
                        <a class="hero-button secondary" href="#songs">Mis playlists</a>
                    </div>
                </div>
            </section>
            <h2 id="songs" class="page-title">Más escuchadas</h2>
            <p class="page-subtitle">Browse and play your favorite tracks</p>
            <div class="grid-container">
                <asp:GridView ID="gvSongs" runat="server" AutoGenerateColumns="False"
                    CssClass="song-grid" GridLines="None" EmptyDataText="No songs available."
                    EmptyDataRowStyle-CssClass="empty-message">
                    <Columns>
                        <asp:TemplateField HeaderText="Song Name" ItemStyle-CssClass="song-name">
                            <ItemTemplate>
                                <div class="album-art">♫</div>
                                <div class="song-title"><%# Eval("SONG_NAME") %></div>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Player">
                            <ItemTemplate>
                                <audio class="audio-player" controls>
                                    <source src='<%# ResolveUrl(Convert.ToString(Eval("SONG_PATH"))) %>' type="audio/mpeg" />
                                    Your browser does not support the audio element.
                                </audio>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:BoundField DataField="PLAYS" HeaderText="Plays"
                            ItemStyle-CssClass="song-plays" ItemStyle-Width="100px" />
                    </Columns>
                </asp:GridView>
            </div>
        </div>
    </form>
</body>
</html>
