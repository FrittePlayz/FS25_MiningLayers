# Mining Layers (FS25)

[![Buy me fries](https://img.shields.io/badge/Buy%20me%20fries-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/fritteplayz)
[![Latest release](https://img.shields.io/github/v/release/FrittePlayz/FS25_MiningLayers?style=for-the-badge&color=2d8a4e)](https://github.com/FrittePlayz/FS25_MiningLayers/releases)
[![Języki](https://img.shields.io/badge/w--grze-PL%20·%20EN%20·%20DE%20·%20FR-2d8a4e?style=for-the-badge)](#)

![Mining Layers — materiał zależy od głębokości kopania, albo zbuduj własną żwirownię](docs/images/00_header.jpg)

**Prawdziwy górniczy gameplay dla Farming Simulator 25 — przekop się przez warstwy geologiczne albo zbuduj własną żwirownię w FS25.**
Materiał w łyżce zależy od głębokości kopania, nie od ręcznego wyboru: najpierw humus, potem żwir, potem pokład, na dole lita skała. Od wersji 1.4.0 pokład jest wybieralny — kopalnia węgla, żwirownia albo kamieniołom wapienia, na każdej mapie, bez edycji mapy. **Mod i podręcznik w grze są w całości po polsku** (tłumaczenie maszynowe — poprawki mile widziane!).

🇬🇧 [English](README.md) · 🇩🇪 [Deutsch](README.de.md) · 🇫🇷 [Français](README.fr.md) — *kompaktowa strona PL; szczegółowa dokumentacja jest w wersji angielskiej, pełny podręcznik w grze — po polsku.*

---

## ⛏️ Najpierw: to mapa decyduje o materiałach

O tym, czy materiał w ogóle istnieje i czy da się go wysypać z powrotem na ziemię, nie decyduje ten mod, lecz twoja mapa razem z listą modów. Z materiałów górniczych podstawowa gra zna tylko STONE: DIRT, GRAVEL, SAND, COAL, LIMESTONE i PAYDIRT zawsze pochodzą z map lub modów. Do tego dochodzi twardy limit gry: jednocześnie na ziemi może leżeć tylko 63 materiały, a podstawowa gra zajmuje już 48. Przy dużych listach modów ostatnie miejsca znikają szybko — wtedy materiał nadal wykopiesz, przewieziesz i sprzedasz, ale już nie wysypiesz.

Dlatego Mining Layers idzie drogą pośrednią, by pozostać grywalnym na każdej mapie: przy wczytywaniu mapy mod sprawdza raz, co TWOJA mapa naprawdę oferuje, i tylko to pokazuje w wyborze warstw (od 1.5.0). `(!)` za nazwą znaczy: kopanie, transport i sprzedaż działają, wysypywanie na tej mapie nie. Czego brakuje całkowicie, jest wypisane pod przekrojem. Nie musisz więc wcześniej testować map — jeśli czegoś brak, to wina mapy, nie moda.

**Zapamiętaj: mniej modów = więcej wolnych miejsc = więcej materiałów do wysypania.** Jeśli potrzebny ci materiał ma `(!)`, pomaga tylko jedno: usunąć mody wnoszące własne materiały terenu. Samego limitu 63 nie da się podnieść — jest wbudowany w grę.

## Wymagania

- **[TerraFarm](https://github.com/scfmod/FS25_TerraFarm)** od scfmod — dostępny wyłącznie na GitHubie. Nie zmieniaj nazwy folderu: musi zostać `FS25_0_TerraFarm` (kolejność ładowania).
- Co najmniej **jedna maszyna z konfiguracją TerraFarm** (np. oficjalny `FS25_TerraFarmMachines`).
- **Tylko PC lub Mac** — mod skryptowy, konsole ich nie obsługują.

Nieoficjalny dodatek, brak powiązań ze scfmod i GIANTS. Żadne pliki TerraFarm nie są dołączane.

## Instalacja

1. Pobierz TerraFarm (link powyżej).
2. Pobierz `FS25_MiningLayers.zip` z [releases](https://github.com/FrittePlayz/FS25_MiningLayers/releases).
3. Wrzuć oba ZIP-y — tak jak są, bez rozpakowywania — do folderu modów:
   `Dokumenty\My Games\FarmingSimulator2025\mods\`
4. Włącz OBA mody w wyborze modów swojego zapisu gry.

## Pierwsze wyrobisko w jednym kroku

Narysuj obszar TerraFarm (wielokąt) wokół przyszłego wyrobiska i **zostaw pola materiału puste**. To wszystko: kop gdziekolwiek w obszarze, a materiał pochodzi z głębokości. Wysokość odniesienia mod wylicza sam z obrysu.

Ustawienia i warstwy: menu ESC → Mining Layers. Tam też pełny podręcznik, po polsku.

## Własna geologia — żwirownia, kopalnia węgla

Od 1.4.0 pokład wybierasz w edytorze (ESC → Mining Layers → Warstwy): pokład to stały ostatni wiersz — weź COAL dla kopalni węgla, LIMESTONE lub STONE dla żwirowni, albo GRAVEL, SAND, DIRT, SOIL. Domyślnie zostaje PAYDIRT. Lita skała pod spodem kończy wyrobisko — tak ma być.

Warto wiedzieć: z materiałów moda tylko STONE jest zarejestrowany w podstawce — DIRT, SOIL, GRAVEL, SAND, COAL, LIMESTONE i PAYDIRT musi dostarczyć mapa albo inne mody (mapy budowlane i górnicze, jak te od RGC, mają te najpopularniejsze).

## Grubość warstw

Co najmniej 1,5 m na warstwę (edytor wymusza 1 m dla najwyższej, 1,5 m dla niższych) — cieńsze warstwy psują podnoszenie hałd. **Przy dużych maszynach klasy PC 8000 z 2 m na warstwę kopie się zauważalnie lepiej.**

## FAQ

**Czy Mining Layers działa na każdej mapie?**
Tak. Bez edycji mapy: narysuj obszar TerraFarm wokół wyrobiska i kop. Dla tekstur mod automatycznie bierze najbliższe podłoże, jakie mapa oferuje; jeśli nic nie pasuje, po prostu zostaje aktywny twój własny wybór tekstury.

**Czy potrzebny jest nowy zapis gry?**
Nie. Mining Layers działa z istniejącymi zapisami — zainstaluj, włącz oba mody w zapisie i graj dalej. Istniejące obszary TerraFarm działają dalej; obszary bez wpisanego materiału po prostu dostają warstwy.

**Jak zbudować żwirownię w FS25?**
Zainstaluj TerraFarm i Mining Layers, narysuj obszar, potem menu ESC → Mining Layers → Warstwy: DIRT na górze, LIMESTONE lub STONE jako pokład. Od 1.4.0 wszystko ustawisz w edytorze — bez XML.

**Jak wydobywać węgiel w FS25?**
Wybierz COAL jako pokład w edytorze warstw. Uwaga: COAL nie jest materiałem z podstawki — mapa albo mod górniczy musi go dostarczyć.

**Czy Mining Layers dodaje materiał paydirt do mojej mapy?**
Nie — mod w ogóle nie rejestruje materiałów. Korzysta tylko z tego, co dają gra podstawowa, mapa i twoje inne mody. Sam PAYDIRT nie jest materiałem z podstawki: dostarczają go mapy i mody górnicze, dlatego często i tak jest dostępny. Nie masz paydirtu w grze? Wybierz w edytorze pokład, który twoja mapa zna — log wypisuje wszystkie przy starcie.

**Czy mogę ustawić własne warstwy — więcej ziemi, różne rodzaje gleby?**
Tak, to sedno moda. Menu ESC → Mining Layers → Warstwy: dla każdego wyrobiska wybierasz materiał I grubość każdej warstwy nadkładu. Więcej ziemi? Ustaw warstwę DIRT na 4 m zamiast 2. Różnorodność? Ułóż DIRT na SOIL na żwirze. Działa wszystko, co twoja mapa zna jako materiał, a pokład na dole też jest do wyboru. Minimalne grubości: 1 m na górze, 1,5 m niżej (przy dużych maszynach 2 m kopie się lepiej).

**Dlaczego moja koparka nie kopie?**
TerraFarm potrzebuje konfiguracji maszyny dla tego pojazdu — bez niej nic się nie dzieje (to nie problem Mining Layers). Zainstaluj paczkę konfiguracji, np. FS25_TerraFarmMachines, i unikaj zdublowanych wpisów z kilku paczek.

**Dlaczego zawsze dostaję ten sam materiał, niezależnie od głębokości?**
W obszarze TerraFarm jest wpisany materiał — obszar działa wtedy jak zwykły TerraFarm bez warstw (celowo, do budów). Zostaw pola materiału puste, a warstwy przejmą robotę.

**Dlaczego nie ma warstw, chociaż narysowałem obszar? (3 najczęstsze przyczyny)**
1. **Maszyna nie ma przypisanego obszaru wejściowego.** TerraFarm wiąże obszary z MASZYNĄ, nie z twoją pozycją: ustawienia maszyny (domyślnie `Y`) → wybierz swój obszar jako wejście. Zapisywane per maszyna i zapis gry — najczęstszy przypadek supportu; HUD TerraFarm pokazuje wtedy twój obszar zamiast samego materiału.
2. **W obszarze wpisany jest materiał** → obszar celowo działa jak zwykły TerraFarm (tryb budowy). Zostaw pola materiału puste.
3. **Kopiesz poza wielokątem obszaru** (albo w obszarze ścieżki — ścieżki nigdy nie mają warstw).

**Jak głęboko można kopać?**
Do litej skały pod najgłębszą warstwą — tam koniec, celowo. Właśnie to czyni z tego górnictwo, a nie bezdenną dziurę z pieniędzmi.

**Jak grube powinny być warstwy?**
Co najmniej 1,5 m (edytor wymusza 1 m na górze, 1,5 m niżej). Przy dużych maszynach klasy PC 8000 lepiej 2 m na warstwę.

**Czy jest limit hałd — ile mogę wysypać?**
Nie. Wysypany materiał staje się przez TerraFarm prawdziwym terenem, a nie stertą z gry bazowej — limit pojemności z gry nie obowiązuje. Pamięć hałd to siatka 2 m na zapis gry, bez limitu liczby ani wielkości. Jedno zastrzeżenie: każda komórka 2 m pamięta JEDEN materiał (wygrywa ostatni wysyp) — nie mieszaj materiałów w tym samym miejscu, jeśli chcesz je odzyskać osobno.

**Zrzucanie na ziemię pokazuje „akcja niemożliwa"?**
TerraFarm sprawdza pionowo pod krawędzią łyżki: jeśli teren jest bliżej niż ok. 0,5 m, zrzut na ziemię jest zablokowany (ochrona pozycji kopania). Liczy się odstęp pod krawędzią, nie wysokość wysięgnika — nad wykopanym zagłębieniem działa nawet z nisko opuszczonym wysięgnikiem; na płaskim gruncie unieś łyżkę na chwilę, aż komunikat zniknie. Jest też górna granica: zrzut musi jeszcze trafić w ziemię. Czyli: krawędź ponad pół metra nad gruntem, ale dość nisko do zrzutu.

**Materiał jest w łyżce, ale nie da się go wysypać na ziemię?**
FS25 ogranicza materiały mogące leżeć na ziemi (height types) do 63 — gra podstawowa, mapa i wszystkie mody dzielą tę pulę, a sama podstawka zajmuje już 48 z nich; mapa i mody walczą o pozostałe 15. Gdy jest pełna, później rejestrowane materiały tracą miejsce: działają w łyżce i można je sprzedać, ale nie da się ich wysypać na teren. W logu widać wtedy `maximum number (63) of height types already registered`, a od 1.4.2 mod ostrzega dla każdej strefy, gdy dotyczy to materiału warstwy. Jedyna rada: odchudzić mody z wieloma materiałami.

**Brakuje kilku materiałów albo mają `(!)` — czy to wina mapy?**
Bardzo możliwe. Uważaj na mapy portowane z FS19 lub FS22: często rejestrują kilkanaście własnych materiałów terenu — a skoro po grze podstawowej zostaje tylko 15 miejsc, taka mapa przekracza limit **sama z siebie**, jeszcze zanim wczyta się jakikolwiek mod. Poznasz to po logu: odrzucane są materiały, które sama mapa wnosi. Zmierzony przykład: portowana mapa kamieniołomu rejestrowała 18 materiałów terenu i kilku z nich nie dostała, podczas gdy natywna mapa górnicza FS25 przy tej samej liście modów miała wszystko sprawne. Jeśli twoja mapa to port, a chcesz pełnej palety materiałów, mapa zrobiona pod FS25 jest pewniejszym wyborem.

**Czemu maszyna wysypuje tylko w jednym obszarze — albo nigdzie?**
W menu maszyny przypisany jest obszar wyjściowy: TerraFarm wysypuje wtedy tylko tam. Od 1.4.2 strefa warstw jako obszar wyjściowy działa automatycznie swobodnie (mówi o tym linia w logu). Żeby wysypywać swobodnie wszędzie, ustaw obszar wyjściowy maszyny na „nieustawiony".

**Jak wyłączyć (albo włączyć) wskaźnik głębokości?**
Naciśnij **Num 5**, gdy maszyna jest aktywna (od 1.4.1). Klawisz można zmienić: Opcje → Sterowanie → Mining Layers. Żeby wskaźnik był wyłączony od startu: `showHeightDisplay="false"` w `modSettings/FS25_MiningLayers/miningLayers.xml`.

**Czy mogę przesunąć wskaźnik, żeby nie nachodził na inne HUD-y?**
Tak — od 1.4.2 naciśnij **Num *** (klawisz do zmiany): kliknij wskaźnik, żeby go podnieść, drugi klik odkłada, prawy przycisk przywraca pozycję domyślną. Pozycja zapisuje się automatycznie (w `modSettings/FS25_MiningLayers/hud.xml`). Bez dodatkowego moda HUD.

**Czy działa na PS5 albo Xboxie?**
Nie. Mining Layers to mod skryptowy, a mody skryptowe działają tylko na PC/Mac.

**Jakie języki są dostępne?**
Polski, angielski, niemiecki i francuski — z pełnym podręcznikiem w grze.

**Czy to naprawdę darmowe?**
Tak. Darmowe pobieranie z GitHuba, bez paywalla, bez early access. Chcesz podziękować? [Postaw mi frytki](https://buymeacoffee.com/fritteplayz). 🍟

## Tłumaczenie

Ta strona i polskie teksty w grze są tłumaczone maszynowo — poprawki od native speakerów są bardzo mile widziane: załóż [issue](https://github.com/FrittePlayz/FS25_MiningLayers/issues) albo pull request (pliki językowe to zwykły XML w `l10n/`), a trafisz do creditsów.

## Błędy i pytania

[GitHub Issues](https://github.com/FrittePlayz/FS25_MiningLayers/issues) — **zawsze dołącz swój `log.txt`** (`Dokumenty/My Games/FarmingSimulator2025/log.txt`, skopiowany zaraz po wystąpieniu problemu). Zawiera pełną listę modów i właściwy błąd — bez niego zwykle nie pomożemy.

## Sponsor

Ten mod wspiera [farmersingles.de](https://www.farmersingles.de), portal randkowy dla rolników — stąd mała tablica przy rogu każdego obszaru. `sponsorSign="false"` w `miningLayers.xml` i znika; nic innego się nie zmienia.

*Mining Layers — Tommy Honold, Farmersingles.de. Projekt [FrittePlayz](https://www.youtube.com/@FrittePlayz). Darmowy i taki zostanie.*
