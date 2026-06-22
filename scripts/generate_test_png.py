from PIL import Image

width, height = 20, 10
img = Image.new('RGBA', (width, height), color=(0, 0, 0, 0))

pixels = img.load()

# Rysujemy podłogę
for x in range(width):
    pixels[x, 9] = (0, 255, 0, 255) # Zielony

# Rysujemy lawę na środku
for x in range(5, 10):
    pixels[x, 9] = (255, 0, 0, 255) # Czerwony

# Rysujemy platformy
pixels[3, 6] = (0, 255, 0, 255)
pixels[4, 6] = (0, 255, 0, 255)

pixels[11, 5] = (0, 255, 0, 255)
pixels[12, 5] = (0, 255, 0, 255)

# Rysujemy monety
pixels[3, 4] = (255, 255, 0, 255) # Żółty
pixels[4, 4] = (255, 255, 0, 255)
pixels[11, 3] = (255, 255, 0, 255)

# Spawn
pixels[1, 8] = (0, 0, 255, 255) # Niebieski

img.save('/Users/mario/.gemini/antigravity/scratch/roblox-games/test_map.png')
print("Stworzono test_map.png")
