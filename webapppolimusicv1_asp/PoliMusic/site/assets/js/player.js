/* =====================================================================
   PoliMusic - reproductor
   Maneja la cola de reproducción, play/pausa, anterior/siguiente,
   barra de progreso y volumen. Funciona con cualquier lista de la
   página marcada con data-queue-item (tarjetas o filas).
   ===================================================================== */
(function () {
    "use strict";

    var audio = document.getElementById("audio");
    if (!audio) { return; }

    var root = (document.body && document.body.dataset.root) || "";

    var el = {
        play: document.getElementById("btnPlay"),
        prev: document.getElementById("btnPrev"),
        next: document.getElementById("btnNext"),
        seek: document.getElementById("seek"),
        vol: document.getElementById("vol"),
        title: document.getElementById("playerTitle"),
        artist: document.getElementById("playerArtist"),
        cover: document.getElementById("playerCover"),
        timeCur: document.getElementById("timeCur"),
        timeDur: document.getElementById("timeDur"),
        player: document.getElementById("player")
    };

    var queue = [];        // cola actual
    var index = -1;        // pista en reproducción
    var seeking = false;   // el usuario está arrastrando la barra

    /* ---------------- utilidades ---------------- */
    function fmt(sec) {
        if (!isFinite(sec) || sec < 0) { sec = 0; }
        var m = Math.floor(sec / 60);
        var s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" + s : s);
    }

    function setFill(input) {
        var min = parseFloat(input.min || 0);
        var max = parseFloat(input.max || 100);
        var val = parseFloat(input.value || 0);
        var pct = max > min ? ((val - min) / (max - min)) * 100 : 0;
        input.style.setProperty("--fill", pct + "%");
    }

    /* ---------------- cola ---------------- */
    function collectQueue(node) {
        var scope = node.closest("[data-queue]") || document;
        var items = scope.querySelectorAll("[data-queue-item]");
        var list = [];
        Array.prototype.forEach.call(items, function (n) {
            if (!n.dataset.src) { return; }
            list.push({
                node: n,
                id: n.dataset.id,
                title: n.dataset.title || "Sin título",
                artist: n.dataset.artist || "Artista desconocido",
                src: n.dataset.src,
                cover: n.dataset.cover || ""
            });
        });
        return list;
    }

    function paintState() {
        Array.prototype.forEach.call(document.querySelectorAll(".is-playing"), function (n) {
            n.classList.remove("is-playing");
        });
        if (index >= 0 && queue[index] && queue[index].node) {
            queue[index].node.classList.add("is-playing");
        }
    }

    function paintNow() {
        var t = queue[index];
        if (!t) { return; }
        el.title.textContent = t.title;
        el.artist.textContent = t.artist;
        if (t.cover) { el.cover.src = t.cover; }
        el.player.dataset.empty = "false";
        document.title = t.title + " · PoliMusic";
    }

    /* ---------------- registro de reproducción ---------------- */
    function registerPlay(id) {
        if (!id) { return; }
        var body = "id=" + encodeURIComponent(id);
        try {
            /* sendBeacon con cuerpo urlencoded: el ASP clásico lo lee en Request.Form */
            if (navigator.sendBeacon) {
                var blob = new Blob([body], { type: "application/x-www-form-urlencoded" });
                navigator.sendBeacon(root + "/api/register_play.asp", blob);
                return;
            }
            fetch(root + "/api/register_play.asp", {
                method: "POST",
                credentials: "same-origin",
                headers: { "Content-Type": "application/x-www-form-urlencoded" },
                body: body
            });
        } catch (e) { /* no bloquear la reproducción */ }
    }

    /* ---------------- reproducción ---------------- */
    function load(i, autoplay) {
        if (i < 0 || i >= queue.length) { return; }
        index = i;
        var t = queue[i];
        audio.src = t.src;
        audio.currentTime = 0;
        el.seek.value = 0;
        setFill(el.seek);
        el.timeCur.textContent = "0:00";
        el.timeDur.textContent = "0:00";
        paintNow();
        paintState();
        if (autoplay !== false) {
            var p = audio.play();
            if (p && typeof p.catch === "function") {
                p.catch(function () { paintButton(false); });
            }
        }
    }

    function paintButton(playing) {
        var ico = el.play.querySelector(".ico");
        if (playing) {
            ico.classList.remove("ico--play");
            ico.classList.add("ico--pause");
            el.play.setAttribute("aria-label", "Pausar");
        } else {
            ico.classList.remove("ico--pause");
            ico.classList.add("ico--play");
            el.play.setAttribute("aria-label", "Reproducir");
        }
    }

    function toggle() {
        if (index < 0 && queue.length === 0) {
            var first = document.querySelector("[data-queue-item][data-src]");
            if (first) { queue = collectQueue(first); load(0); }
            return;
        }
        if (index < 0) { load(0); return; }
        if (audio.paused) {
            var p = audio.play();
            if (p && typeof p.catch === "function") { p.catch(function () {}); }
        } else {
            audio.pause();
        }
    }

    function step(delta) {
        if (queue.length === 0) { return; }
        var next = index + delta;
        if (next < 0) { next = queue.length - 1; }
        if (next >= queue.length) { next = 0; }
        load(next);
    }

    /* ---------------- eventos ---------------- */
    function closest(node, selector) {
        while (node && node.nodeType !== 1) { node = node.parentNode; }
        while (node && !matches(node, selector)) { node = node.parentNode; }
        return node;
    }
    function matches(node, selector) {
        if (node.matches) { return node.matches(selector); }
        var all = document.querySelectorAll(selector);
        for (var i = 0; i < all.length; i++) { if (all[i] === node) { return true; } }
        return false;
    }

    document.addEventListener("click", function (ev) {
        var btn = closest(ev.target, "[data-play]");
        if (!btn) { return; }
        ev.preventDefault();
        var item = closest(btn, "[data-queue-item]");
        if (!item) { return; }

        var list = collectQueue(item);
        var pos = -1;
        for (var k = 0; k < list.length; k++) { if (list[k].node === item) { pos = k; break; } }
        queue = list;

        if (pos === index && item.classList.contains("is-playing")) {
            toggle();
            return;
        }
        load(pos);
        registerPlay(item.dataset.id);
    });

    el.play.addEventListener("click", toggle);
    el.prev.addEventListener("click", function () { step(-1); });
    el.next.addEventListener("click", function () { step(1); });

    audio.addEventListener("play", function () { paintButton(true); });
    audio.addEventListener("pause", function () { paintButton(false); });
    audio.addEventListener("ended", function () { step(1); });

    audio.addEventListener("loadedmetadata", function () {
        el.timeDur.textContent = fmt(audio.duration);
    });

    audio.addEventListener("timeupdate", function () {
        if (seeking || !audio.duration) { return; }
        el.seek.value = Math.round((audio.currentTime / audio.duration) * 1000);
        setFill(el.seek);
        el.timeCur.textContent = fmt(audio.currentTime);
    });

    el.seek.addEventListener("pointerdown", function () { seeking = true; });
    el.seek.addEventListener("input", function () {
        setFill(el.seek);
        if (audio.duration) {
            el.timeCur.textContent = fmt((el.seek.value / 1000) * audio.duration);
        }
    });
    el.seek.addEventListener("change", function () {
        if (audio.duration) {
            audio.currentTime = (el.seek.value / 1000) * audio.duration;
        }
        seeking = false;
    });

    /* volumen (se recuerda en el navegador) */
    var savedVol = localStorage.getItem("pm_vol");
    el.vol.value = savedVol !== null ? savedVol : 80;
    audio.volume = el.vol.value / 100;
    setFill(el.vol);

    el.vol.addEventListener("input", function () {
        audio.volume = el.vol.value / 100;
        setFill(el.vol);
        try { localStorage.setItem("pm_vol", el.vol.value); } catch (e) {}
    });

    /* teclado: barra espaciadora play/pausa (salvo en campos de texto) */
    document.addEventListener("keydown", function (ev) {
        if (ev.code !== "Space" && ev.key !== " ") { return; }
        var tag = (ev.target.tagName || "").toLowerCase();
        if (tag === "input" || tag === "textarea" || tag === "select") { return; }
        ev.preventDefault();
        toggle();
    });

    setFill(el.seek);
})();
