from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
ASSET_ROOT = ROOT / "assets" / "expert-meeting-viewer" / "art" / "imagegen" / "extracted"
BODY_INPUT = ASSET_ROOT / "occupied-seats"
HEAD_INPUT = ASSET_ROOT / "occupied-seat-heads"
BODY_OUTPUT = ASSET_ROOT / "occupied-seats-silhouette"
HEAD_OUTPUT = ASSET_ROOT / "occupied-seat-heads-silhouette"


def get_dark_component_mask(image):
    width, height = image.size
    pixels = image.load()
    dark = [[False] * width for _ in range(height)]

    for y in range(height):
        for x in range(width):
            red, green, blue, alpha = pixels[x, y]
            if alpha <= 8:
                continue

            luminance = 0.299 * red + 0.587 * green + 0.114 * blue
            if luminance < 122 and max(red, green, blue) < 150:
                dark[y][x] = True

    seen = [[False] * width for _ in range(height)]
    components = []
    for y in range(height):
        for x in range(width):
            if not dark[y][x] or seen[y][x]:
                continue

            queue = deque([(x, y)])
            seen[y][x] = True
            points = []
            while queue:
                point_x, point_y = queue.popleft()
                points.append((point_x, point_y))
                for next_x in (point_x - 1, point_x, point_x + 1):
                    for next_y in (point_y - 1, point_y, point_y + 1):
                        if next_x == point_x and next_y == point_y:
                            continue
                        if 0 <= next_x < width and 0 <= next_y < height and dark[next_y][next_x] and not seen[next_y][next_x]:
                            seen[next_y][next_x] = True
                            queue.append((next_x, next_y))

            components.append(points)

    components.sort(key=len, reverse=True)
    mask = Image.new("L", image.size, 0)
    mask_pixels = mask.load()
    if components:
        for x, y in components[0]:
            mask_pixels[x, y] = 255

    return mask.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(3))


def write_body_silhouette(source, target):
    image = Image.open(source).convert("RGBA")
    mask = get_dark_component_mask(image)
    output = image.copy()
    output_pixels = output.load()
    mask_pixels = mask.load()
    width, height = output.size

    for y in range(height):
        for x in range(width):
            if mask_pixels[x, y] > 0:
                _, _, _, alpha = output_pixels[x, y]
                output_pixels[x, y] = (0, 0, 0, alpha)

    target.parent.mkdir(parents=True, exist_ok=True)
    output.save(target)


def write_head_silhouette(source, target):
    image = Image.open(source).convert("RGBA")
    output = Image.new("RGBA", image.size, (0, 0, 0, 0))
    source_pixels = image.load()
    output_pixels = output.load()
    width, height = output.size

    for y in range(height):
        for x in range(width):
            _, _, _, alpha = source_pixels[x, y]
            if alpha > 0:
                output_pixels[x, y] = (0, 0, 0, alpha)

    target.parent.mkdir(parents=True, exist_ok=True)
    output.save(target)


def main():
    for source in BODY_INPUT.glob("*.png"):
        write_body_silhouette(source, BODY_OUTPUT / source.name)

    for source in HEAD_INPUT.glob("*.png"):
        write_head_silhouette(source, HEAD_OUTPUT / source.name)

    print(f"wrote {len(list(BODY_OUTPUT.glob('*.png')))} body silhouettes")
    print(f"wrote {len(list(HEAD_OUTPUT.glob('*.png')))} head silhouettes")


if __name__ == "__main__":
    main()
