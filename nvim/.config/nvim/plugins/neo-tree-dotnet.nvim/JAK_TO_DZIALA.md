# Jak działają pluginy Neovima i źródła Neo-tree

Ten przewodnik wyjaśnia działanie `neo-tree-dotnet.nvim` na jego rzeczywistym kodzie.
Zacznij od rozdziałów 1–4, potem przejdź ścieżkę pojedynczego kliknięcia z rozdziału 6.
Nie musisz znać całego Neovima, żeby zacząć zmieniać ten plugin.

## 1. Plugin to katalog z kodem

Plugin Neovima nie wymaga osobnego procesu ani serwera. W naszym przypadku jest
katalogiem z plikami Lua, które wykonują się wewnątrz edytora.

Neovim ma opcję `runtimepath`: listę katalogów, w których szuka rozszerzeń,
modułów Lua, dokumentacji i innych zasobów. Możesz ją zobaczyć:

```vim
:set runtimepath?
```

Niektóre podkatalogi mają ustalone znaczenie:

| Katalog | Do czego służy |
| --- | --- |
| `plugin/` | Pliki inicjalizacyjne wykonywane przy ładowaniu pluginu |
| `lua/` | Moduły ładowane przez `require(...)` |
| `ftplugin/` | Ustawienia lub zachowanie dla konkretnego typu pliku |
| `after/` | Późniejsze nadpisania ustawień ładowanych standardowo |
| `doc/` | Dokumentacja w formacie pomocy `:help` |

Nasze rozszerzenie używa `plugin/` oraz `lua/`. README i ten przewodnik są zwykłymi
plikami Markdown; nie stają się automatycznie tematami `:help`.

W [plugin/neo-tree-dotnet.lua](plugin/neo-tree-dotnet.lua) rejestrujemy komendy,
na przykład:

```lua
vim.api.nvim_create_user_command("NeotreeDotnetPanelToggle", function()
  require("neo-tree-dotnet").toggle_panel()
end, { desc = "Hide/show Neo-tree, remembering the view in this tab" })
```

Rejestracja komendy nie otwiera panelu. Dopiero wykonanie
`:NeotreeDotnetPanelToggle` uruchomi przekazaną funkcję.

Na początku tego pliku jest strażnik `vim.g.loaded_neo_tree_dotnet`. Zapobiega
ponownej rejestracji komend przy ponownym wykonaniu pliku. To flaga w pamięci
bieżącego procesu Neovima, a nie plik na dysku.

Więcej o układzie pluginów: `:help write-plugin` oraz
[dokumentacja tworzenia rozszerzeń Neovima](https://neovim.io/doc/user/usr_41/).

## 2. Co dokładnie robi `require`

Wywołanie:

```lua
local dotnet = require("neo-tree-dotnet")
```

pozwala Neovimowi znaleźć moduł w `lua/neo-tree-dotnet.lua` lub
`lua/neo-tree-dotnet/init.lua`. W naszym pluginie istnieje drugi z tych plików.
Kropki w nazwie modułu oznaczają kolejne katalogi:

```lua
require("neo-tree.sources.dotnet_solution")
-- lua/neo-tree/sources/dotnet_solution/init.lua
```

Typowy moduł zwraca tabelę z funkcjami:

```lua
local M = {}

function M.hello()
  vim.notify("Cześć!")
end

return M
```

`M` to zwykła nazwa zmiennej, nie specjalne słowo Lua. `return M` udostępnia tę
tabelę kodowi, który wywołał `require`. Funkcja zdefiniowana przez `local function`
pozostaje prywatna dla pliku, o ile jej jawnie nie zwrócisz.

Lua zapamiętuje załadowany moduł w `package.loaded`. Kolejne `require` zwykle
zwraca tę samą tabelę, zamiast wykonywać cały plik ponownie. Dlatego zapisanie
zmiany na dysku nie aktualizuje automatycznie działającego pluginu.

Podczas nauki najprościej uruchomić Neovima ponownie. Samo wyczyszczenie jednego
wpisu `package.loaded` nie usuwa starych autocmdów, callbacków ani obiektów widoku.

Przydatna pomoc: `:help lua-guide-modules` i
[Lua w Neovimie](https://neovim.io/doc/user/lua/).

## 3. Gdzie w tym wszystkim jest lazy.nvim

Neovim wykonuje kod pluginu. **lazy.nvim** zarządza tym, skąd go wziąć i kiedy go
załadować. W Twojej konfiguracji ten plugin jest lokalną zależnością Neo-tree:

```lua
dependencies = {
  {
    dir = vim.fn.stdpath("config") .. "/plugins/neo-tree-dotnet.nvim",
    name = "neo-tree-dotnet.nvim",
  },
}
```

`dir` wskazuje kod na dysku. Nie trzeba publikować go na GitHubie. `dependencies`
pozwala lazy.nvim załadować rozszerzenie razem z pluginem, który go potrzebuje.
Szczegóły tych pól są w [dokumentacji specyfikacji lazy.nvim](https://lazy.folke.io/spec).

Ważne rozróżnienie:

- `~/.config/nvim/lua/plugins/neo-tree.lua` jest **Twoją konfiguracją** dla lazy.nvim.
- `plugin/neo-tree-dotnet.lua` w tym katalogu jest **kodem inicjalizacyjnym pluginu**.

`lua/plugins/` nie jest specjalnym katalogiem Neovima. Twoje lazy.nvim odczytuje
go dlatego, że w konfiguracji masz import modułów `plugins`.

Również `setup()` jest konwencją bibliotek, a nie magiczną funkcją Lua.
W tym projekcie wywołujesz `require("neo-tree").setup(...)`. Nasze rozszerzenie
nie wymaga osobnego `require("neo-tree-dotnet").setup()`.

## 4. Co dostajemy od Neo-tree

Neo-tree potrafi wyświetlać różne **źródła** danych w podobnym panelu:

- `filesystem`: katalogi i pliki na dysku;
- `buffers`: otwarte bufory;
- `git_status`: pliki wynikające ze stanu Git;
- `dotnet_solution`: logiczną strukturę solucji z naszego pluginu.

Źródło odpowiada za znaczenie danych i operacje na nich. Neo-tree zapewnia między
innymi okno, obsługę mapowań, renderowanie drzewa oraz selektor źródeł. Korzysta
przy tym z `nui.nvim`; nie rysujemy osobnego interfejsu od zera.

W konfiguracji rejestrujemy nazwę:

```lua
sources = { "filesystem", "buffers", "git_status", "dotnet_solution" }
```

Neo-tree odnajduje wtedy moduł
[sources/dotnet_solution/init.lua](lua/neo-tree/sources/dotnet_solution/init.lua).
Choć plik leży w przestrzeni nazw `neo-tree`, należy do naszego katalogu pluginu.
Nie zmieniamy plików zainstalowanego Neo-tree.

W tym module:

- `name` identyfikuje źródło;
- `default_config` udostępnia domyślne opcje;
- `setup(config)` instaluje obsługę zdarzeń;
- `navigate(state, dir, file_to_reveal, callback)` przygotowuje widok.

To umowa z Neo-tree, a nie ze wszystkimi pluginami Neovima. Zewnętrzne źródła
opisuje również [wiki Neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim/wiki/External-Sources).

## 5. Mapa plików po uporządkowaniu

W tabeli ścieżki są względem katalogu tego pluginu.

| Plik | Odpowiedzialność |
| --- | --- |
| `plugin/neo-tree-dotnet.lua` | Rejestracja komend `:NeotreeDotnet...` |
| `lua/neo-tree-dotnet/init.lua` | Otwieranie panelu, zmiana źródła, pamięć widoku dla karty |
| `lua/neo-tree/sources/dotnet_solution/init.lua` | Połączenie z Neo-tree, wybór solucji, zdarzenia edytora |
| `lua/neo-tree/sources/dotnet_solution/defaults.lua` | Opcje, domyślne skróty i deklaracje rendererów |
| `lua/neo-tree/sources/dotnet_solution/commands.lua` | Zachowanie poleceń wykonywanych z drzewa |
| `lua/neo-tree/sources/dotnet_solution/components.lua` | Ikony, nazwy i grupy kolorów |
| `lua/neo-tree-dotnet/view.lua` | Model pojedynczego widoku, rozwijanie, odświeżanie, wskazywanie pliku |
| `lua/neo-tree-dotnet/solution.lua` | Zamiana `.sln` lub `.slnx` na strukturę logiczną |
| `lua/neo-tree-dotnet/xml.lua` | Odczyt struktury XML dla `.slnx` |
| `lua/neo-tree-dotnet/project.lua` | Budowanie węzłów plików i zależności projektu |
| `lua/neo-tree-dotnet/msbuild.lua` | Asynchroniczne uruchomienie MSBuild i odczyt JSON |
| `lua/neo-tree-dotnet/tree.lua` | Wspólne sortowanie i wyszukiwanie ścieżki w drzewie |
| `lua/neo-tree-dotnet/path.lua` | Ścieżki, odczyt pliku i wyszukiwanie solucji w katalogach nadrzędnych |

Ten podział ma praktyczny cel. Zmieniając ikonę, nie musisz rozumieć MSBuild.
Zmieniając sposób uruchomienia MSBuild, nie dotykasz skrótów ani kursora.

## 6. Co dzieje się po otwarciu solucji

Przykład komendy:

```vim
:NeotreeDotnet /sciezka/do/MyApp.slnx
```

Przepływ wygląda tak:

```text
komenda Neovima
  → neo-tree-dotnet.open(...)
  → neo-tree.command.execute({ source = "dotnet_solution", ... })
  → source.navigate(...)
  → View:begin(...) i View:load(...)
  → solution.load(...): plik solucji → model węzłów
  → View:render(...)
  → renderer.show_nodes(...): model → widoczne drzewo Neo-tree
```

Model składa się ze zwykłych tabel Lua. Uproszczony przykład pliku:

```lua
{
  id = "project::Api::file::Program.cs",
  name = "Program.cs",
  path = "/repo/Api/Program.cs",
  type = "file",
  extra = { kind = "file" },
}
```

`name` to napis dla użytkownika. `path` to ścieżka, którą można otworzyć.
`id` jest tożsamością węzła w drzewie. Nie są zamienne: ten sam linkowany plik
może występować w więcej niż jednym projekcie i potrzebuje odrębnych węzłów.

Projekt lub folder ma `children`. Projekt zaczyna z `loaded = false`:
znamy jego miejsce w solucji, ale jeszcze nie odczytaliśmy zawartości.

Po naciśnięciu `Enter` na projekcie:

1. Neo-tree uruchamia `commands.open(state)`.
2. Polecenie widzi węzeł katalogowy i wywołuje `toggle_node`.
3. `View` prosi `project.load(...)` o dzieci.
4. Po otrzymaniu wyniku zapisuje je w modelu i renderuje drzewo.

To **lazy loading**, czyli ładowanie dopiero wtedy, kiedy dane są potrzebne.
Przy dużej solucji nie trzeba od razu skanować wszystkich katalogów.

## 7. Bufor, okno, karta i stan

Te pojęcia oznaczają różne rzeczy:

| Pojęcie | Znaczenie |
| --- | --- |
| Bufor | Zawartość pliku albo specjalnej powierzchni, np. drzewa |
| Okno | Obszar edytora pokazujący bufor; ma własny kursor |
| Karta (`tabpage`) | Zestaw okien |
| Stan źródła Neo-tree | Dane danego widoku: konfiguracja, okno, bufor, drzewo |

Bufor może istnieć bez widocznego okna. Dlatego sam fakt, że zapisaliśmy `bufnr`,
nie wystarcza, żeby uznać panel za otwarty.

Nasza klasa `View` trzyma dane rozszerzenia w jednym obiekcie `state._dotnet`:
model `root`, wybraną `solution_file`, oczekujący plik `reveal_file`, numer
`generation` oraz oczekujące rozwinięcia. To szczegół wewnętrzny, nie opcje
przeznaczone do ustawiania w konfiguracji.

Lua nie wymaga klasy w stylu C#. `View.new(state)` tworzy tabelę, a
`setmetatable(..., View)` i `View.__index = View` pozwalają jej korzystać
z metod zdefiniowanych na `View`.

```lua
view:load(file, true)
-- odpowiada:
view.load(view, file, true)
```

Dwukropek przekazuje obiekt jako pierwszy argument `self`, podobnie do roli
`this` w metodach C#.

Ostatni widok panelu zapisujemy osobno w `vim.t.neo_tree_dotnet_panel`.
`vim.t` oznacza zmienne bieżącej karty; `vim.g` oznacza zmienne globalne.
Wybór `Solution` w jednej karcie nie powinien zmieniać preferencji drugiej.
Ta pamięć działa w bieżącej sesji Neovima. Nie jest zapisywana na dysku.

## 8. Dlaczego są dwa różne „toggle”

W [głównym module](lua/neo-tree-dotnet/init.lua) są dwie osobne operacje:

```lua
require("neo-tree-dotnet").toggle_panel() -- ukryj / pokaż ten sam widok
require("neo-tree-dotnet").toggle()       -- zmień Files ↔ Solution
```

U Ciebie pierwsza jest pod `Spacja e` i `Spacja ee`, druga pod `Tab` w panelu
oraz `Spacja Shift+E`. To ustawienia Twojego configu; plugin nie narzuca globalnie
tych skrótów wszystkim użytkownikom.

Zapamiętujemy faktycznie pokazywany panel przy zdarzeniach otwarcia i zamknięcia.
Dzięki temu uwzględniamy również kliknięcie selektora oraz automatyczne zamknięcie
po otwarciu pliku. Poleganie tylko na ostatniej wykonanej komendzie nie daje
niezależnego stanu dla każdej karty.

Był też drugi, osobny problem: spacja jest domyślnym skrótem rozwijania węzła,
a u Ciebie jednocześnie klawiszem `leader`. Dlatego w `defaults.lua` mamy:

```lua
["<space>"] = { "toggle_node", nowait = false }
```

`nowait = false` pozwala Neovimowi poczekać na resztę sekwencji. Przy `true`
spacja mogła od razu wykonać akcję folderu i przechwycić początek `Spacja ee`.
Gdy jeden skrót jest początkiem drugiego, na przykład `Spacja e` i `Spacja ee`,
czas rozstrzygnięcia krótszego skrótu zależy również od `timeout` i `timeoutlen`.

## 9. Automatyczne wskazywanie aktualnego pliku

Do reagowania na edytor służą **autocommands**, czyli funkcje uruchamiane przez
zdarzenia. W źródle rejestrujemy:

- `BufEnter` — wejście do bufora;
- `TabEnter` — wejście do karty;
- `BufWritePost` — zakończenie zapisu pliku.

Przy zmianie bufora pobieramy jego nazwę. Specjalne bufory, takie jak terminal
lub sam panel Neo-tree, nie są traktowane jak zwykły plik do wskazania.
Następnie `View:follow(file)`:

1. Sprawdza, czy śledzenie jest włączone i czy widok jest widoczny w bieżącej karcie.
2. Szuka pliku w już wczytanym modelu.
3. W razie potrzeby ładuje brakujące katalogi albo projekt.
4. Rozwija przodków znalezionego węzła i ustawia kursor **w oknie drzewa**.

Nie przenosi aktywnego okna z edytora do panelu. To różnica między „wskaż plik
w drzewie” a „przejdź fokusem do drzewa”. Ukryty panel pozostaje ukryty.

Opcja sterująca tym zachowaniem:

```lua
dotnet_solution = {
  follow_current_file = { enabled = true },
}
```

Po zapisach stosujemy 150 ms opóźnienia. Kolejne zapisy unieważniają poprzednie
oczekujące odświeżenie. To **debounce**: seria zdarzeń prowadzi do jednego
odświeżenia po ostatnim z nich, a nie do wielu pełnych przebudów drzewa.

## 10. Filesystem a MSBuild

`project.load(node, options, callback)` jest wspólnym wejściem do ładowania dzieci.
Widok otrzymuje listę węzłów albo błąd, niezależnie od sposobu zdobycia danych.

W trybie `filesystem` korzystamy z `vim.uv.fs_scandir` i czytamy jeden fizyczny
katalog. To działa szybko i nie wymaga SDK, ale plik wykluczony z kompilacji nadal
może być pokazany, ponieważ istnieje na dysku.

W trybie `msbuild` odczytujemy ocenione elementy projektu, używając
`dotnet msbuild` z opcjami `-getItem` i `-getProperty`. Nie uruchamiamy celu build
ani restore. `msbuild.lua` zwraca odczytany JSON, a `project.lua` zamienia go
na węzły, uwzględniając m.in. `Link` oraz odwołania do projektów i pakietów.

Proces uruchamia `vim.system` z listą argumentów. Nie składamy polecenia powłoki
z ręcznie cytowanymi ścieżkami. Wynik trafia do callbacku przez
`vim.schedule_wrap`, żeby dalsze operacje edytora wykonały się w jego głównej pętli.

W czasie oczekiwania użytkownik może zamknąć panel, odświeżyć widok albo przejść
do innej solucji. Dlatego każde nowe `View:begin(...)` zwiększa `generation`.
Callback zapamiętuje generację z chwili uruchomienia. Jeśli po zakończeniu procesu
numer już się nie zgadza, wynik jest pomijany — nie może nadpisać nowszego widoku.
To unieważnienie wyniku, nie fizyczne przerwanie już uruchomionego procesu.

## 11. Jak bezpiecznie eksperymentować

Najlepsza kolejność czytania kodu:

1. `plugin/neo-tree-dotnet.lua`: jakie komendy istnieją?
2. `lua/neo-tree-dotnet/init.lua`: co te komendy robią z panelem?
3. `sources/dotnet_solution/defaults.lua` i `commands.lua`: jak działa `Enter`?
4. `solution.lua`: jak wygląda model danych?
5. `view.lua`: jak model zmienia się po rozwinięciu lub zmianie pliku?
6. `project.lua` i `msbuild.lua`: skąd pochodzą dzieci projektu?
7. Źródłowy `sources/dotnet_solution/init.lua`: jak zdarzenia łączą całość?

Małe ćwiczenia:

- Zmień ikonę projektu w `components.lua`. Sprawdź, czy reszta zachowania pozostaje taka sama.
- Dodaj w konfiguracji Neo-tree mapowanie `gs` pod innym klawiszem.
- Zmień `excluded_dirs`, np. dopisz katalog `coverage`.
- Porównaj `filesystem` i `msbuild` na projekcie zawierającym `Compile Remove`.
- Otwórz dwie karty Neovima, wybierz w nich różne źródła, zamknij i ponownie otwórz panel.

Do diagnozowania mapowania użyj:

```vim
:verbose nmap <Space>e
:verbose nmap <Space>ee
:verbose nmap <Space>
```

Ostatnią komendę wykonaj wewnątrz panelu, bo mapowanie spacji jest lokalne dla bufora.
Sprawdź również `:messages` po błędzie. Nie każde `module not found` oznacza błąd
Lua — może oznaczać, że katalog pluginu nie znajduje się na `runtimepath`.

## 12. Testy i dalszy rozwój

Z katalogu pluginu uruchom:

```sh
make test
```

Potrzebujesz Neovima, .NET SDK 8+ oraz zainstalowanych zależności Neo-tree.
Jeśli nie znajdują się pod `stdpath("data")/lazy`, wskaż ich wspólny katalog:

```sh
NEOTREE_TEST_DEPS=/sciezka/do/katalogu/z/pluginami make test
```

`tests/minimal_init.lua` przygotowuje osobne środowisko bez Twojego `init.lua`.
`tests/run.lua` używa prawdziwego Neo-tree i fixture'ów z `tests/fixtures/`.
Sprawdzamy między innymi otwieranie plików, śledzenie kursora, przełączanie źródeł,
zapamiętywanie widoku, opóźnione wyniki MSBuild i konflikt spacji ze skrótami.

Dodając funkcję, najpierw wybierz moduł, który jest właścicielem danego zachowania.
Nie dodawaj operacji na oknie do parsera `.sln`; nie uruchamiaj MSBuild z funkcji
rysującej ikonę. Staraj się, by zmiana jednego zachowania wymagała zrozumienia
jednego małego obszaru kodu, a test opisywał rezultat widoczny dla użytkownika.

Plugin ma świadome ograniczenia opisane w [README](README.md): nie jest pełnym
systemem projektowym Visual Studio, nie wykonuje refaktoryzacji namespace'ów
i nie obserwuje automatycznie wszystkich zmian plików wykonanych poza Neovimem.
