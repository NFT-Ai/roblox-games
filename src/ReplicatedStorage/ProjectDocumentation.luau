--[[
# DOKUMENTACJA PROJEKTU: PLATFORMÓWKA 2D (MARIO CLONE)
Data: 2026-06-21

## CEL PROJEKTU
Stworzenie klasycznej gry platformowej 2D z widokiem bocznym, mechaniką paralaksy tła i zablokowanym ruchem w jednej płaszczyźnie.

## ARCHITEKTURA I ŚRODOWISKO
Gra opiera się na silniku Roblox, wykorzystując Luau. System 2D jest emulowany poprzez:
1. Zablokowanie ruchu postaci w osi Z (głębia).
2. Skrypt kamery (Scriptable), który śledzi gracza tylko w osiach X i Y.
3. Tło wyświetlane w ScreenGui dla uzyskania efektu "płaskiego" obrazu (UI Overlay zamiast 3D).

## OPIS SKRYPTÓW

### 1. StarterPlayerScripts/Camera2D (LocalScript)
Odpowiada za widok z boku.
- Typ kamery: Scriptable.
- Działanie: W każdej klatce (RenderStep) ustawia pozycję kamery na wysokości gracza, zachowując stały dystans w osi Z. Patrzy bezpośrednio na postać.

```lua
-- Kluczowa logika:
local cameraPosition = Vector3.new(rootPart.Position.X, rootPart.Position.Y + 5, 40)
camera.CFrame = CFrame.lookAt(cameraPosition, Vector3.new(rootPart.Position.X, rootPart.Position.Y + 2, 0))
```

### 2. StarterPlayerScripts/BackgroundHandler (LocalScript)
Zarządza tłem i efektem paralaksy.
- Wykorzystuje ImageLabel w ScreenGui.
- Paralaksa: Przesuwa `ImageRectOffset` na podstawie pozycji X gracza, co daje wrażenie ruchu tła.

### 3. StarterCharacterScripts/Lock2DMovement (LocalScript)
Wymusza rozgrywkę 2D.
- Co klatkę resetuje pozycję Z HumanoidRootPart do 0.
- Zapobiega "wpadaniu" gracza w głąb ekranu.

## PROBLEMY DO ROZWIĄZANIA
1. Widoczność: Ustawienie FOV i dystansu kamery musi być precyzyjne, aby UI tła nie zasłaniało świata 3D lub odwrotnie.
2. Wsparcie dla bitmap: Upewnienie się, że identyfikatory obrazów (rbxassetid) są poprawne i załadowane.

## JAK ROBIĆ PLANY I PARALAKSĘ 2D
- Planowanie: Najpierw zdefiniuj "Grid" (siatkę) ruchu. W Roblox oś X to lewo/prawo, Y to góra/dół.
- Paralaksa: Podziel tło na warstwy (bliskie, średnie, dalekie). Każda warstwa powinna przesuwać się z inną prędkością (mnożnik pozycji X gracza).
]]

return {}
