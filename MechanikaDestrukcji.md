# Dokumentacja Mechaniki Destrukcji i Botów (Roblox)

W naszej grze implementujemy system zniszczeń oraz dynamicznych NPC (Botów) z poszanowaniem architektury klient-serwer (FilteringEnabled) i praw fizyki.

## 1. System Zniszczeń Muru (Pre-fragmentacja i Pęd)

- **Fizyka Uderzenia**: Przy trafieniu pocisku obliczany jest jego pęd ($p = m \cdot v$). Wektor impulsu przekazywany jest do funkcji `ApplyImpulseAtPosition(impulse, hitPosition)`, co realistycznie odrzuca odłamki i nadaje im moment obrotowy.
- **Optymalizacja Destrukcji**: Zamiast kosztownych operacji CSG w czasie rzeczywistym, mur opiera się na **pre-fragmentacji**. Składa się z mniejszych części połączonych za pomocą `WeldConstraint` (domyślnie `Anchored = true`).
- **Integralność Strukturalna**: Zaimplementowano algorytm flood-fill/BFS sprawdzający połączenia z fundamentem. Odłamki odcięte od podstawy tracą zakotwiczenie i spadają zgodnie z grawitacją.
- **Wydajność**: Odłamki są usuwane po określonym czasie (`Debris:AddItem`), a ich fizyka kolizji jest wyłączana (`CanQuery = false`, `CanTouch = false`) po wygenerowaniu, by nie obciążać silnika.

## 2. Dynamiczne Boty R15 (Architektura Serwerowa)

- **Model Replikacji**: Boty tworzone są po stronie serwera, co gwarantuje pełną synchronizację (FilteringEnabled) u wszystkich graczy. 
- **Network Ownership**: Dla płynności ruchu, serwer przypisuje `NetworkOwner` do odpowiedniego klienta (lub zachowuje autorytet, ustawiając `nil`), co eliminuje rubberbanding bez łamania replikacji.
- **Animacje**: Używamy domyślnych animacji twórcy przypisanych do obiektu `Animator`. Nasłuchujemy zdarzenia `Humanoid.Running`, aby dynamicznie odtwarzać i zatrzymywać ścieżkę chodu.

## 3. Pasywny Ragdoll i Reakcja na Postrzał

Kiedy serwer zwaliduje trafienie w bota:
1. **Inicjalizacja**: Ustawiamy `humanoid.BreakJointsOnDeath = false` oraz `humanoid.RequiresNeck = false`.
2. **Transformacja Stawów**: Zamiast niszczyć łączenia, wyłączamy je (`Motor6D.Enabled = false`). Pomiędzy kończynami dodawane są `BallSocketConstraint` oraz kluczowe `NoCollisionConstraint`, aby zapobiec odpychaniu się hitboxów ("eksplodujący ragdoll").
3. **Kinetyka**: Impuls fizyczny z pocisku aplikowany jest bezpośrednio w punkt trafienia kończyny, po stronie serwera. Skala impulsu jest zbalansowana, aby oddać realistyczny pęd kuli bez wyolbrzymionego odrzutu.

## Faza 3: Serwerowy Anti-Cheat i Ostateczny Szlif Ragdolla

### Wdrożenie Anti-Cheatu (CombatHandler.server.lua)
Do bezpiecznej wersji serwerowej wprowadzono rygorystyczną walidację każdego pocisku. Klient wysyła sygnał o trafieniu w bota, jednak to serwer decyduje, czy uderzenie jest autentyczne:
1. **Cooldown Spamu:** Mechanizm anty-autoclickerowy wymusza 0.05 sekundy pauzy pomiędzy strzałami. Pakiety przychodzące częściej są bezdźwięcznie ignorowane.
2. **Limit Dystansu (Zasięg):** Sprawdzenie `(Gracz - Cel).Magnitude` upewnia się, czy cel mieści się w akceptowalnych 1000 studów.
3. **Raycast Line of Sight (LoS):** System dokonuje serwerowego pomiaru `workspace:Raycast` bezpośrednio z Głowy postaci strzelca do współrzędnych trafienia `hitPosition`. Użyto tu `RaycastParams.FilterType = Exclude`, ignorując wszystkich graczy i foldery z botami, koncentrując promień na przeszkodach stałych (np. ściany, podłogi). Trafienie w cokolwiek po drodze ujawnia oszustwo "strzału przez ścianę" (Silent Aim) i powoduje zablokowanie ataku.

### Doskonalenie Ragdolla (Ragdoll.lua)
Aby uzyskać prawdziwie "szmaciany" efekt Ragdolla:
- Wyrzucono prymitywną komendę `motor.Enabled = false`, która potrafiła zawieszać silnik animacji Robloxa w bezruchu ("Deska"). Zamiast tego zaimplementowano twarde fizyczne odpięcie stawu: `motor.Part1 = nil`, z zachowaniem starego wskazania w `ObjectValue` celem późniejszej reanimacji `Ragdoll.Disable()`.
- Dopracowano per-stawowe limity kątowe `BallSocketConstraint`, dostosowując ruchomość każdego połączenia w oparciu o anatomię (np. Biodra = 85°, Ramiona = 100°, Kark = 45°). Uniemożliwia to groteskowe wywijanie rąk z tyłu głowy, utrzymując realistyczne opadanie uderzonego bot'a.
- Moduł `NPCSpawner` pobiera teraz awatary dynamicznie metodą `GetHumanoidDescriptionFromUserId` zamiast lokalnego klonowania trybu edycji, co zapewnia poprawność kształtów `MeshPart` i prawidłową pracę `NoCollisionConstraint` na stykach ciała R15.

