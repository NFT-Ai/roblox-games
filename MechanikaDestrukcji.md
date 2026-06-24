# Dokumentacja Mechaniki Destrukcji i Botów (Roblox)

W naszej grze zaimplementowaliśmy zaawansowany system fizycznej destrukcji z elementami kinetycznymi oraz system dynamicznych NPC (Botów) wykorzystujący najnowsze standardy Roblox.

## 1. System Zniszczeń Muru (Voxel Destruction)
Wykorzystujemy zmodyfikowany moduł `VoxBreaker` do rzeźbienia otworów w obiektach.
- **Kształt Zniszczeń**: Przy uderzeniu pocisku tworzony jest okrągły hitbox (`Enum.PartType.Ball`), który wykrawa kuliste wyrwy w obiekcie docelowym (murze).
- **Zasada Zachowania Energii**: Wyrwane kawałki muru (woksele) nie znikają. Silnik oblicza energię kinetyczną wystrzelonego pocisku ($E_k = \frac{1}{2}mv^2$) oraz kąt uderzenia. Energia ta jest w ułamku sekundy aplikowana do nowo powstałych odłamków w postaci precyzyjnego Impulsu Fizycznego (`ApplyImpulse`).
- **Zawalające się Ściany (Structural Integrity)**: Mur (np. `TestWall`) ma wyłączone statyczne zakotwiczenie (`Anchored = false`), ale jego duża masa i grubość utrzymują go w pionie. Gdy gracz "podetnie" mur strzałami z dołu, silnik fizyczny Robloxa automatycznie przelicza środek ciężkości. W efekcie podcięta ściana realistycznie zawala się i runie na ziemię pod własnym ciężarem.

## 2. Dynamiczne Boty R15
Stworzyliśmy nowoczesne, zaokrąglone boty R15 (korzystające z ubrań i pakietu Roblox Boy), które posiadają pełną fizykę wielosegmentowych ciał.
- **Architektura Lokalna (Network Ownership)**: Aby zapobiec błędom replikacji (tzw. "glitchom" i rubberbandingowi), boty generowane są natychmiast na komputerze klienta za pomocą skryptu lokalnego (`LocalScript`). Dzięki temu klient ma 100% autorytetu nad fizyką botów.
- **Preloader**: Z powodu dynamicznego wczytywania zasobów graficznych z serwerów Roblox, zaimplementowano interfejs Preloadera (`ContentProvider:PreloadAsync`). Zatrzymuje on renderowanie imion do czasu pełnego wczytania siatek 3D i tekstur do pamięci VRAM.
- **Dynamiczna Animacja**: Moduł wyszukuje ID domyślnej animacji chodu z aktywnego awatara gracza i wstrzykuje go bezpośrednio do obiektów `Animator` naszych NPC. Gdy bot wywołuje komendę `MoveTo()`, animacja jest odtwarzana mechanicznie.

## 3. Aktywny Ragdoll i Fizyka Postrzału
Kiedy pocisk wejdzie w kolizję z botem:
1. **Natychmiastowa Śmierć**: Życie (Health) spada do 0, lecz zapobiegamy standardowemu rozsypaniu się modelu (`BreakJointsOnDeath = false`).
2. **Transformacja Stawów**: Twarde łączenia typu `Motor6D` są natychmiastowo zrywane i zastępowane luźnymi zawiasami `BallSocketConstraint`, z włączonymi limitami skrętu. Tworzy to efekt "szmacianej lalki" (Ragdoll).
3. **Kinetyka Uderzenia**: Silnik przenosi energię uderzeniową pocisku bezpośrednio na trafioną kończynę oraz tors bota (w odpowiednio przeskalowanych proporcjach), sprawiając, że bot efektownie i z impetem odlatuje w tył zgodnie z trajektorią lotu kuli.
