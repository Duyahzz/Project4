from PIL import Image, ImageDraw, ImageFont
import math
import os

def get_font(size, bold=False):
    try:
        font_name = "arialbd.ttf" if bold else "arial.ttf"
        return ImageFont.truetype(font_name, size)
    except Exception:
        return ImageFont.load_default()

def draw_centered_label(draw, text, cx, cy, font, bg_color=(255, 255, 255), text_color=(15, 23, 42)):
    try:
        bbox = draw.textbbox((0, 0), text, font=font)
        w = bbox[2] - bbox[0]
        h = bbox[3] - bbox[1]
    except Exception:
        w = len(text) * 7
        h = 12
    x = cx - w / 2
    y = cy - h / 2
    pad = 5
    # draw background box with rounded corners
    draw.rounded_rectangle([x - pad, y - pad, x + w + pad, y + h + pad], radius=3, fill=bg_color, outline=(203, 213, 225), width=1)
    draw.text((x, y), text, fill=text_color, font=font)

def draw_arrow(draw, start, end, label="", fill=(71, 85, 105), width=2, arrow_size=10, double=False):
    x1, y1 = start
    x2, y2 = end
    
    # Draw main line
    draw.line([x1, y1, x2, y2], fill=fill, width=width)
    
    # Calculate arrowhead angle
    angle = math.atan2(y2 - y1, x2 - x1)
    
    # Head at end point (x2, y2)
    p1 = (x2 - arrow_size * math.cos(angle - math.pi/6), y2 - arrow_size * math.sin(angle - math.pi/6))
    p2 = (x2 - arrow_size * math.cos(angle + math.pi/6), y2 - arrow_size * math.sin(angle + math.pi/6))
    draw.polygon([end, p1, p2], fill=fill)
    
    # Head at start point if double-headed
    if double:
        p3 = (x1 + arrow_size * math.cos(angle - math.pi/6), y1 + arrow_size * math.sin(angle - math.pi/6))
        p4 = (x1 + arrow_size * math.cos(angle + math.pi/6), y1 + arrow_size * math.sin(angle + math.pi/6))
        draw.polygon([start, p3, p4], fill=fill)
        
    # Draw label in the middle
    if label:
        cx = (x1 + x2) / 2
        cy = (y1 + y2) / 2
        draw_centered_label(draw, label, cx, cy, get_font(11, True))

def draw_detailed_diagram(output_path):
    width = 1000
    height = 750
    img = Image.new('RGB', (width, height), color=(248, 250, 252)) # slate-50
    draw = ImageDraw.Draw(img)
    
    # Draw light grey grid background
    grid_spacing = 25
    for x in range(0, width, grid_spacing):
        draw.line([x, 0, x, height], fill=(241, 245, 249), width=1)
    for y in range(0, height, grid_spacing):
        draw.line([0, y, width, y], fill=(241, 245, 249), width=1)
        
    # Helpers for rounded boxes
    def draw_rounded_box(draw, box, radius, fill_color, outline_color, width=2):
        x0, y0, x1, y1 = box
        draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=fill_color, outline=outline_color, width=width)

    # ─── HEADER BANNER ───
    draw.rectangle([0, 0, width, 70], fill=(15, 23, 42)) # slate-900
    draw.text((30, 20), "eStudiez Portal - Detailed System Architecture & Data Flow Diagram", fill=(255, 255, 255), font=get_font(20, True))
    
    # ─── LAYER LABELS (Left side) ───
    draw.text((25, 135), "PRESENTATION\nLAYER", fill=(71, 85, 105), font=get_font(11, True))
    draw.text((25, 265), "SECURITY\nLAYER", fill=(71, 85, 105), font=get_font(11, True))
    draw.text((25, 415), "BACKEND\nLAYER", fill=(71, 85, 105), font=get_font(11, True))
    draw.text((25, 595), "DATA &\nSERVICES", fill=(71, 85, 105), font=get_font(11, True))
    
    # Horizontal separator lines for layers (very thin and dashed-looking)
    for y in [220, 345, 510]:
        for x in range(20, width - 20, 10):
            draw.line([x, y, x + 5, y], fill=(226, 232, 240), width=1)

    # ─── PRESENTATION LAYER ───
    # 1. Thymeleaf Web Portal Box
    t_box = [150, 100, 420, 195]
    draw_rounded_box(draw, t_box, 10, (240, 253, 244), (22, 163, 74), 2) # Green-100 fill, Green-600 border
    # Thymeleaf Leaf Logo
    draw.polygon([(180, 155), (200, 120), (215, 130), (210, 150), (195, 165), (182, 165)], fill=(21, 128, 61))
    draw.polygon([(182, 150), (200, 120), (205, 130), (201, 150), (192, 160)], fill=(34, 197, 94))
    # Text
    draw.text((230, 120), "Thymeleaf Web Portal", fill=(21, 128, 61), font=get_font(15, True))
    draw.text((230, 142), "Web client interface for Admin,", fill=(71, 85, 105), font=get_font(11, False))
    draw.text((230, 157), "Teachers, and Managers", fill=(71, 85, 105), font=get_font(11, False))
    
    # 2. Flutter Mobile App Box
    f_box = [580, 100, 850, 195]
    draw_rounded_box(draw, f_box, 10, (240, 249, 255), (2, 132, 199), 2) # Blue-100 fill, Blue-600 border
    # Flutter Logo (Chevrons)
    cx, cy = 610, 148
    draw.polygon([(cx + 15, cy - 25), (cx + 30, cy - 25), (cx + 15, cy - 10), (cx, cy - 10)], fill=(0, 180, 255))
    draw.polygon([(cx + 15, cy - 10), (cx + 30, cy - 10), (cx + 5, cy + 15), (cx - 10, cy + 15)], fill=(0, 112, 192))
    draw.polygon([(cx + 5, cy + 15), (cx + 30, cy - 10), (cx + 20, cy - 10), (cx - 2, cy + 15)], fill=(0, 80, 180))
    # Text
    draw.text((655, 120), "Flutter Mobile App", fill=(2, 132, 199), font=get_font(15, True))
    draw.text((655, 142), "Cross-platform mobile client for", fill=(71, 85, 105), font=get_font(11, False))
    draw.text((655, 157), "Students, Parents, and Teachers", fill=(71, 85, 105), font=get_font(11, False))

    # ─── SECURITY LAYER (JWT) ───
    jwt_box = [370, 245, 630, 325]
    draw_rounded_box(draw, jwt_box, 8, (250, 245, 255), (126, 34, 206), 2) # Purple fill, purple border
    # JWT Starburst Logo
    star_x, star_y = 405, 285
    colors = [(251, 0, 137), (218, 0, 137), (137, 0, 218), (0, 180, 255), (0, 210, 80), (251, 140, 0)]
    for i in range(12):
        angle = i * (360 / 12)
        rad = math.radians(angle)
        x_start = star_x + int(5 * math.cos(rad))
        y_start = star_y + int(5 * math.sin(rad))
        x_end = star_x + int(18 * math.cos(rad))
        y_end = star_y + int(18 * math.sin(rad))
        draw.line([x_start, y_start, x_end, y_end], fill=colors[i % len(colors)], width=3)
    draw.line([star_x, star_y - 20, star_x, star_y + 20], fill=(255, 255, 255), width=3)
    # Text
    draw.text((440, 260), "JWT Security Filter", fill=(126, 34, 206), font=get_font(14, True))
    draw.text((440, 282), "Token verification & role access control", fill=(71, 85, 105), font=get_font(10, False))
    draw.text((440, 296), "Intercepts and authenticates requests", fill=(71, 85, 105), font=get_font(10, False))

    # ─── BACKEND LAYER (Spring Boot) ───
    sb_box = [330, 370, 670, 485]
    draw_rounded_box(draw, sb_box, 10, (240, 253, 244), (22, 163, 74), 2) # Green fill, Green-600 border
    # Spring Leaf inside Circle
    draw.ellipse([350, 400, 400, 450], fill=(255, 255, 255), outline=(22, 163, 74), width=1)
    draw.polygon([(365, 435), (385, 410), (390, 420), (382, 438)], fill=(34, 197, 94))
    draw.polygon([(365, 435), (376, 422), (382, 425), (372, 438)], fill=(21, 128, 61))
    # Text
    draw.text((415, 385), "Spring Boot Engine (REST API)", fill=(21, 128, 61), font=get_font(16, True))
    draw.text((415, 410), "Controllers: Auth, User, Attendance, Class, Chat, News", fill=(71, 85, 105), font=get_font(11, False))
    draw.text((415, 428), "Services: UserService, ChatService, NotificationService", fill=(71, 85, 105), font=get_font(11, False))
    draw.text((415, 446), "Spring Security, Spring Data JPA / Hibernate", fill=(71, 85, 105), font=get_font(11, False))

    # ─── DATA & SERVICES LAYER ───
    # 1. Microsoft SQL Server
    sql_box = [150, 545, 420, 650]
    draw_rounded_box(draw, sql_box, 10, (254, 242, 242), (220, 38, 38), 2) # Red fill, Red border
    # Red Pyramid mesh logo
    px, py = 185, 570
    draw.polygon([(px, py), (px - 20, py + 30), (px + 20, py + 30)], outline=(220, 38, 38), width=2)
    draw.line([px, py, px, py + 30], fill=(220, 38, 38), width=2)
    draw.line([px - 10, py + 15, px + 10, py + 15], fill=(220, 38, 38), width=1)
    # Text
    draw.text((220, 560), "Microsoft SQL Server", fill=(185, 28, 28), font=get_font(14, True))
    draw.text((220, 582), "Relational Database (eStudentDB)", fill=(71, 85, 105), font=get_font(10, False))
    draw.text((220, 596), "Stores: Timetable, Grades, Users,", fill=(71, 85, 105), font=get_font(10, False))
    draw.text((220, 610), "Attendance, and Enrollment records", fill=(71, 85, 105), font=get_font(10, False))

    # 2. Firebase Cloud Services
    fb_box = [580, 545, 850, 650]
    draw_rounded_box(draw, fb_box, 10, (255, 251, 235), (217, 119, 6), 2) # Orange fill, Orange border
    # Firebase flame
    fx, fy = 615, 585
    draw.polygon([(fx, fy - 20), (fx - 12, fy + 12), (fx + 12, fy + 12)], fill=(255, 179, 0))
    draw.polygon([(fx, fy - 20), (fx - 4, fy + 12), (fx + 12, fy + 12)], fill=(255, 202, 40))
    # Text
    draw.text((650, 560), "Firebase Services", fill=(217, 119, 6), font=get_font(14, True))
    draw.text((650, 582), "FCM, Cloud Firestore / Storage", fill=(71, 85, 105), font=get_font(10, False))
    draw.text((650, 596), "Handles: Push notifications,", fill=(71, 85, 105), font=get_font(10, False))
    draw.text((650, 610), "Real-time Chat, and File Uploads", fill=(71, 85, 105), font=get_font(10, False))

    # ─── FLOW ARROWS ───
    # Flow 1a: Thymeleaf to JWT Security Filter
    # Start: bottom-center of Thymeleaf box (285, 195), End: top-left of JWT box (420, 245)
    draw_arrow(draw, (285, 195), (420, 245), label="1a. Send HTTP Request", fill=(71, 85, 105), width=2)
    
    # Flow 1b: Flutter to JWT Security Filter
    # Start: bottom-center of Flutter box (715, 195), End: top-right of JWT box (580, 245)
    draw_arrow(draw, (715, 195), (580, 245), label="1b. Send HTTP Request", fill=(71, 85, 105), width=2)

    # Flow 2: JWT to Spring Boot
    # Start: bottom-center of JWT box (500, 325), End: top-center of Spring Boot box (500, 370)
    draw_arrow(draw, (500, 325), (500, 370), label="2. Forward Authorized Request", fill=(71, 85, 105), width=2)

    # Flow 3a: Spring Boot to MS SQL Server
    # Start: bottom-left of Spring Boot box (380, 485), End: top-center of SQL Server box (285, 545)
    draw_arrow(draw, (380, 485), (285, 545), label="3a. JPA / JDBC SQL Transactions", fill=(71, 85, 105), width=2, double=True)

    # Flow 3b: Spring Boot to Firebase Services
    # Start: bottom-right of Spring Boot box (620, 485), End: top-center of Firebase box (715, 545)
    draw_arrow(draw, (620, 485), (715, 545), label="3b. Cloud Messaging & Storage", fill=(71, 85, 105), width=2, double=True)

    # Flow 4: Firebase back to Flutter Mobile App (Real-time notifications)
    # Drawing multi-segment arrow: Firebase right-center (850, 597) -> right outer path (920, 597) -> right outer path (920, 148) -> Flutter right-center (850, 148)
    draw.line([(850, 597), (910, 597), (910, 148), (850, 148)], fill=(217, 119, 6), width=2)
    # Draw arrow head on Flutter right-center (850, 148) (pointing left)
    arrow_size = 10
    draw.polygon([(850, 148), (850 + arrow_size, 148 - 5), (850 + arrow_size, 148 + 5)], fill=(217, 119, 6))
    # Label on vertical line of Flow 4
    draw_centered_label(draw, "4. Real-time FCM Notifications & Message Stream", 910, 370, get_font(10, True), text_color=(217, 119, 6))

    # Save Image
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)
    print(f"Diagram successfully saved to {output_path}")

if __name__ == "__main__":
    draw_detailed_diagram("C:/Users/ACER/.gemini/antigravity/brain/dea5ba61-4960-4852-a9d6-f0399d4e1e13/architecture_flow.png")
