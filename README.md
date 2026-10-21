# MiniRange

Reichweitenbalken für WoW Forever (Interface 16001), zunächst für Schamanen.
Eigenständiges AddOn mit dem Balkenstil von MiniExpBar.

- Melee Range: grau, höchste Priorität.
- Earth Shock: gelb, sobald in Reichweite, mit Vorrang vor Flame Shock.
- Flame Shock: gelb, sobald in Reichweite.
- Lightning Bolt: grün, wenn nur dieser Zauber in Reichweite ist.
- Out of Range: rot.

Bei freundlichen, heilbaren Zielen zeigt der Balken Healing Wave in Grün innerhalb
seiner 40-Yard-Reichweite und Out of Range in Rot außerhalb. Die Prüfung erfolgt
über die tatsächliche Zauberreichweite des Clients. Healing Wave wird nicht als
40-Yard-Prüfung für Gegner verwendet, da der Heilzauber dort kein gültiges Ziel hat.
Angreifbare Ziele zeigen stets die offensiven Reichweiten, auch wenn sie zugleich
als freundlich beziehungsweise heilbar eingestuft werden.

Die Zaubernamen werden in der Sprache des Clients angezeigt. Reichweiten werden
alle 0,1 Sekunden über die Client-API geprüft, unabhängig von Mana und Cooldowns.
Ohne lebendes, angreifbares oder heilbares Ziel und bei anderen Klassen ist der Balken verborgen.
Beim Anvisieren des eigenen Charakters bleibt der Balken auch im entsperrten Zustand verborgen.

`/minirange unlock`: Vorschau einblenden und Balken mit der linken Maustaste
verschieben. Den kleinen Kreis rechts unten ziehen, um Breite und Höhe unabhängig
voneinander zu ändern (50–200 % der Standardgröße).

`/minirange lock`: Position und Größe fixieren, Mausinteraktion deaktivieren.
`/minirange reset`: Standardgröße und Position wiederherstellen.
`/minirang` funktioniert ebenfalls als Alias. Einstellungen gelten pro Charakter.

Die Nahkampfprüfung verwendet Attack und gegebenenfalls dessen Aktionsleistenplatz.
Falls diese keine Reichweite liefern, dient der übliche Classic-Gegenstandscheck
mit Voodoo Charm (8149) als 5-Yard-Näherung. Bei großen Gegnern kann diese Näherung
von deren tatsächlicher Nahkampfreichweite abweichen.

Nach Installation das Spiel neu starten, damit das neue AddOn erkannt wird.
