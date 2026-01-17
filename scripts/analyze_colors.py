from PIL import Image
import os

def analyze_corners(image_path):
    try:
        if not os.path.exists(image_path):
            print(f"File not found: {image_path}")
            return

        img = Image.open(image_path).convert("RGBA")
        width, height = img.size
        
        corners = [
            (0, 0),
            (width - 1, 0),
            (0, height - 1),
            (width - 1, height - 1)
        ]
        
        print(f"--- Analysis for {os.path.basename(image_path)} ---")
        for x, y in corners:
            pixel = img.getpixel((x, y))
            print(f"Corner ({x}, {y}): {pixel}")

    except Exception as e:
        print(f"Error analyzing {image_path}: {e}")

if __name__ == "__main__":
    files = [
        "assets/png/body_chart_skeleton_front.png",
        "assets/png/body_chart_muscles_front.png",
        "assets/png/body_chart_head_front.png"
    ]
    
    base = os.getcwd()
    for f in files:
        analyze_corners(os.path.join(base, f))
