"""Genera portadas originales (álbumes / artistas / avatar) para PoliMusic.
Paleta azul: se crean imágenes con degradado + ondas + iniciales.
"""
import os
from PIL import Image, ImageDraw, ImageFont

BASE = "/workspace/PoliMusic/site"
FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_REG = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

# paletas (inicio, fin, acento)
PALETTES = [
    ((11, 30, 63), (37, 99, 235), (125, 211, 252)),   # azul profundo
    ((8, 47, 73), (14, 165, 233), (165, 243, 252)),   # cian
    ((23, 25, 74), (79, 70, 229), (196, 181, 253)),   # índigo
    ((6, 41, 56), (2, 132, 199), (103, 232, 249)),    # océano
    ((15, 23, 42), (59, 130, 246), (147, 197, 253)),  # acero
]


def gradient(size, c0, c1, angle=0):
    w, h = size
    img = Image.new("RGB", size)
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(h - 1, 1)
        r = int(c0[0] + (c1[0] - c0[0]) * t)
        g = int(c0[1] + (c1[1] - c0[1]) * t)
        b = int(c0[2] + (c1[2] - c0[2]) * t)
        d.line([(0, y), (w, y)], fill=(r, g, b))
    return img


def waves(draw, size, color, seed=0, alpha=70):
    """Ondas horizontales tipo ecualizador."""
    w, h = size
    import math
    for k in range(4):
        amp = 14 + k * 9
        ybase = int(h * (0.62 + k * 0.09))
        pts = []
        for x in range(0, w + 6, 6):
            y = ybase + amp * math.sin((x / w) * (3 + k) * math.pi + seed + k)
            pts.append((x, y))
        draw.line(pts, fill=color, width=3)
    return draw


def font(path, size):
    return ImageFont.truetype(path, size)


def cover(path, initials, title, subtitle, idx, size=(640, 640)):
    p = PALETTES[idx % len(PALETTES)]
    img = gradient(size, p[0], p[1])
    d = ImageDraw.Draw(img, "RGBA")
    # círculo suave de acento
    d.ellipse([size[0] * 0.10, -size[1] * 0.22, size[0] * 0.95, size[1] * 0.55],
              fill=(p[2][0], p[2][1], p[2][2], 26))
    waves(d, size, (p[2][0], p[2][1], p[2][2], 120), seed=idx)
    f_init = font(FONT_BOLD, int(size[0] * 0.30))
    f_title = font(FONT_BOLD, int(size[0] * 0.075))
    f_sub = font(FONT_REG, int(size[0] * 0.045))
    # iniciales
    bbox = d.textbbox((0, 0), initials, font=f_init)
    d.text(((size[0] - (bbox[2] - bbox[0])) / 2, size[1] * 0.14), initials,
           font=f_init, fill=(255, 255, 255, 235))
    bbox = d.textbbox((0, 0), title, font=f_title)
    d.text(((size[0] - (bbox[2] - bbox[0])) / 2, size[1] * 0.52), title,
           font=f_title, fill=(255, 255, 255, 240))
    bbox = d.textbbox((0, 0), subtitle, font=f_sub)
    d.text(((size[0] - (bbox[2] - bbox[0])) / 2, size[1] * 0.62), subtitle,
           font=f_sub, fill=(255, 255, 255, 180))
    img.save(path)
    print("OK", path)


def avatar(path, initials, idx, size=(640, 640), square=True):
    p = PALETTES[idx % len(PALETTES)]
    img = gradient(size, p[0], p[1])
    d = ImageDraw.Draw(img, "RGBA")
    d.ellipse([size[0] * 0.18, size[1] * 0.12, size[0] * 0.82, size[1] * 0.76],
              fill=(p[2][0], p[2][1], p[2][2], 40))
    f_init = font(FONT_BOLD, int(size[0] * 0.26))
    bbox = d.textbbox((0, 0), initials, font=f_init)
    d.text(((size[0] - (bbox[2] - bbox[0])) / 2, size[1] * 0.30), initials,
           font=f_init, fill=(255, 255, 255, 235))
    img.save(path)
    print("OK", path)


albums = [
    ("album1.png", "RA", "ROCK ALBUM", "1976"),
    ("album2.png", "RM", "RELAX MUSIC", "2000"),
    ("album3.png", "RE", "RETRO ALBUM", "1980"),
    ("album4.png", "CA", "CLASSIC ALBUM", "1950"),
    ("album5.png", "CO", "COUNTRY ALBUM", "1990"),
]
artists = [
    ("artist1.jpg", "Juan", "Gabriel"),
    ("artist2.jpg", "Ana", "Gabriel"),
    ("artist3.jpg", "Mariah", "Carey"),
    ("artist4.jpg", "Elvis", "Presley"),
    ("artist5.png", "Edward", "Sheeran"),
]

for i, (fn, ini, t, s) in enumerate(albums):
    cover(os.path.join(BASE, "albumImages", fn), ini, t, s, i)

for i, (fn, n, l) in enumerate(artists):
    avatar(os.path.join(BASE, "ArtistImages", fn), (n[0] + l[0]).upper(), i)

# avatar de usuario genérico (username1 referenciado en el script original)
avatar(os.path.join(BASE, "userImages", "username1.png"), "U1", 2)
avatar(os.path.join(BASE, "userImages", "jpulig.png"), "JP", 0)

# favicon / logo simple
logo = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
dl = ImageDraw.Draw(logo)
dl.rounded_rectangle([0, 0, 255, 255], radius=64, fill=(37, 99, 235, 255))
dl.ellipse([70, 60, 186, 176], fill=(255, 255, 255, 255))
dl.ellipse([104, 94, 152, 142], fill=(37, 99, 235, 255))
dl.rounded_rectangle([120, 40, 136, 120], radius=8, fill=(255, 255, 255, 255))
logo.save(os.path.join(BASE, "assets", "img", "logo.png"))
print("OK logo")
