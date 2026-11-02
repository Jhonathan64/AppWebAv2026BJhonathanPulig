<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="WebAppPoliMusicV3._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <main class="home-page">
        <section class="home-hero" aria-labelledby="homeTitle">
            <div class="home-icon">&#9835;</div>
            <div>
                <p class="home-kicker">POLI MUSIC</p>
                <h1 id="homeTitle">Tu música, siempre contigo</h1>
                <p class="home-description">Explora nuestra colección de canciones y disfruta tus pistas favoritas desde un reproductor sencillo y elegante.</p>
                <a class="home-button" runat="server" href="~/Song">Explorar canciones <span>&rarr;</span></a>
            </div>
        </section>

        <section class="home-features" aria-label="Características">
            <article class="home-feature">
                <span class="feature-icon">&#127925;</span>
                <div><h2>Descubre música</h2><p>Encuentra canciones para cada momento.</p></div>
            </article>
            <article class="home-feature">
                <span class="feature-icon">&#9654;</span>
                <div><h2>Reproduce al instante</h2><p>Selecciona una canción y comienza a escuchar.</p></div>
            </article>
            <article class="home-feature">
                <span class="feature-icon">&#9733;</span>
                <div><h2>Tu espacio musical</h2><p>Una experiencia limpia, rápida y personalizada.</p></div>
            </article>
        </section>
    </main>

    <style>
        .home-page { color: #fff; }
        .home-hero { display: flex; align-items: center; gap: 28px; max-width: 850px; padding: 52px 0 58px; }
        .home-icon { width: 92px; height: 92px; flex: 0 0 92px; display: flex; align-items: center; justify-content: center; border-radius: 22px; background: linear-gradient(135deg, #00d4ff, #1264df); color: #fff; font-size: 46px; box-shadow: 0 12px 30px rgba(0, 120, 255, .28); }
        .home-kicker { color: #00d4ff; font-size: 12px; font-weight: 700; letter-spacing: 2px; margin: 0 0 10px; }
        .home-hero h1 { font-size: clamp(32px, 5vw, 52px); line-height: 1.08; margin: 0 0 14px; color: #fff; }
        .home-description { max-width: 650px; color: #a0aabf; font-size: 16px; line-height: 1.7; margin: 0 0 26px; }
        .home-button { display: inline-flex; gap: 14px; align-items: center; padding: 12px 20px; border-radius: 8px; background: #1264df; color: #fff; text-decoration: none; font-weight: 600; }
        .home-button:hover { background: #1978ff; color: #fff; text-decoration: none; }
        .home-button span { font-size: 20px; }
        .home-features { display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px; border-top: 1px solid rgba(0, 212, 255, .15); padding-top: 28px; }
        .home-feature { display: flex; gap: 14px; align-items: flex-start; padding: 20px; border-radius: 12px; background: #111d36; }
        .feature-icon { color: #00d4ff; font-size: 24px; }
        .home-feature h2 { font-size: 16px; margin: 0 0 7px; color: #fff; }
        .home-feature p { color: #a0aabf; font-size: 13px; line-height: 1.5; margin: 0; }
        @media screen and (max-width: 700px) { .home-hero { padding: 30px 0 38px; flex-direction: column; align-items: flex-start; } .home-features { grid-template-columns: 1fr; } }
    </style>

</asp:Content>
