<%@ Page Title="Canciones" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebAppPoliMusicV3.Song" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        /* ===== PAGE HEADER ===== */
        .song-page-header {
            display: flex;
            align-items: center;
            gap: 24px;
            margin-bottom: 32px;
        }

        .song-page-header .header-icon {
            width: 72px;
            height: 72px;
            border-radius: 12px;
            background: linear-gradient(135deg, #1ed760, #0d6efd);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 36px;
            flex-shrink: 0;
        }

        .song-page-header h1 {
            font-size: 36px;
            font-weight: 700;
            color: #ffffff;
            margin: 0;
        }

        .song-page-header .header-subtitle {
            font-size: 14px;
            color: #a0aabf;
            margin-top: 4px;
        }

        /* ===== SONG CARDS GRID ===== */
        .songs-container {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 24px;
            margin-bottom: 40px;
        }

        .song-card {
            background-color: #141b2d;
            border-radius: 12px;
            padding: 16px;
            transition: background-color 0.25s ease, transform 0.2s ease;
            cursor: pointer;
            position: relative;
            overflow: hidden;
        }

        .song-card:hover {
            background-color: #1a2338;
            transform: translateY(-4px);
        }

        .song-card .song-artwork {
            width: 100%;
            aspect-ratio: 1;
            border-radius: 8px;
            background: linear-gradient(135deg, #1a2338, #0d6efd);
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 12px;
            position: relative;
            overflow: hidden;
        }

        .song-card .song-artwork .music-note {
            font-size: 48px;
            opacity: 0.5;
        }

        .song-card .song-artwork .play-btn {
            position: absolute;
            bottom: 8px;
            right: 8px;
            width: 44px;
            height: 44px;
            border-radius: 50%;
            background-color: #1ed760;
            display: flex;
            align-items: center;
            justify-content: center;
            opacity: 0;
            transform: translateY(8px);
            transition: opacity 0.25s ease, transform 0.25s ease;
            box-shadow: 0 4px 12px rgba(0,0,0,0.4);
            border: none;
            cursor: pointer;
        }

        .song-card:hover .play-btn {
            opacity: 1;
            transform: translateY(0);
        }

        .song-card .play-btn::after {
            content: '';
            width: 0;
            height: 0;
            border-left: 14px solid #0a0e17;
            border-top: 9px solid transparent;
            border-bottom: 9px solid transparent;
            margin-left: 3px;
        }

        .song-card .song-name {
            font-size: 15px;
            font-weight: 600;
            color: #ffffff;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            margin-bottom: 4px;
        }

        .song-card .song-plays {
            font-size: 13px;
            color: #a0aabf;
        }

        .song-card .song-id-badge {
            position: absolute;
            top: 8px;
            right: 8px;
            background-color: rgba(0, 212, 255, 0.15);
            color: #00d4ff;
            font-size: 11px;
            font-weight: 600;
            padding: 2px 8px;
            border-radius: 4px;
        }

        /* ===== GRIDVIEW (hidden, used as data source) ===== */
        .gridview-wrapper {
            display: none;
        }

        /* ===== EMPTY STATE ===== */
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #a0aabf;
        }

        .empty-state .empty-icon {
            font-size: 64px;
            margin-bottom: 16px;
            opacity: 0.3;
        }

        .empty-state h3 {
            color: #ffffff;
            font-size: 20px;
            margin-bottom: 8px;
        }

        /* ===== TOP PLAYER PANEL ===== */
        .player-bar {
            position: relative;
            width: 100%;
            min-height: var(--player-height, 90px);
            background: linear-gradient(135deg, #111d36, #102d62);
            border: 1px solid rgba(0, 212, 255, 0.25);
            border-radius: 14px;
            display: flex;
            align-items: center;
            padding: 0 24px;
            margin-bottom: 28px;
            gap: 24px;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.25);
        }

        .player-bar .now-playing {
            flex: 0 0 25%;
            display: flex;
            align-items: center;
            gap: 12px;
            overflow: hidden;
        }

        .player-bar .now-playing .np-artwork {
            width: 56px;
            height: 56px;
            border-radius: 8px;
            background: linear-gradient(135deg, #1a2338, #0d6efd);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            flex-shrink: 0;
        }

        .player-bar .now-playing .np-info {
            overflow: hidden;
        }

        .player-bar .now-playing .np-title {
            font-size: 14px;
            font-weight: 600;
            color: #ffffff;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .player-bar .now-playing .np-subtitle {
            font-size: 12px;
            color: #a0aabf;
        }

        .player-bar .player-controls {
            flex: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 8px;
            max-width: 600px;
        }

        .player-bar .player-controls audio {
            width: 100%;
            max-width: 500px;
            filter: invert(0.85) hue-rotate(120deg);
        }

        .player-bar .player-controls audio::-webkit-media-controls-panel {
            background-color: #1a2338;
        }

        .player-bar .player-right {
            flex: 0 0 25%;
            display: flex;
            justify-content: flex-end;
            align-items: center;
            gap: 16px;
        }

        .player-bar .player-right .plays-count {
            font-size: 13px;
            color: #a0aabf;
        }

        .player-bar .player-right .plays-count strong {
            color: #1ed760;
        }

        /* ===== RESPONSIVE PLAYER ===== */
        @media screen and (max-width: 768px) {
            .player-bar {
                padding: 0 12px;
                gap: 12px;
            }
            .player-bar .now-playing {
                flex: 0 0 35%;
            }
            .player-bar .player-controls {
                flex: 1;
            }
            .player-bar .player-right {
                display: none;
            }
            .songs-container {
                grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
                gap: 12px;
            }
            .song-page-header h1 {
                font-size: 24px;
            }
            .song-page-header .header-icon {
                width: 48px;
                height: 48px;
                font-size: 24px;
            }
        }
    </style>

    <!-- ===== TOP PLAYER PANEL ===== -->
    <div class="player-bar">
        <div class="now-playing">
            <div class="np-artwork" id="npArtwork">&#9835;</div>
            <div class="np-info">
                <div class="np-title" id="npTitle">Selecciona una canci&oacute;n</div>
                <div class="np-subtitle" id="npSubtitle">Poli Music Player</div>
            </div>
        </div>
        <div class="player-controls">
            <audio id="audioPlayer" controls preload="metadata">
                <source id="audioSource" src="" type="audio/mpeg" />
                Tu navegador no soporta el elemento de audio HTML5.
            </audio>
        </div>
        <div class="player-right">
            <div class="plays-count" id="playsCount">Reproducciones: <strong id="playsCountValue">--</strong></div>
        </div>
    </div>

    <!-- ===== PAGE HEADER ===== -->
    <div class="song-page-header">
        <div class="header-icon">&#127925;</div>
        <div>
            <h1>Canciones</h1>
            <div class="header-subtitle">Reproductor de m&uacute;sica - Poli Music V3</div>
        </div>
    </div>

    <!-- ===== HIDDEN GRIDVIEW (data source for the card UI) ===== -->
    <div class="gridview-wrapper">
        <asp:GridView ID="GridViewSongs" runat="server" AutoGenerateColumns="true" Visible="false"></asp:GridView>
    </div>

    <!-- ===== SONG CARDS CONTAINER (populated from code-behind) ===== -->
    <div class="songs-container" id="songsContainer" runat="server">
        <!-- Cards will be injected here from Song.aspx.cs -->
    </div>

    <!-- ===== EMPTY STATE (shown when no songs) ===== -->
    <div class="empty-state" id="emptyState" runat="server" style="display:none;">
        <div class="empty-icon">&#127925;</div>
        <h3>No hay canciones disponibles</h3>
        <p>A&uacute;n no se han registrado canciones en la base de datos.</p>
    </div>

    <!-- ===== HIDDEN FIELD for currently playing song ID ===== -->
    <asp:HiddenField ID="hdnCurrentSongId" runat="server" Value="0" />

    <script type="text/javascript">
        // ===== Audio player integration =====
        var audioPlayer = document.getElementById('audioPlayer');
        var audioSource = document.getElementById('audioSource');
        var npTitle = document.getElementById('npTitle');
        var npSubtitle = document.getElementById('npSubtitle');
        var playsCountValue = document.getElementById('playsCountValue');

        function playSong(songId, songName, songPath, plays) {
            // Update the audio source
            audioSource.src = songPath;
            audioPlayer.load();
            var playRequest = audioPlayer.play();
            if (playRequest && playRequest.catch) {
                playRequest.catch(function () {
                    npSubtitle.textContent = 'Pulsa reproducir para iniciar el audio';
                });
            }

            // Update now-playing info
            npTitle.textContent = songName;
            npSubtitle.textContent = 'Reproduciendo ahora...';
            playsCountValue.textContent = plays;

            // Send the count without navigating, so the audio is not interrupted.
            fetch(window.location.pathname + '/IncrementPlay', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({ songId: parseInt(songId, 10) })
            }).catch(function () { });
        }

        // When audio ends
        audioPlayer.addEventListener('ended', function () {
            npSubtitle.textContent = 'Reproducci\u00f3n finalizada';
        });

        // ===== Song card click handlers =====
        document.addEventListener('DOMContentLoaded', function () {
            var cards = document.querySelectorAll('.song-card');
            cards.forEach(function (card) {
                card.addEventListener('click', function () {
                    var songId = this.getAttribute('data-song-id');
                    var songName = this.getAttribute('data-song-name');
                    var songPath = this.getAttribute('data-song-path');
                    var plays = this.getAttribute('data-song-plays');
                    playSong(songId, songName, songPath, plays);
                });
            });
        });
    </script>

</asp:Content>
