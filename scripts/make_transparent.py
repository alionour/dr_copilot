from PIL import Image
import os
import math

def color_distance(c1, c2):
    return math.sqrt(sum((a - b) ** 2 for a, b in zip(c1, c2)))

def flood_fill_transparency(image_path, tolerance=40):
    try:
        if not os.path.exists(image_path):
            print(f"Skipping: {image_path} (not found)")
            return

        print(f"Processing (Flood Fill): {image_path}")
        img = Image.open(image_path).convert("RGBA")
        width, height = img.size
        pixels = img.load()

        # Start from all 4 corners
        seeds = [
            (0, 0),
            (width - 1, 0),
            (0, height - 1),
            (width - 1, height - 1)
        ]

        visited = set()
        stack = []

        # Identify background colors from corners
        for x, y in seeds:
            bg_color = pixels[x, y]
            # If corner is already transparent, skip
            if bg_color[3] == 0:
                continue
            stack.append((x, y))
            visited.add((x, y))

        # BFS Flood Fill
        while stack:
            cx, cy = stack.pop()
            current_color = pixels[cx, cy]
            
            # Make transparent
            pixels[cx, cy] = (255, 255, 255, 0)

            # Check neighbors
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nx, ny = cx + dx, cy + dy
                
                if 0 <= nx < width and 0 <= ny < height:
                    if (nx, ny) not in visited:
                        neighbor_color = pixels[nx, ny]
                        # If transparent, skip
                        if neighbor_color[3] == 0:
                            visited.add((nx, ny))
                            continue
                            
                        # Compare with current pixel (or original background? Using neighbor for gradient following)
                        # Better: compare with corner color? 
                        # Actually for textured paper, neighbor comparison is risky (drift).
                        # Let's check distance to the *original pixel at this seed*? 
                        # But we popped the seed.
                        # Simple approach: Check distance to (255,255,255) OR distance to neighbor < small?
                        # Let's stick to: "Is this pixel 'background-like'?"
                        # Since we analyzed the corners and they are greyish/white, let's assume anything 
                        # brighter than (50,50,50) could be background if connected? No, that kills the image.
                        
                        # Use neighbor similarity (gradient following)
                        dist = color_distance(current_color[:3], neighbor_color[:3])
                        if dist < tolerance:
                             stack.append((nx, ny))
                             visited.add((nx, ny))

        img.save(image_path, "PNG")
        print(f"Saved transparent (Flood Fill): {image_path}")

    except Exception as e:
        print(f"Error processing {image_path}: {e}")

if __name__ == "__main__":
    target_files = [
        "assets/png/body_chart_skeleton_front.png",
        "assets/png/body_chart_skeleton_back.png",
        "assets/png/body_chart_skeleton_lateral.png",
        "assets/png/body_chart_muscles_front.png",
        "assets/png/body_chart_muscles_back.png",
        "assets/png/body_chart_muscles_lateral.png",
        "assets/png/body_chart_lateral.png",
        "assets/png/body_chart_teeth_front.png",
        "assets/png/body_chart_head_front.png" 
    ]

    base_dir = os.getcwd()
    print(f"Working directory: {base_dir}")

    for rel_path in target_files:
        full_path = os.path.join(base_dir, rel_path)
        flood_fill_transparency(full_path, tolerance=30)
