mpackage = [[Party Info]]
author = [[Me]]
description = [[Party formation HUD for Icesus. Gags the party-channel vitals spam from the main console and renders each member as a compact HP / SP / EP block placed in a fixed 3x3 grid mirroring Icesus party formation positions (1,1 .. 3,3). The panel sits between the icesus.core banner and the Elemental Bonds buff bar.

### Description

The Icesus party channel reports every member's vitals continuously (`<party>: Name >> HP:[...] SP:[...] EP:[...]`). In a full party this is thousands of lines that bury actual party chat. This package:

* Gags those vitals lines from the main console (party CHAT, e.g. `Name [party]: text`, and buff `reports` lines are left untouched).
* Places each member in a 3x3 grid cell matching their formation position. Front row (row 1) is drawn at the top.
* Reads positions from formation messages (`steps`/`moves`/`guides to position R,C`) and from the `ps` party-status table, which also supplies the leader marker and front-row (O/C/D) tag.
* Appears only while you are in a party; hides when you leave/are kicked/party disbands. (Add the exact kick/disband trigger text in the 'leave events' trigger group — two disabled stubs are included.)

Note: the party feed only ever carries SP, never PSP, so the middle bar is always SP.

### Usage

`> ps`              -- run party status to refresh positions/roles
`> party clear`     -- forget all tracked members
`> party width 360`  -- set panel width in pixels
`> party height 220` -- set panel height in pixels (floats over console)

Requires icesus.core (Icesus Core) for banner-fitting and palette. Auto-anchors to the left edge of the Elemental Bonds buff bar when present.

### See Also

* Icesus: https://icesus.org
* Mudlet: https://wiki.mudlet.org
]]
version = [[2.3]]
created = "2026-06-17T06:10:00+02:00"
