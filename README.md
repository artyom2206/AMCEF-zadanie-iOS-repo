# AMCEF-zadanie-iOS-repo

<table>
<tr>
<td>

## Úvod
Toto zadanie je jednoduchá SwiftUI aplikácia, ktorá zobrazuje verejne dostupné prístupové body (APIs). Využíva dáta poskytnuté cez [public-api](https://github.com/davemachado/public-api) a vie zobrazovať a filtrovať APIs podľa rôznych kritérií.


## Zadanie
Bolo mi zadané vytvoriť aplikáciu, ktorá:
- Zobrazuje dáta z endpointu `/entries`.
- Zobrazuje prvých 40 výsledkov pomocou tableView alebo collectionView.
- Každá bunka obsahuje názov API, popis, kategóriu, informáciu o HTTPS a ikonu zámku, ak vyžaduje autentifikáciu.
- Po tapnutí na bunku presmeruje na URL API vo vnorenom webview.
- Umožňuje online vyhľadávanie vo všetkých dostupných prístupových bodoch podľa názvu alebo popisu.
- Viditeľné asynchrónne operácie (loading stav).
- Zobrazuje prázdny stav (žiadne výsledky).
- Filtruje podľa kategórií z endpointu `/categories` bez obmedzenia počtu výsledkov.
- Prvých 40 výsledkov ukladá do db a vie zobraziť v offline režime.
- Aspoň jednu z technológií `Combine`/`Rx` a `SwiftUI`.


## Použité technológie:
- **SwiftUI**
- **Combine**
- **Core Data**
- **XCTest**

</td>
<td>

<img src="zadanie_preview.gif" height="600" width="370" alt="Popis GIF">

</td>
</tr>
</table>


## Technické problémy
Hneď na začiatku som narazil na problém s dostupnosťou dát z [public-api](https://github.com/davemachado/public-api). Keďže to nie je funkčné, aby som bol schopný dokončiť zadanie použil som web scraping na vytiahnutie všetkých dát. Ďalej som zvažoval vytvorenie vlastného REST API, no najjednoduchšie pre mňa bolo použiť Firebase, kedže podporuje jednoduché server-side sortovanie a filtrovanie json súborov.
- [Všetky prístupy (entries)](https://json-rest-api-79fe3-default-rtdb.europe-west1.firebasedatabase.app/entries.json)
- [Kategórie (categories)](https://json-rest-api-79fe3-default-rtdb.europe-west1.firebasedatabase.app/categories.json)

## Štruktúra aplikácie

Aplikácia pozostáva z dvoch hlavných častí: **Dashboard** a **List**.

### Dashboard
Dashboard slúži ako úvodná obrazovka aplikácie, kde sa zobrazuje náhodne vybrané API. Pod touto náhodnou položkou sú zobrazené všetky dostupné APIs, usporiadané podľa kategórií. Vzhľadom na to, že aplikácia je vyvíjaná vo SwiftUI, tento dashboard funguje ako alternatíva k tradičnému `CollectionView` v UIKit.

### List
Hlavnou časťou aplikácie je List, ktorý je alternatívou `TableView`. Táto časť obsahuje všetky zadané funkcionality.

## Obmedzenia
### Online vyhľadávanie
Použitie Firebase prináša určité obmedzenia v možnostiach vyhľadávania. Neumožňuje vyhľadávanie podreťazcov, ako to robí originálne [public-api](https://github.com/davemachado/public-api). V dôsledku toho aplikácia sťahuje všetky dostupné výsledky a vyhľadávanie podľa názvu alebo popisu sa deje priamo v aplikácii. Naproti tomu, vyhľadávanie podľa kategórií je spravované priamo cez REST API.

## Spustenie projektu
Pre spustenie aplikácie v Xcode:
1. Naklonujte repozitár.
2. Otvorte `.xcworkspace` súbor v Xcode.
3. Vyberte cieľové zariadenie a spustite projekt.
4. Pre overenie kvality kódu môžete spustiť integrované XCTesty (`Command+U`).

