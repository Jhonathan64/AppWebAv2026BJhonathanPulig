using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.Services;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV3
{
    public partial class Song : System.Web.UI.Page
    {
        private string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadSongs();
            }

            // Handle the increment plays callback from client-side
            string eventTarget = Request["__EVENTTARGET"];
            if (!string.IsNullOrEmpty(eventTarget) && eventTarget.StartsWith("IncrementPlays"))
            {
                string songIdStr = eventTarget.Substring("IncrementPlays".Length).TrimStart('$');
                int songId;
                if (int.TryParse(songIdStr, out songId) && songId > 0)
                {
                    new BLL.PoliMusicV3.Song(strConnString).IncrementPlays(songId);
                }
            }
        }

        private void LoadSongs()
        {
            try
            {
                DataTable dtSongs = new BLL.PoliMusicV3.Song(strConnString).Read();

                // Bind the hidden GridView for compatibility
                GridViewSongs.DataSource = dtSongs;
                GridViewSongs.DataBind();

                if (dtSongs != null && dtSongs.Rows.Count > 0)
                {
                    BuildSongCards(dtSongs);
                    emptyState.Style["display"] = "none";
                }
                else
                {
                    emptyState.Style["display"] = "block";
                }
            }
            catch (Exception ex)
            {
                // Show empty state if database is not available
                emptyState.Style["display"] = "block";
                // In debug mode, show the error in the subtitle
#if DEBUG
                var litError = new Literal();
                litError.Text = "<div style='color:#ff6b6b;padding:20px;font-size:14px;'>Debug: " +
                    Server.HtmlEncode(ex.Message) + "</div>";
                songsContainer.Controls.Add(litError);
#endif
            }
        }

        private void BuildSongCards(DataTable dtSongs)
        {
            string songFolderUrl = ResolveUrl("~/songFiles/");
            StringBuilder html = new StringBuilder();

            foreach (DataRow row in dtSongs.Rows)
            {
                int idSong = row["ID_SONG"] != DBNull.Value ? Convert.ToInt32(row["ID_SONG"]) : 0;
                string songName = row["SONG_NAME"] != DBNull.Value ? row["SONG_NAME"].ToString() : "Desconocido";
                string songPath = row["SONG_PATH"] != DBNull.Value ? row["SONG_PATH"].ToString() : "";
                int plays = row["PLAYS"] != DBNull.Value ? Convert.ToInt32(row["PLAYS"]) : 0;

                // Build the full URL to the mp3 file
                // songPath may be just a filename (e.g., "bensound-dreams.mp3") or a relative path
                string fullSongUrl;
                if (string.IsNullOrEmpty(songPath))
                {
                    fullSongUrl = songFolderUrl + songName.Replace(" ", "%20") + ".mp3";
                }
                else if (songPath.StartsWith("http") || songPath.StartsWith("/"))
                {
                    fullSongUrl = songPath;
                }
                else if (songPath.StartsWith("~/"))
                {
                    fullSongUrl = ResolveUrl(songPath);
                }
                else
                {
                    // Assume it's a filename in the songFiles folder
                    fullSongUrl = songFolderUrl + songPath;
                }

                // Sanitize for HTML attributes
                string safeName = Server.HtmlEncode(songName);
                string safeUrl = fullSongUrl.Replace("'", "&#39;");

                html.Append("<div class=\"song-card\"");
                html.Append(" data-song-id=\"").Append(idSong).Append("\"");
                html.Append(" data-song-name=\"").Append(safeName).Append("\"");
                html.Append(" data-song-path=\"").Append(safeUrl).Append("\"");
                html.Append(" data-song-plays=\"").Append(plays).Append("\">");

                html.Append("<div class=\"song-id-badge\">#").Append(idSong).Append("</div>");
                html.Append("<div class=\"song-artwork\">");
                html.Append("<span class=\"music-note\">&#9835;</span>");
                html.Append("<div class=\"play-btn\"></div>");
                html.Append("</div>");

                html.Append("<div class=\"song-name\">").Append(safeName).Append("</div>");
                html.Append("<div class=\"song-plays\">").Append(plays).Append(" reproducciones</div>");

                html.Append("</div>");
            }

            // Inject the HTML cards into the container
            var lit = new Literal();
            lit.Text = html.ToString();
            songsContainer.Controls.Add(lit);
        }

        [WebMethod]
        public static void IncrementPlay(int songId)
        {
            if (songId <= 0)
            {
                return;
            }

            string connectionString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;
            new BLL.PoliMusicV3.Song(connectionString).IncrementPlays(songId);
        }

    }
}
