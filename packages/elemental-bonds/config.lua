mpackage = [[Elemental Bonds]]
author = [[Me]]
description = [[Templar elemental bond manager for Icesus.

### Description

Tracks your four elemental bonds (air / water / fire / earth), your recorded per-element maximums, your live active buffs (parsed from `templar_command list all`), and the measured channel efficiency. Provides aliases to auto-balance bonds by channeling, end all buffs, and end all buffs except Shield of Faith.

Type `bondhelp` after install for the full command list.

### Usage

`> bonds`

    [bond] ===== Elemental Bond Status =====
        AIR    1602 / 1602  (100%)  drain +36
        ...

`> setmax`     -- record current strengths as your maxima (use judiciously)
`> tcbal`      -- auto-balance bonds toward maxima via channeling
`> tcbal?`     -- show the plan without sending
`> ch 100 fire earth`   -- manual channel
`> endbuffs`   -- end ALL buffs
`> keepfaith`  -- end every buff EXCEPT Shield of Faith

### Notes

* Channel efficiency is learned live from the "resulting in a flow of N units" line; it starts at ~68% and self-corrects.
* `keepfaith` ends each non-protected buff individually. Add more protected spells with `keepalso <name>`.
* Run `tcla` (list all) before `keepfaith` if buffs may have changed, so tracking is current.
]]
version = [[2.9]]
created = "2026-06-15T08:45:00+02:00"
