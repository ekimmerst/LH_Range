# LH_Range

Version: 1.1.1

A target range bar for Shamans in WoW Forever (Interface 16001). The addon uses the same bar style as LH_ExpBar and includes its own texture. LH_ExpBar is optional; when available, its bar supplies the default width, otherwise the minimap is used.

## Range display

For living, attackable targets, the first matching range wins:

| Range | Color |
| --- | --- |
| Melee Range | Gray, highest priority |
| Earth Shock | Yellow, takes priority over Flame Shock |
| Flame Shock | Yellow |
| Lightning Bolt | Green |
| Out of Range | Red |

For friendly, healable targets, the bar shows Healing Wave in green within its client-reported range (normally 40 yards), or Out of Range in red. Healing Wave is not used to check enemy range because enemies are not valid healing targets. Attackable targets always use offensive checks, even if the client also classifies them as friendly or healable.

Spell names follow the client language. Range is checked every 0.1 seconds through the client API, independently of mana and cooldowns. In locked mode, the bar is hidden without a living, attackable or healable target, and for classes other than Shaman. Targeting yourself hides the bar even while unlocked.

Melee checks use Attack and, when available, its action-bar slot. If these cannot provide a range result, the standard Classic Voodoo Charm item check (8149) provides an approximate five-yard check. For large enemies, this approximation can differ from their actual melee reach.

## Commands

- `/lh_range unlock`: show a preview and drag the bar with the left mouse button to move it. Drag the small circle below the right corner to resize width and height independently, from 50% to 200% of the default size.
- `/lh_range lock`: lock position and size and disable mouse interaction.
- `/lh_range reset`: restore the default size and position.

Position, size and lock state are saved per character in `LH_RangeDB`.

## Installation and upgrade

Place the `LH_Range` folder in your game's `Interface/AddOns` folder. It must contain `LH_Range.toc`, `LH_Range.lua` and the bundled `Media` folder. Restart WoW and enable **LH_Range** in the addon list.

When upgrading from MiniRange, replace the old folder and fully restart WoW. Do not enable both versions together. Commands now use `/lh_range`; the former `/minirange` and `/minirang` commands are no longer registered.

To retain your settings, close WoW and back up each character's `WTF/Account/<account>/<realm>/<character>/SavedVariables/MiniRange.lua` file. Copy it to `LH_Range.lua` in the same SavedVariables folder, then change `MiniRangeDB` to `LH_RangeDB` inside the copy. Migrate before first using the renamed addon; do not overwrite an existing `LH_Range.lua` containing settings you want to keep. Without migration, the addon uses its default position, size and lock state.

## Changelog

### 1.1.1 - 2026-10-21

- Renamed MiniRange to LH_Range, including its folder, Lua/TOC files, metadata, texture path, named frames, chat messages, saved-variable table and test references.
- Replaced the previous commands with `/lh_range`.
- Translated the documentation into English and added instructions for transferring saved settings.
- Updated the optional width reference to LH_ExpBar and the test support path to LH_AuraBars.

## Required core addon

Install and enable **LH_Tweaks** alongside this addon. LH_Tweaks is the shared LiteHawk configuration host and must load first. CurseForge releases must list LH_Tweaks as a required dependency so the client installs it automatically.
