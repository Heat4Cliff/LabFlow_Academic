"""Generate Android launcher resources from the supplied LabFlow master artwork.

Requires Pillow. Run from the repository root: python tools/generate_android_icons.py
"""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / "assets/branding/labflow_app_icon_1024.png"
RES = ROOT / "android/app/src/main/res"
SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}


def main() -> None:
    artwork = Image.open(MASTER).convert("RGBA")
    for density, size in SIZES.items():
        target = RES / f"mipmap-{density}" / "ic_launcher.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        artwork.resize((size, size), Image.Resampling.LANCZOS).save(target)

    # Extract only the supplied lime flask strokes for Android's adaptive mask.
    # The original composition remains unchanged in legacy launcher resources.
    flask = Image.new("RGBA", artwork.size)
    source = artwork.load()
    output = flask.load()
    assert source is not None and output is not None
    for y in range(min(artwork.height, 740)):
        for x in range(artwork.width):
            red, green, blue, source_alpha = source[x, y]
            strength = green - max(red, blue)
            if strength > 3 and blue < 140 and green > 110:
                alpha = min(source_alpha, max(0, round(strength * 255 / 50)))
                output[x, y] = (red, green, blue, alpha)

    bounds = flask.getbbox()
    if bounds is None:
        raise RuntimeError("Master artwork does not contain the lime flask")
    flask = flask.crop(bounds)
    flask.thumbnail((260, 260), Image.Resampling.LANCZOS)
    foreground = Image.new("RGBA", (432, 432))
    foreground.alpha_composite(
        flask, ((432 - flask.width) // 2, (432 - flask.height) // 2)
    )
    target = RES / "drawable-nodpi" / "ic_launcher_foreground.png"
    target.parent.mkdir(parents=True, exist_ok=True)
    foreground.save(target)


if __name__ == "__main__":
    main()
