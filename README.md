<h1 style="color: #d9a94b;">LH Range</h1>

<p>LH Range shows melee range and configurable spell-range zones for your target on one compact, movable bar.</p>

<h2 style="color: #73c9c4;">What it shows</h2>

<ul>
  <li>Melee range for every class.</li>
  <li>A text-free player health bar sits directly above the range bar at half its height. It is green from 50% health, orange from 25%, and red below 25%.</li>
  <li>In melee range, a live bar for the active non-Mana resource replaces the range label (for example Rage, Energy, Focus, Runic Power or Fury). The current value appears on the bar. Gained resource briefly glows green; spent resource glows red.</li>
  <li>Built-in spell-range zones for Shamans, Hunters and Warriors, plus configurable ability checks for every class.</li>
  <li>When the ability used for the current range cue is on cooldown, its remaining time appears in parentheses beside the centered range label. The bar dims during cooldown and flashes briefly when the ability becomes available.</li>
  <li>A Dead Zone cue when the target is beyond melee and too close for the configured ranged ability, where the client provides a usable range check.</li>
  <li>A movable, resizable bar that can match the width of LH ExpBar or the minimap.</li>
</ul>

<h2 style="color: #c78be6;">Class spells</h2>

<p>Open <strong>Options → AddOns → LH Tweaks → LH Range</strong>. The <strong>Class spells</strong> section contains fields directly on the settings page for melee and the 8, 10, 20, 30 and 40 yard tiers. Enter an ability name in your client's language, such as <strong>Serpent Sting</strong> for a Hunter's 30-yard tier or <strong>Charge</strong> for a Warrior's 20-yard tier. Spell IDs also work, but are not required.</p>

<p>Press Enter or leave a field to save it. The tier labels help order the checks, while the game determines each ability's actual range. The nearest assigned ability that passes its range check is shown. Leave melee empty for automatic melee detection, or enter an ability such as <strong>Wing Clip</strong>. Empty distance fields are skipped.</p>

<p>Editing a field replaces the built-in checks for this character. <strong>Clear spells</strong> removes your custom assignments and restores the built-in behavior. Assignments are saved per character and are excluded from settings profiles. Existing class-wide assignments are copied to each character the first time it loads this version.</p>

<h2 style="color: #c78be6;">Position and size</h2>

<p>Turn the bar on, unlock its preview and drag it where it is useful. The small handle below its right edge changes its size; sliders and a layout reset are available too. Lock it when you're done. Bar visibility, position and size are saved per character.</p>

<p>The Target range settings also let you show or hide the player health bar and the resource bar that replaces the melee-range label. Both choices are saved per character.</p>

<h2 style="color: #c78be6;">Settings profiles</h2>

<p>Choose a character under <strong>Use settings from</strong> to share the range bar's position, size, lock state, visibility, health bar and resource bar choices. LH Tweaks can apply its selected source to all LH addons. Melee and yard spell assignments remain per character, even when another character supplies the display settings. <strong>This character</strong> restores your own display choices.</p>

<h2 style="color: #73c9c4;">More LH addons</h2>

<p>Choose only the pieces you want. Most companion addons require LH Tweaks; LH NameplateQuestInfo also works without it.</p>

<ul>
  <li><strong>LH AuraBars:</strong> Compact bars for buffs, debuffs and spell cooldowns.</li>
  <li><strong>LH CooldownPulse:</strong> Flashes an ability icon when its cooldown finishes.</li>
  <li><strong>LH ExpBar:</strong> A minimal experience bar with rested XP.</li>
  <li><strong>LH HideMe:</strong> Hides selected parts of the default UI, individually or all at once.</li>
  <li><strong>LH JobsDone:</strong> Plays the Warcraft peasant voice when a quest is ready to turn in.</li>
  <li><strong>LH MailBags:</strong> Opens your bags at the mailbox, with optional closing.</li>
  <li><strong>LH MP5:</strong> Shows an estimated five-second timer on the player mana bar.</li>
  <li><strong>LH NameplateQuestInfo:</strong> Adds quest markers and objective progress to nameplates.</li>
  <li><strong>LH NameplateThreatColors:</strong> Colors Blizzard nameplates by threat and role.</li>
  <li><strong>LH PetStats:</strong> Shows hunter pet loyalty beside the pet portrait.</li>
  <li><strong>LH BuffReminders:</strong> Reminds you when selected class buffs are missing.</li>
  <li><strong>LH Skills:</strong> Shows profession ranks in a movable compact bar.</li>
  <li><strong>LH Stats:</strong> Shows money, free bag slots and remaining ammo below the minimap.</li>
  <li><strong>LH SwingTimer:</strong> Shows main-hand and ranged swing timers below the player cast bar.</li>
  <li><strong>LH TinyDPS:</strong> Shows built-in damage meter data in a compact separate window.</li>
  <li><strong>LH Tweaks:</strong> Provides the shared settings hub plus chat, positioning, merchant and fishing tweaks.</li>
</ul>

<h2 style="color: #d9a94b;">Installation and feedback</h2>

<p><strong>LH Tweaks is required</strong> and must be installed alongside LH Range. LH ExpBar is optional. This began as a simple range cue for my own characters; please tell me in the CurseForge comments if a class ability or range zone needs attention.</p>

<h2 style="color: #73c9c4;">Changelog</h2>

<p><strong>1.6.0 - Forever and Retail</strong></p>

<ul>
  <li>Added character settings profiles for the bar and its display options.</li>
  <li>Melee and yard spell assignments are now saved per character. Existing class assignments are copied on first load and stay outside profiles.</li>
</ul>

<p><strong>1.5.2 - Forever and Retail</strong></p>

<ul>
  <li>Added an optional player health bar above the range bar and separate controls for the health and melee resource displays.</li>
  <li>Added a live non-Mana resource bar in melee range for any class with an active resource, with brief color feedback when resource is gained or spent.</li>
  <li>Show the range-check ability's remaining cooldown beside the range cue, dim the bar during cooldown, and flash it when the ability becomes available.</li>
</ul>

<p><strong>1.5.1 - Forever</strong></p>

<ul>
  <li>In melee range, Warriors, Rogues and Druids can see their current Rage or Energy in place of the range label when that resource is active.</li>
</ul>

<hr>
<p><sup>*</sup> Implemented with the help of Codex and GPT-6-SOL. Some class or race combinations may still need work; please report anything you notice.</p>
