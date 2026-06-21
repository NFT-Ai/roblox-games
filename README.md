# Platformówka 2D (Roblox)

Klasyczna platformówka 2D (side-scroller) na silniku Roblox / Luau.
Kod żyje na dysku w `src/` i jest synchronizowany do Studio przez **Rojo**.

## Struktura

```
src/
  StarterPlayerScripts/
    Camera2D.client.luau          # kamera boczna 2D (Scriptable)
    BackgroundHandler.client.luau # tło + paralaksa w ScreenGui
  StarterCharacterScripts/
    Lock2DMovement.client.luau     # blokada ruchu w osi Z (płaszczyzna 2D)
  ReplicatedStorage/
    ProjectDocumentation.luau      # dokumentacja założeń projektu
  ServerScriptService/             # (logika serwera — na razie pusto)
```

## Jak pracować (codzienny workflow)

1. **W Studio** zainstaluj wtyczkę **Rojo** (Toolbox → wyszukaj „Rojo", autor: UpliftGames),
   jeśli jej jeszcze nie masz.
2. W terminalu, w tym katalogu:
   ```bash
   rojo serve
   ```
3. W Studio: panel **Rojo → Connect**. Od teraz każda zmiana pliku `.luau`
   na dysku natychmiast pojawia się w grze.

## Budowanie pliku miejsca z kodu

```bash
rojo build default.project.json -o Platformowka.rbxl
```

## ⚠️ Ważne — zapisywanie świata (geometria, modele)

Rojo synchronizuje **kod (skrypty)**, ale geometria poziomów, części i modele
budowane ręcznie w Studio NIE są w `src/`. Pamiętaj, żeby **zapisywać miejsce
w Studio** (`File → Save to File`), aby nie stracić zbudowanego świata —
tak jak stało się wcześniej (praca istniała tylko w pliku auto-odzysku).
