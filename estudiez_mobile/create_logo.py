import os
import subprocess
import sys

def install_and_import(package):
    try:
        __import__(package)
    except ImportError:
        print(f"Installing {package}...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", package])

# Ensure Pillow is installed
install_and_import('PIL')

from PIL import Image, ImageDraw

def create_gradient_lightning_icon():
    width, height = 512, 512
    # Dark grey background
    image = Image.new("RGBA", (width, height), (43, 43, 43, 255))
    draw = ImageDraw.Draw(image)

    # Vertices of the stylized double-stepped lightning bolt
    # Centered in the 512x512 square
    lightning_points = [
        (300, 50),
        (160, 270),
        (250, 270),
        (200, 462),
        (350, 242),
        (262, 242)
    ]

    # Create a gradient mask
    mask = Image.new("L", (width, height), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.polygon(lightning_points, fill=255)

    # Create the gradient image (Purple to Blue)
    gradient = Image.new("RGBA", (width, height))
    for y in range(height):
        # Interpolate from purple (138, 43, 226) to blue (30, 144, 255)
        ratio = y / height
        r = int(138 * (1 - ratio) + 30 * ratio)
        g = int(43 * (1 - ratio) + 144 * ratio)
        b = int(226 * (1 - ratio) + 255 * ratio)
        for x in range(width):
            gradient.putpixel((x, y), (r, g, b, 255))

    # Composite the gradient onto the dark grey background using the lightning mask
    image.paste(gradient, (0, 0), mask)

    # Ensure output directory exists
    output_dir = os.path.join("assets", "icon")
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    output_path = os.path.join(output_dir, "app_icon.png")
    image.save(output_path, "PNG")
    print(f"Success! App launcher icon created at: {os.path.abspath(output_path)}")

if __name__ == "__main__":
    create_gradient_lightning_icon()
