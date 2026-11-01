using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV2
{
    public partial class Song : System.Web.UI.Page
    {
        string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
        {
            Entities.User user = (Entities.User)Session[Util.Constants.USER];
            if (user == null)
            {
                Response.Redirect("Login.aspx");
                return;
            }
            lblWelcome.Text = "Welcome, <strong>" + user.UserName + "</strong>";
            litUserName.Text = Server.HtmlEncode(user.UserName);
            if (!Page.IsPostBack)
            {
                LoadSongs();
            }
        }

        private void LoadSongs()
        {
            BLL.Song songBLL = new BLL.Song(strConnString);
            DataTable dtSongs = songBLL.GetAll();
            gvSongs.DataSource = dtSongs;
            gvSongs.DataBind();
        }
    }

}
