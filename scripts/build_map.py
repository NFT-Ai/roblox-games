import sys
import os
from PIL import Image

def rgb_to_type(r, g, b, a):
    if a < 128:
        return 'Empty'
    
    # Tolerancja dla kolorów (często programy graficzne nie dają idealnie 255)
    if g > 150 and r < 100 and b < 100:
        return 'Ground'
    if r > 150 and g < 100 and b < 100:
        return 'Fire'
    if r > 150 and g > 150 and b < 100:
        return 'Coin'
    if b > 150 and r < 100 and g < 100:
        return 'Spawn'
        
    return 'Empty'

def build_map(image_path, out_path):
    img = Image.open(image_path).convert('RGBA')
    width, height = img.size
    
    lua_code = "local MapData = {}\n"
    lua_code += f"MapData.Width = {width}\n"
    lua_code += f"MapData.Height = {height}\n"
    lua_code += "MapData.Grid = {\n"
    
    for y in range(height):
        lua_code += "    {"
        row = []
        for x in range(width):
            r, g, b, a = img.getpixel((x, y))
            t = rgb_to_type(r, g, b, a)
            row.append(f'"{t}"')
        lua_code += ", ".join(row) + "},\n"
        
    lua_code += "}\n\nreturn MapData"
    
    with open(out_path, 'w') as f:
        f.write(lua_code)
    print(f"Pomyślnie wygenerowano mapę {width}x{height} do {out_path} na podstawie {image_path}")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Użycie: python build_map.py <input.png> <output.lua>")
        sys.exit(1)
    build_map(sys.argv[1], sys.argv[2])
