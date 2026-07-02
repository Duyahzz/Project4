from PIL import Image, ImageDraw, ImageFont
import os

def get_font(size, bold=False):
    try:
        font_name = "arialbd.ttf" if bold else "arial.ttf"
        return ImageFont.truetype(font_name, size)
    except Exception:
        return ImageFont.load_default()

def draw_stack_diagram(output_path):
    # Canvas Size
    width = 800
    height = 600
    img = Image.new('RGB', (width, height), color=(255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    # Draw light grey grid background
    grid_spacing = 20
    for x in range(0, width, grid_spacing):
        draw.line([x, 0, x, height], fill=(240, 240, 240), width=1)
    for y in range(0, height, grid_spacing):
        draw.line([0, y, width, y], fill=(240, 240, 240), width=1)
        
    # Helpers for rounded boxes
    def draw_rounded_box(draw, box, radius, fill_color, outline_color, width=1):
        x0, y0, x1, y1 = box
        draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=fill_color, outline=outline_color, width=width)

    # ─── ROW 1: PRESENTATION (Thymeleaf & Flutter) ───
    # Icon: Client device (Monitor & Phone)
    # Monitor base
    draw.polygon([(60, 110), (100, 110), (90, 95), (70, 95)], fill=(120, 144, 156))
    draw.rectangle([75, 95, 85, 105], fill=(144, 164, 174))
    # Monitor screen
    draw_rounded_box(draw, [40, 50, 120, 95], 5, (224, 242, 241), (55, 71, 79), 2)
    # Screen inner content symbol </>
    draw.text((68, 65), "</>", fill=(38, 50, 56), font=get_font(12, True))
    # Phone
    draw_rounded_box(draw, [110, 40, 140, 95], 4, (230, 242, 255), (0, 112, 192), 2)
    draw.rectangle([112, 45, 138, 85], fill=(255, 255, 255))
    draw.ellipse([123, 88, 127, 92], fill=(0, 112, 192))
    
    # Right box
    draw_rounded_box(draw, [180, 20, 780, 140], 12, (255, 255, 255), (180, 180, 180), 2)
    
    # Thymeleaf Logo & Text inside box
    # Green leaf logo
    # draw leaf polygon
    draw.polygon([(220, 80), (250, 45), (270, 60), (265, 85), (245, 105), (225, 105)], fill=(0, 95, 47))
    draw.polygon([(225, 75), (250, 45), (258, 60), (252, 85), (240, 98)], fill=(0, 120, 60))
    # Thymeleaf Text
    draw.text((280, 50), "Thymeleaf", fill=(50, 50, 50), font=get_font(28, False))
    
    # Flutter Logo & Text
    # Flutter Chevrons
    # Upper chevron
    draw.polygon([(620, 45), (650, 45), (630, 65), (600, 65)], fill=(0, 180, 255))
    # Lower chevron
    draw.polygon([(630, 65), (660, 65), (620, 105), (590, 105)], fill=(0, 112, 192))
    draw.polygon([(620, 105), (660, 65), (645, 65), (605, 105)], fill=(0, 80, 180)) # darker overlay
    # Flutter Text
    draw.text((670, 52), "Flutter", fill=(50, 50, 50), font=get_font(28, False))
    
    # ─── ROW 2: SECURITY (JWT) ───
    # Icon: Shield with lock
    # Shield shape outline
    draw.polygon([(50, 190), (110, 190), (110, 230), (80, 260), (50, 230)], fill=(245, 247, 250))
    draw.line([(50, 190), (110, 190), (110, 230), (80, 260), (50, 230), (50, 190)], fill=(0, 0, 0), width=3)
    # Lock inside shield
    draw_rounded_box(draw, [70, 215, 90, 240], 2, (0, 0, 0), (0, 0, 0), 1)
    draw.arc([73, 205, 87, 220], 180, 360, fill=(0, 0, 0), width=2)
    
    # Right box
    draw_rounded_box(draw, [180, 160, 780, 280], 12, (255, 255, 255), (180, 180, 180), 2)
    
    # JWT Logo (Starburst) & Text
    # Starburst petals
    star_x, star_y = 360, 220
    colors = [
        (251, 0, 137), (218, 0, 137), (137, 0, 218), (0, 180, 255),
        (0, 210, 180), (0, 210, 80), (180, 210, 0), (251, 140, 0)
    ]
    # Draw starburst using rounded lines radiating from center
    import math
    for i in range(12):
        angle = i * (360 / 12)
        rad = math.radians(angle)
        x_start = star_x + int(10 * math.cos(rad))
        y_start = star_y + int(10 * math.sin(rad))
        x_end = star_x + int(32 * math.cos(rad))
        y_end = star_y + int(32 * math.sin(rad))
        draw.line([x_start, y_start, x_end, y_end], fill=colors[i % len(colors)], width=6)
    # White vertical divider line in the center of the starburst
    draw.line([star_x, star_y - 35, star_x, star_y + 35], fill=(255, 255, 255), width=6)
    # JWT Text
    draw.text((430, 190), "JWT", fill=(0, 0, 0), font=get_font(42, True))
    
    # ─── ROW 3: BACKEND (Spring Boot) ───
    # Icon: Browser with gear
    # Browser window
    draw.rectangle([45, 340, 115, 395], outline=(0, 112, 192), width=2)
    draw.line([45, 350, 115, 350], fill=(0, 112, 192), width=2)
    # Gear
    draw.ellipse([85, 375, 110, 400], outline=(55, 71, 79), width=2)
    # Gear teeth
    for i in range(8):
        angle = i * (360 / 8)
        rad = math.radians(angle)
        gx = 97 + int(15 * math.cos(rad))
        gy = 387 + int(15 * math.sin(rad))
        draw.line([97, 387, gx, gy], fill=(55, 71, 79), width=3)
    draw.ellipse([92, 382, 102, 392], fill=(255, 255, 255), outline=(55, 71, 79), width=2)
    # Small text below icon
    draw.text((55, 402), "BACKEND", fill=(0, 112, 192), font=get_font(8, True))
    
    # Right box
    draw_rounded_box(draw, [180, 300, 780, 420], 12, (255, 255, 255), (180, 180, 180), 2)
    
    # Green Spring Boot Block
    # Width 220 px, Height 118 px, centered horizontally in the box
    draw.rectangle([400, 301, 620, 419], fill=(109, 179, 63))
    # Leaf logo inside green block
    # White circle
    draw.ellipse([420, 335, 470, 385], fill=(255, 255, 255))
    # Green leaf inside white circle
    draw.polygon([(435, 368), (455, 342), (460, 355), (452, 373)], fill=(109, 179, 63))
    draw.polygon([(435, 368), (446, 355), (452, 358), (442, 372)], fill=(80, 140, 40)) # shadow
    # Spring Boot Text inside green block
    draw.text((485, 330), "spring", fill=(255, 255, 255), font=get_font(22, False))
    draw.text((485, 358), "Boot", fill=(255, 255, 255), font=get_font(24, True))
    
    # ─── ROW 4: DATABASE (SQL Server & Firebase) ───
    # Icon: Database Cylinder
    db_x = 80
    draw.ellipse([db_x - 35, 470, db_x + 35, 490], fill=(245, 247, 250), outline=(0, 0, 0), width=3)
    draw.rectangle([db_x - 35, 480, db_x + 35, 510], fill=(245, 247, 250))
    draw.line([db_x - 35, 480, db_x - 35, 510], fill=(0, 0, 0), width=3)
    draw.line([db_x + 35, 480, db_x + 35, 510], fill=(0, 0, 0), width=3)
    draw.ellipse([db_x - 35, 500, db_x + 35, 520], fill=(245, 247, 250), outline=(0, 0, 0), width=3)
    
    draw.rectangle([db_x - 35, 510, db_x + 35, 540], fill=(245, 247, 250))
    draw.line([db_x - 35, 510, db_x - 35, 540], fill=(0, 0, 0), width=3)
    draw.line([db_x + 35, 510, db_x + 35, 540], fill=(0, 0, 0), width=3)
    draw.ellipse([db_x - 35, 530, db_x + 35, 550], fill=(245, 247, 250), outline=(0, 0, 0), width=3)
    
    # Right box
    draw_rounded_box(draw, [180, 440, 780, 560], 12, (255, 255, 255), (180, 180, 180), 2)
    
    # SQL Server Logo & Text
    # Red mesh pyramid
    px, py = 320, 485
    draw.polygon([(px, py), (px - 25, py + 35), (px + 25, py + 35)], outline=(218, 37, 29), width=2)
    draw.line([px, py, px, py + 35], fill=(218, 37, 29), width=2)
    draw.line([px - 25, py + 35, px + 25, py + 35], fill=(218, 37, 29), width=2)
    draw.line([px, py, px - 12, py + 35], fill=(218, 37, 29), width=1)
    draw.line([px, py, px + 12, py + 35], fill=(218, 37, 29), width=1)
    draw.line([px - 12, py + 18, px + 12, py + 18], fill=(218, 37, 29), width=1)
    
    # SQL Server Text
    draw.text((270, 522), "Microsoft", fill=(80, 80, 80), font=get_font(10, False))
    draw.text((270, 532), "SQL Server", fill=(0, 0, 0), font=get_font(18, True))
    
    # Firebase Blue Block
    # Width 120 px, Height 118 px
    draw.rectangle([570, 441, 690, 559], fill=(2, 136, 209))
    # Firebase flame (yellow/orange triangles)
    fx, fy = 630, 490
    draw.polygon([(fx, fy - 25), (fx - 15, fy + 15), (fx + 15, fy + 15)], fill=(255, 179, 0)) # orange
    draw.polygon([(fx, fy - 25), (fx - 5, fy + 15), (fx + 15, fy + 15)], fill=(255, 202, 40)) # yellow
    # Firebase Text inside blue block
    draw.text((605, 515), "Firebase", fill=(255, 255, 255), font=get_font(12, True))
    
    # Save Image
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)
    print(f"Technology stack diagram successfully saved to {output_path}")

if __name__ == "__main__":
    draw_stack_diagram("scratch/architecture.png")
