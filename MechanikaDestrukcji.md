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
