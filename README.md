# LH_Range

Version: 1.4.0

A target range bar for every class in WoW Forever (Interface 16001), with additional spell-range zones for Shamans and Hunters. The addon uses the same bar style as LH_ExpBar and includes its own texture. LH_ExpBar is optional; when available, its bar supplies the default width, otherwise the minimap is used.

## Range display

For Shamans with living, attackable targets, the first matching range wins:

| Range | Color |
| --- | --- |
| Melee Range | Gray, highest priority |
| Earth Shock | Yellow, takes priority over Flame Shock |
| Flame Shock | Yellow |
| Lightning Bolt | Green |
| Out of Range | Red |

For friendly, healable targets, the bar shows Healing Wave in green within its client-reported range (normally 40 yards), or Out of Range in red. Healing Wave is not used to check enemy range because enemies are not valid healing targets. Attackable targets always use offensive checks, even if the client also classifies them as friendly or healable.

Spell names follow the client language. Range is checked every 0.1 seconds through the client API, independently of mana, focus and cooldowns. In locked mode, the bar is hidden without a suitable living target. All classes support attackable targets; Shamans additionally support friendly healing targets. Targeting yourself hides the locked bar; while unlocked, the gray LH_Range preview and resize circle remain visible.

Melee checks first use learned instant targeted strikes: Wing Clip/Mongoose Bite for Hunters, and suitable strikes for other melee classes. These checks do not depend on weapon-type tables, cooldown readiness or resources. Raptor Strike is not used: a next-swing modifier can return a positive result without checking target distance. Attack action/spellbook/spell results are accepted only when `SpellHasRange` confirms an actual range check exists.

When no reliable weapon-range check is available, the class-independent Classic five-yard item probe (8149) supplies an approximation. A positive result shows gray **Melee Range**, as requested; this fallback still estimates proximity rather than proving that the equipped weapon can hit. A negative result excludes melee; Hunters can then identify the red dead zone using Serpent Sting and the near-range probes. This supports low-level characters, including a level-11 Hunter who has learned neither Wing Clip nor Mongoose Bite, and classes without a suitable instant strike. Exact melee reach cannot be established for those characters through these APIs. Missing or restricted probes show Range unavailable.

Classes other than Shamans and Hunters show gray Melee Range, red Out of Melee Range, or gray Range unavailable. Shamans and Hunters retain their additional spell-range zones.

## Warrior range display

| Condition | Display | Color |
| --- | --- | --- |
| Rend in range (melee) | Melee Range | Gray |
| Charge in range (normally 8-25 yards) | In Range | Green |
| Neither, but an eight-yard probe confirms the target is closer than 8 yards | Dead Zone | Red |
| Eight-yard probes unreadable | Dead Zone if the target came from melee or the dead zone, otherwise Out of Range | Red |

Rend and Charge use the client's spell range, independent of stance, rage and cooldowns. Without Charge learned, only melee is shown (Out of Melee Range otherwise). Without Rend, the generic melee fallbacks apply.

## Hunter range display

The first matching condition wins:

| Condition | Display | Color |
| --- | --- | --- |
| Player in melee range | Melee Range | Gray |
| No reliable melee spell check; positive five-yard approximation in the near interval | Melee Range | Gray |
| Outside melee and Serpent Sting, with a positive eight-yard check or the Classic 35-yard fallback | Dead Zone | Red |
| Living pet has learned Charge and its pet-spellbook range check succeeds | Localized Charge name | Yellow |
| Serpent Sting range check succeeds (normally 8â€“35 yards) | In Range | Green |
| Serpent Sting reports out of range and the target is beyond the eight-yard probe | Out of Range | Red |
| Required range evidence is unavailable or restricted | Range unavailable | Gray |

As requested, Charge uses the **pet-to-target** range, not a 25-yard player-distance threshold. A pet positioned near a distant target can therefore produce Charge while the Hunter is outside Serpent Sting range. Melee and the player's dead zone take priority. This is a range indicator, not a check of Charge's focus/cooldown readiness. Pets without Charge, absent pets and dead pets do not produce a Charge indication. Pet-spellbook discovery refreshes when pet/spellbook events change; localized names cover learned Charge ranks.

The implementation uses modern `C_SpellBook.IsSpellBookItemInRange` with the Pet bank, or legacy `IsSpellInRange(slot, "pet", "target")`. Serpent Sting uses the client's actual spell range, so talent or beta changes can change its effective limit. The eight-yard probes are item IDs 34368, 33278 and 29052 as listed by LibRangeCheck. If those return no readable result, Classic item 18904 (Zorbin's Ultra-Shrinker) supplies a 35-yard maximum-range check. With a positive maximum check, negative Serpent Sting and negative melee checks identify the near dead zone rather than a far-away target. Item data for 18904 and 8149 is requested once when that API is available. No external library is bundled or required. If neither near-range probe family returns a readable result, Range unavailable is retained instead of guessing.

References: [Forever pet spellbook API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua), [LibRangeCheck probe tables](https://github.com/WeakAuras/LibRangeCheck-3.0/blob/main/LibRangeCheck-3.0/LibRangeCheck-3.0.lua).

## Native settings

Open WoW Settings > AddOns > LH Tweaks > LH Range, or type `/lh_range`. The page provides an activation checkbox, unlock/preview checkbox, width and height sliders (50â€“200%) and Reset layout. Activation defaults to on and locking defaults to locked. Everything uses the existing per-character `LH_RangeDB`, retaining saved positions and dimensions. Disabling hides the bar immediately. Reset layout preserves activation and locking; native Defaults additionally locks the bar and restores the enabled default through its checkbox.

## Commands

- `/lh_range`: open native settings.
- `/lh_range on` / `off`: enable or disable the range bar.
- `/lh_range unlock`: show a preview and drag the bar with the left mouse button to move it. Drag the small circle below the right corner to resize width and height independently, from 50% to 200% of the default size.
- `/lh_range lock`: lock position and size and disable mouse interaction.
- `/lh_range reset`: restore the default size and position.

Position, size and lock state are saved per character in `LH_RangeDB`.

## Installation and upgrade

Place the complete `LH_Range` folder in your game's `Interface/AddOns` folder, including LH_Range.toc, LH_Range.lua, Settings.lua and Media. Install and enable LH_Tweaks as well. Fully restart WoW and enable **LH Range**, grouped under **LH Tweaks** in the addon list. Version 1.2.0 requires a full restart because the TOC loads a new file and adds grouping/icon metadata.

Media/Icon.png and Media/Icon.tga are exact copies of LH_Tweaks' gold LH artwork, using Spoken's chamfered gold frame as the reference. There is no runtime Spoken dependency.

When upgrading from MiniRange, replace the old folder and fully restart WoW. Do not enable both versions together. Commands now use `/lh_range`; the former `/minirange` and `/minirang` commands are no longer registered.

To retain your settings, close WoW and back up each character's `WTF/Account/<account>/<realm>/<character>/SavedVariables/MiniRange.lua` file. Copy it to `LH_Range.lua` in the same SavedVariables folder, then change `MiniRangeDB` to `LH_RangeDB` inside the copy. Migrate before first using the renamed addon; do not overwrite an existing `LH_Range.lua` containing settings you want to keep. Without migration, the addon uses its default position, size and lock state.

## Verification

`_tests/melee_test.py` runs the existing Shaman, Hunter and settings regressions, then tests every class through range-validated Attack action, modern and legacy player spellbook checks, and direct Attack spell fallback. It reproduces the level-11 Hunter case with Attack and Raptor Strike always reporting in range, tests the approximation for every class, and switches to the exact strike check when Wing Clip is learned. It also covers missing/restricted results, pet range/lifecycle and dead-zone boundaries. Run `python LH_Range/_tests/melee_test.py` from the AddOns folder with Lupa available in `LH_Tweaks/.test-runtime`. These are simulated client results, not live measurements of every weapon.

Native rendering and real range probes require in-game checks after a full restart, particularly large NPC melee reach, the eight-yard boundary, pets with different learned Charge ranks and independently moving pets.

## Changelog

### 1.4.0 - 2026-10-21

- Added Warrior support: Rend for Melee Range, Charge for In Range, plus Dead Zone detection between them using the eight-yard item probes (35-yard probe as far-range fallback). Hamstring/Overpower are no longer used for melee checks.

### 1.3.2 - 2026-10-21

- Display Melee Range for both exact and approximate near-range checks, and In Range for a successful Serpent Sting check. Range logic, Charge and Dead Zone are unchanged.

### 1.3.1 - 2026-10-21

- Fixed unconditional Melee Range results from next-swing Raptor Strike and Attack checks without real range validation. Use learned instant strikes and require range metadata before accepting Attack results.
- Added the class-independent, explicitly approximate Within ~5 yd display when exact weapon reach is unavailable. This restores other Hunter range zones at low levels without claiming an exact melee boundary.
- Added regressions for the reported level-11 Hunter case, spell learning, all-class approximation and modern range metadata.

### 1.3.0 - 2026-10-21

- Added melee range display for every class using client Attack action/spellbook checks, without weapon-type restrictions. No Attack action-bar button is required.
- Hunters use Raptor Strike before generic Attack checks to avoid switching to Melee Range too early. Removed the approximate five-yard item fallback.
- Added all-class regressions for modern/legacy player spellbooks, action slots, direct spell fallback and unavailable range data. Existing Hunter, Shaman, settings and LH_ExpBar integration simulations pass. Live weapon reach still requires in-game verification; existing installations can use `/reload`.

### 1.2.2 - 2026-10-21

- Keep the gray preview bar and resize handle visible while unlocked when targeting yourself. Locked self-target behavior still hides the bar. Covered by the Shaman regression and Hunter/settings suite.

### 1.2.1 - 2026-10-21

- Fixed the dead-zone path when later-expansion eight-yard item probes provide no usable data. Added the Classic 35-yard maximum probe together with a one-time item-data request; Serpent Sting and melee checks disambiguate close and distant targets.
- Added regressions with every eight-yard probe unavailable, the modern item API, restricted/failed maximum probes and eight-/35-yard boundaries. Hunter, Shaman and LH_ExpBar integration simulations pass; live confirmation of this fallback remains pending. Existing installations can load this fix with `/reload`.

### 1.2.0 - 2026-10-21

- Added native LH Range settings under LH Tweaks, activation, width/height sliders and existing unlock/reset controls, plus the shared LH icon and native AddOn grouping.
- Added Hunter support for Serpent Sting, learned pet Charge using the pet's range, and a red dead zone between melee and the ranged minimum.
- Added guarded range results and an unavailable state for missing/restricted Hunter range data. Existing Shaman priority and friendly-healing checks remain intact.

### 1.1.1 - 2026-10-21

- Renamed MiniRange to LH_Range, including its folder, Lua/TOC files, metadata, texture path, named frames, chat messages, saved-variable table and test references.
- Replaced the previous commands with `/lh_range`.
- Translated the documentation into English and added instructions for transferring saved settings.
- Updated the optional width reference to LH_ExpBar and the test support path to LH_AuraBars.

## Required core addon

Install and enable **LH_Tweaks** alongside this addon. LH_Tweaks is the shared LiteHawk configuration host and must load first. CurseForge releases must list LH_Tweaks as a required dependency so the client installs it automatically.
