"""Gera os assets da Play Store em /workspace/habitly-store (ou argv[1]).

Uso (a partir de mobile/):
  STORE_SHOTS=/workspace/habitly-store/raw flutter test test/store_screenshots_test.dart
  python3 tool/gen_store_assets.py /workspace/habitly-store
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = sys.argv[1] if len(sys.argv) > 1 else '/workspace/habitly-store'
HERE = os.path.dirname(os.path.abspath(__file__))
FONT_DIR = os.path.join(HERE, '..', 'test', 'fonts')
GREEN = (27, 122, 75)
DARK = (14, 84, 50)
MINT = (220, 242, 228)
WHITE = (255, 255, 255)


def font(weight, size):
    return ImageFont.truetype(os.path.join(FONT_DIR, f'Roboto-{weight}.ttf'), size)


def raw_mark(W):
    """Check + folha (mesmo desenho de tool/gen_icon.py), máscara L."""
    img = Image.new('L', (W, W), 0)
    d = ImageDraw.Draw(img)
    P = lambda x, y: (x * W, y * W)
    w = int(W * 0.12)
    a, b, c = (0.10, 0.58), (0.36, 0.82), (0.66, 0.42)
    d.line([P(*a), P(*b), P(*c)], fill=255, width=w, joint='curve')
    for p in (a, c):
        x, y = P(*p)
        r = w / 2
        d.ellipse([x - r, y - r, x + r, y + r], fill=255)
    L = 0.34
    ang = math.radians(-40)
    ux, uy = math.cos(ang), math.sin(ang)
    base = (c[0] + ux * 0.02, c[1] + uy * 0.02)
    pts = []
    N = 60
    for i in range(N + 1):
        t = i / N
        pts.append((t * L, math.sin(math.pi * t) * L * 0.30))
    for i in range(N, -1, -1):
        t = i / N
        pts.append((t * L, -math.sin(math.pi * t) * L * 0.30))
    poly = [P(base[0] + x * ux - y * uy, base[1] + x * uy + y * ux) for x, y in pts]
    d.polygon(poly, fill=255)
    d.line([P(base[0] + 0.05 * ux, base[1] + 0.05 * uy),
            P(base[0] + 0.27 * ux, base[1] + 0.27 * uy)], fill=0,
           width=max(2, int(W * 0.018)))
    return img.crop(img.getbbox())


def paste_mask(img, mask, color, box_size, center):
    k = box_size / max(mask.size)
    m = mask.resize((int(mask.size[0] * k), int(mask.size[1] * k)), Image.LANCZOS)
    layer = Image.new('RGBA', m.size, color + (255,))
    img.paste(layer, (int(center[0] - m.size[0] / 2), int(center[1] - m.size[1] / 2)), m)


def gradient(size, top, bottom):
    w, h = size
    g = Image.new('RGB', (1, h))
    for y in range(h):
        t = y / max(1, h - 1)
        g.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return g.resize((w, h))


def icon_main(S=512):
    """Ícone atual: check + folha branco no verde (igual ao launcher)."""
    k = 4
    img = Image.new('RGBA', (S * k, S * k), GREEN + (255,))
    paste_mask(img, raw_mark(2000), WHITE, S * k * 0.58, (S * k / 2, S * k / 2))
    return img.resize((S, S), Image.LANCZOS)


def icon_alt1(S=512):
    """Alternativa 1: anel de progresso do dia + check, gradiente verde."""
    k = 4
    W = S * k
    img = gradient((W, W), (40, 150, 95), DARK).convert('RGBA')
    d = ImageDraw.Draw(img)
    r = W * 0.34
    cx = cy = W / 2
    lw = int(W * 0.075)
    box = [cx - r, cy - r, cx + r, cy + r]
    d.arc(box, 0, 360, fill=(255, 255, 255, 70), width=lw)
    d.arc(box, -90, 200, fill=WHITE + (255,), width=lw)
    # ponta arredondada do arco
    for angle in (-90, 200):
        a = math.radians(angle)
        x = cx + (r - lw / 2) * math.cos(a)
        y = cy + (r - lw / 2) * math.sin(a)
        d.ellipse([x - lw / 2, y - lw / 2, x + lw / 2, y + lw / 2], fill=WHITE + (255,))
    # check
    pts = [(0.37, 0.52), (0.46, 0.61), (0.64, 0.42)]
    pts = [(x * W, y * W) for x, y in pts]
    cw = int(W * 0.06)
    d.line(pts, fill=WHITE + (255,), width=cw, joint='curve')
    for x, y in (pts[0], pts[-1]):
        d.ellipse([x - cw / 2, y - cw / 2, x + cw / 2, y + cw / 2], fill=WHITE + (255,))
    return img.resize((S, S), Image.LANCZOS)


def icon_alt2(S=512):
    """Alternativa 2: broto verde num 'quadradinho de calendário' claro."""
    k = 4
    W = S * k
    img = Image.new('RGBA', (W, W), MINT + (255,))
    d = ImageDraw.Draw(img)
    m = W * 0.20
    d.rounded_rectangle([m, m * 1.05, W - m, W - m * 0.95], radius=W * 0.09,
                        fill=WHITE + (255,), outline=GREEN + (255,), width=int(W * 0.035))
    # barra do topo do calendário
    d.rounded_rectangle([m, m * 1.05, W - m, m * 1.05 + W * 0.13], radius=W * 0.09,
                        fill=GREEN + (255,))
    d.rectangle([m, m * 1.05 + W * 0.07, W - m, m * 1.05 + W * 0.13], fill=GREEN + (255,))
    for x in (0.36, 0.64):
        d.rounded_rectangle([W * x - W * 0.025, m * 0.75, W * x + W * 0.025, m * 1.05 + W * 0.06],
                            radius=W * 0.02, fill=DARK + (255,))
    # broto: caule + duas folhas
    cx = W / 2
    base_y = W * 0.70
    top_y = W * 0.47
    d.line([(cx, base_y), (cx, top_y)], fill=GREEN + (255,), width=int(W * 0.035))

    def leaf(angle_deg, length):
        a = math.radians(angle_deg)
        ux, uy = math.cos(a), math.sin(a)
        pts = []
        N = 50
        for i in range(N + 1):
            t = i / N
            pts.append((t * length, math.sin(math.pi * t) * length * 0.32))
        for i in range(N, -1, -1):
            t = i / N
            pts.append((t * length, -math.sin(math.pi * t) * length * 0.32))
        poly = [(cx + x * ux - y * uy, top_y + W * 0.04 + x * uy + y * ux) for x, y in pts]
        d.polygon(poly, fill=GREEN + (255,))

    leaf(-35, W * 0.17)
    leaf(-145, W * 0.14)
    d.rounded_rectangle([cx - W * 0.11, base_y - W * 0.01, cx + W * 0.11, base_y + W * 0.035],
                        radius=W * 0.02, fill=DARK + (255,))
    return img.resize((S, S), Image.LANCZOS)


def soft_circle(img, box, alpha):
    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse(box, fill=(255, 255, 255, alpha))
    img.alpha_composite(layer)


def rounded(img, radius):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] - 1], radius, fill=255)
    out = img.convert('RGBA')
    out.putalpha(mask)
    return out


def shadowed(canvas, img, pos, radius, blur=28, offset=14):
    sh = Image.new('RGBA', (img.size[0] + blur * 4, img.size[1] + blur * 4), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle(
        [blur * 2, blur * 2, blur * 2 + img.size[0], blur * 2 + img.size[1]], radius, fill=(0, 0, 0, 110))
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    canvas.alpha_composite(sh, (pos[0] - blur * 2, pos[1] - blur * 2 + offset))
    canvas.alpha_composite(img, pos)


def wrap(draw, text, fnt, max_w):
    words, lines, cur = text.split(), [], ''
    for w in words:
        t = (cur + ' ' + w).strip()
        if draw.textlength(t, font=fnt) <= max_w:
            cur = t
        else:
            lines.append(cur)
            cur = w
    lines.append(cur)
    return lines


def feature_graphic(today_shot):
    W, H = 1024, 500
    img = gradient((W, H), (34, 140, 88), DARK).convert('RGBA')
    soft_circle(img, [640, -200, 1160, 320], 22)
    soft_circle(img, [-140, 360, 200, 700], 16)
    # ícone
    ic = rounded(icon_main(150), 34)
    shadowed(img, ic, (64, 86), 34, blur=14, offset=8)
    d = ImageDraw.Draw(img)
    d.text((64, 262), 'Habitly', font=font('Bold', 84), fill=WHITE)
    sub = font('Medium', 34)
    y = 370
    for line in ['Construa hábitos,', 'um dia de cada vez']:
        d.text((66, y), line, font=sub, fill=(232, 247, 238))
        y += 44
    # celular com a tela Hoje
    if today_shot is not None:
        ph_h = 470
        shot = today_shot.convert('RGB')
        ph_w = int(shot.size[0] * ph_h / shot.size[1])
        shot = shot.resize((ph_w, ph_h), Image.LANCZOS)
        bezel = 12
        phone = Image.new('RGBA', (ph_w + bezel * 2, ph_h + bezel * 2), (0, 0, 0, 0))
        ImageDraw.Draw(phone).rounded_rectangle([0, 0, phone.size[0] - 1, phone.size[1] - 1], 44,
                                                fill=(20, 28, 24, 255))
        phone.alpha_composite(rounded(shot, 34), (bezel, bezel))
        phone = phone.rotate(-8, resample=Image.BICUBIC, expand=True)
        shadowed(img, phone, (668, 18), 40, blur=18, offset=10)
    return img.convert('RGB')


CAPTIONS = {
    '01-hoje': 'Seus hábitos do dia, a um toque',
    '02-historico': 'Acompanhe tudo no calendário',
    '03-estatisticas': 'Estatísticas que mostram sua evolução',
    '04-conquistas': 'Sequências e conquistas para manter o ritmo',
    '05-nota': 'Não deu hoje? Anote o motivo e aprenda',
    '06-premium': 'Premium: hábitos ilimitados e sem anúncios',
}


def framed(shot, caption):
    W, H = 1080, 1920
    img = gradient((W, H), (34, 140, 88), DARK).convert('RGBA')
    soft_circle(img, [620, -260, 1340, 460], 20)
    d = ImageDraw.Draw(img)
    fnt = font('Bold', 70)
    lines = wrap(d, caption, fnt, W - 140)
    y = 110
    for line in lines:
        tw = d.textlength(line, font=fnt)
        d.text(((W - tw) / 2, y), line, font=fnt, fill=WHITE)
        y += 86
    top = max(y + 50, 330)
    sh_h = H - top - 70
    sh_w = int(shot.size[0] * sh_h / shot.size[1])
    s = shot.convert('RGB').resize((sh_w, sh_h), Image.LANCZOS)
    bezel = 16
    phone = Image.new('RGBA', (sh_w + bezel * 2, sh_h + bezel * 2), (0, 0, 0, 0))
    ImageDraw.Draw(phone).rounded_rectangle([0, 0, phone.size[0] - 1, phone.size[1] - 1], 60,
                                            fill=(20, 28, 24, 255))
    phone.alpha_composite(rounded(s, 46), (bezel, bezel))
    shadowed(img, phone, ((W - phone.size[0]) // 2, top), 60)
    return img.convert('RGB')


def main():
    os.makedirs(OUT, exist_ok=True)
    icon_main().save(os.path.join(OUT, 'icon-512.png'))
    icon_alt1().save(os.path.join(OUT, 'icon-alt-1.png'))
    icon_alt2().save(os.path.join(OUT, 'icon-alt-2.png'))
    raw_dir = os.path.join(OUT, 'raw')
    today = None
    if os.path.exists(os.path.join(raw_dir, '01-hoje.png')):
        today = Image.open(os.path.join(raw_dir, '01-hoje.png'))
    feature_graphic(today).save(os.path.join(OUT, 'feature-graphic-1024x500.png'))
    shots = os.path.join(OUT, 'screenshots')
    plain = os.path.join(OUT, 'screenshots-plain')
    os.makedirs(shots, exist_ok=True)
    os.makedirs(plain, exist_ok=True)
    for name, cap in CAPTIONS.items():
        p = os.path.join(raw_dir, name + '.png')
        if not os.path.exists(p):
            continue
        shot = Image.open(p).convert('RGB')
        if shot.size != (1080, 1920):
            shot = shot.resize((1080, 1920), Image.LANCZOS)
        shot.save(os.path.join(plain, name + '.png'))
        framed(shot, cap).save(os.path.join(shots, name + '.png'))


if __name__ == '__main__':
    main()
