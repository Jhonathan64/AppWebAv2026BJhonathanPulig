/* =====================================================================
   PoliMusic - interacción general de la interfaz
   Menú lateral en móvil, cierre de avisos, confirmaciones de borrado,
   respaldo de imágenes y resaltado de enlaces activos.
   ===================================================================== */
(function () {
    "use strict";

    /* Reserva el espacio real del reproductor, incluso al cambiar el zoom. */
    var player = document.getElementById("player");
    function updatePlayerSpace() {
        if (!player) { return; }
        var bottom = parseFloat(window.getComputedStyle(player).bottom) || 0;
        document.documentElement.style.setProperty("--player-space", (player.getBoundingClientRect().height + bottom) + "px");
    }
    updatePlayerSpace();
    window.addEventListener("resize", updatePlayerSpace);
    if (player && window.ResizeObserver) {
        new ResizeObserver(updatePlayerSpace).observe(player);
    }

    /* ---------- Menú lateral (móvil / tablet) ---------- */
    var sidebar = document.getElementById("sidebar");
    var btnMenu = document.getElementById("btnMenu");
    var scrim = document.getElementById("scrim");

    function openMenu(open) {
        if (!sidebar) { return; }
        sidebar.classList.toggle("is-open", !!open);
        if (scrim) { scrim.hidden = !open; }
    }
    if (btnMenu) {
        btnMenu.addEventListener("click", function () {
            openMenu(!sidebar.classList.contains("is-open"));
        });
    }
    if (scrim) { scrim.addEventListener("click", function () { openMenu(false); }); }
    document.addEventListener("keydown", function (ev) {
        if (ev.key === "Escape") { openMenu(false); }
    });

    /* ---------- Avisos (flash) ---------- */
    var flashes = document.querySelectorAll(".flash");
    Array.prototype.forEach.call(flashes, function (f) {
        var close = f.querySelector(".flash__close");
        if (close) {
            close.addEventListener("click", function () { f.parentNode.removeChild(f); });
        }
        setTimeout(function () { if (f.parentNode) { f.parentNode.removeChild(f); } }, 7000);
    });

    /* ---------- Confirmación antes de borrar ---------- */
    var confirms = document.querySelectorAll("[data-confirm]");
    Array.prototype.forEach.call(confirms, function (node) {
        node.addEventListener("click", function (ev) {
            if (!window.confirm(node.getAttribute("data-confirm"))) {
                ev.preventDefault();
                ev.stopPropagation();
            }
        });
        node.addEventListener("submit", function (ev) {
            if (!window.confirm(node.getAttribute("data-confirm"))) { ev.preventDefault(); }
        });
    });

    /* ---------- Reproducir toda una lista ---------- */
    var playAll = document.querySelectorAll("[data-play-all]");
    Array.prototype.forEach.call(playAll, function (btn) {
        btn.addEventListener("click", function () {
            var scope = btn.closest("[data-queue]") || btn.parentNode.closest("[data-queue]") || document;
            var first = scope.querySelector("[data-queue-item] [data-play], [data-queue-item][data-src] [data-play]");
            if (!first) { first = scope.querySelector("[data-play]"); }
            if (first) { first.click(); }
        });
    });

    /* ---------- Carátulas que no cargan ---------- */
    var imgs = document.querySelectorAll("img[data-fallback]");
    Array.prototype.forEach.call(imgs, function (img) {
        img.addEventListener("error", function () {
            img.src = img.getAttribute("data-fallback");
        });
    });

    /* ---------- Evitar doble envío en formularios ---------- */
    var forms = document.querySelectorAll("form[data-once]");
    Array.prototype.forEach.call(forms, function (form) {
        form.addEventListener("submit", function () {
            var btn = form.querySelector("button[type=submit]");
            if (btn && !btn.disabled) {
                btn.disabled = true;
                btn.textContent = "Procesando...";
            }
        });
    });
})();
