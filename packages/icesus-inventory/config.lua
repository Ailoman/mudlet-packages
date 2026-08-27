mpackage = [[Icesus Inventory]]
author = [[built with Claude]]
description = [[Instance-aware inventory tracker, disposal advisor, inline annotator,
and mob-safe auto-loot with shop/altar disposal for Icesus.

### Favour-first disposal: learn favour before selling (9.14)
disposeRoute used to sell an item on its silver figure whenever it had ANY sale
value — even while its divine favour was UNMEASURED. That contradicts classify()
(which learns favour before writing an item off) and the package's own premise
that favour is the scarce side: a 936-silver iron club sold blind, its favour
never learned, when the altar might have valued it higher. Now disposeRoute
never sells while the altar side is unmeasured — it sacrifices ONE to learn the
favour first (a learning sacrifice costs one item, not the stack; the rest route
on the next pass), and once both are known the better silver-equivalent wins,
exactly like classify(). Exceptions where silver is the only answer: the altar
has refused the type (noSac), or the price is at/below `sellBlindMaxSilver` (the
cheap-junk escape hatch, default 0 = always learn first). Two knobs:
`inv.config.favourFirst` (default true; set false for the old sell-leaning rule)
and `inv.config.sellBlindMaxSilver`. Because far more now routes to the altar,
`dfToSilver` (via `idf`) governs many more decisions — calibrate it.

### ishop no longer appraises sac-only items at a shop (9.13)
A food/sac-only item (a heart) has disposeRoute "unknown" when its favour is not
yet measured — but "unknown" there means "learn favour at the ALTAR", not
"appraise at a shop". ishop read it as the latter and dragged every heart out of
the stage bag, showed it to a keeper who can never buy food ("I don't buy food
stuff"), and put it straight back — a wasted get/value/put per heart every run,
made worse by every heart answering only to `heart` (endless position retries).
ishop now holds a KNOWN sac-only category for isac instead. A brand-new type
with no category yet still gets one shop appraisal — which is how it learns it
is food — and is deferred from then on.

### The cutoff is a pick-up rule even before an item is established (9.12)
classify() returns "leave" (skip) only once an average is ESTABLISHED (n >=
estN); below the cutoff but not yet established it returns the ROUTE instead,
meaning "worth another sample". roomScanEnd treated that as a reason to pick the
item UP — so a 42-s/l Lead spear (favour sampled once) was hauled home every run
to "refine" a reading that never completes: you would have to sacrifice a cheap
item three times to establish its favour, which you never do, so it was picked
up forever. The pick-up decision now enforces the cutoff regardless of sample
count: an item whose known value/litre is already below cutoffSL is LEFT on the
floor. Genuine first appraisals (no data at all, or value-known-but-unweighed)
are still taken once, and the worth-learning-favour case is unchanged. Disposal
(disposeRoute) is untouched — items already in the pack still route normally.

### Creatures are not loot; `inonitem` to flag the ones that slip through (9.11)
The colour-based mob filter (`lineIsMob`) was written but never wired into the
room scanner, so NPCs drawn in colour ("Orc patroller humming a happy tune")
were ingested as items: iloot burned a whole handle ladder on each and left an
`ihandle` nag for something that was never takeable. `roomLine` now consults it
— a colour-led line is skipped as a creature, UNLESS it carries a glow tag (a
glowing ITEM that happens to be coloured) or is a money pile (`get all money`
takes those). `lineIsMob` returns false whenever it cannot read colour, so a
terminal without colour info keeps the old aggressive behaviour rather than
dropping real items.

New `inonitem` command for the ones that still get through: `inonitem` lists the
stuck types by number, `inonitem N` / `inonitem all` / `inonitem "exact name"`
flag them as non-items (purging the phantom type and never looting it again),
and `inonitem reset NAME` undoes a mistake.

### Bulk disposal: sell all, stage for sacrifice, sacrifice all (9.10)
Two optimisations over the one-command-per-item paths, each safe only in a
specific condition and with the per-item path as fallback.

ishop now empties each sale bag with a single `sell all from "<bag>"` after
appraisals finish, instead of one `sell` per item. This loses nothing: each
"You sell X for N silver." line still names and prices the item, so price and
vendor-category learning are unharmed — the plain `<Keeper> says: I don't buy
<cat>.` refusal is now parsed too, so categories are learned during bulk sales.
Before the sale, the sac-routed items are STAGED out of the sale bags into the
"treasure" bag (`istage`, also run automatically), so the vendor cannot buy an
item whose real worth is divine favour.

isac then empties the stage bag with one `sacrifice all from "treasure"` — but
ONLY when every altar-bound item in it is established (favour n >= estN). A bulk
sacrifice returns one lump favour that cannot be attributed to an item, so a
single unlearned item would lose its reading; until the whole bag is
established, the proven per-item learning path runs and prices the unlearned
ones one at a time. `ibulk` shows/toggles both switches.

### Disposal empties the bags; the cutoff is a pick-up rule (9.9)
classify()'s keep/leave/trash verdict answers "should iloot grab this off the
floor?" — it weighs value per litre against the pack space it would cost. That
is the wrong question for something already sitting loose or in a disposal bag:
it is there to LEAVE. Applying the pick-up cutoff to disposal meant low-value
items were silently HOARDED — a 3-favour guard-dog heart (favour * dfToSilver
below the keep line) sat in loose forever, and a 77-silver empty sack sat in
"loot" forever, because ishop/isac only ever touched items ABOVE the cutoff.

ishop and isac now route disposal through `disposeRoute`, which ignores the
cutoff and asks only for the way out: any sale value at all -> sell (however
cheap), favour but no sale value -> altar, nothing measured yet -> appraise or
learn, measured worth of zero -> drop. So the bags actually empty. A worthless
LOOSE item is dropped; a worthless BAGGED item is only reported (a blind drop
into a bag needs a handle we cannot confirm, and mis-dropping something valuable
is unrecoverable — pull those loose and drop by hand).

Note this is unaffected by a low `dfToSilver`: valuing favour near its true
silver ratio is a deliberate lean toward selling, and disposal now honours that
(the heart is offered to the altar because it CANNOT be sold, not because it
cleared a cutoff).

### The "not carried" reply the game actually sends (9.8)
A sell, sacrifice or get aimed at something the location map thinks we hold
but do not is answered "You do not seem to have any <item>." — which matched
NO trigger. "Not carried" only catches "You do not have <item>." (a different
string), so the "seem to have any" form fell straight through: a phantom entry
was retried on every single run and never pruned. A suit of chainmail already
sold at one shop was offered again at the next ("You do not seem to have any
iron chain mail suit."); a stale "armour" bucket that never held anything was
sold into empty air on every ishop. The line is now a trigger (`onNoSuchItem`)
that reads it the way a failed sacrifice is read — the item is not there OR the
handle does not name it — and splits on handle provenance: an ACTION-PROVEN
handle failing means a genuine phantom, so prune it and drop its queued
commands; a GUESSED handle failing (e.g. the drained oil sack, which answers
only to an of-form and never to the ladder's `sized sack`) walks the handle
ladder and, if it runs out, marks the type stuck for `ihandle` instead of
deleting a real item. Either way it advances as a handled outcome, never a
bad-handle miss, so it cannot trip the three-strikes abort. During isac the
same line routes to onSacNothing.

### Handle discovery (new in 5.4, fully scoped in 5.6)
Items answer to MANY handles ("Voltaic titanium blade" is also `blade`,
`titanium blade`, `executioner's sword` and `sword`). The tracker learns and
stores the whole set per item type instead of one lucky winner.

Discovery uses `look`: free, non-destructive, and scopable. Each probe is
addressed to exactly where the item lives — `on ground` for room items,
`in "<bag>"` for stowed loot, bare for what you carry. For each new type the
ladder of plausible handles is enumerated and probed one at a time; a hit
prints the item's description, a miss prints "Look at what?". The first hit
becomes the fingerprint and every later hit is compared to it, so a handle that
reaches a DIFFERENT item is recorded as ambiguous rather than blacklisted. The
description is mined for handles the name never contains, via the "It most
closely resembles a ..." line.

Ambiguity is recorded WITH ITS SCOPE, because Icesus' verbs are scoped: `get`
only sees the ground, `put` only sees inventory. A handle shadowed by something
in your pack is still used freely for picking that item up off the floor, and a
collision found on the ground is exactly the one `get` would have hit.

Probing runs automatically: on room items before `iloot` picks them up, and on
anything loose before `iloot sort` stows it. Both windows are out of combat.
Bagged loot is probed in place — no need to pull it out first.

### Sacrifice, appraisal and map integrity (5.7-6.1)
The altar echoes its own short form ("sacrifice dagger on the altar") whatever
handle you sent, so favour readings used to be dropped whenever that form was
ambiguous. `isac` now sends one sacrifice at a time and attributes the favour
by position, the way the handle prober does — no more lost DF on a learning
sacrifice, which is irreversible.

"There was nothing to sacrifice." is treated as evidence: the instance is
pruned from the location map, and the run stops after 3 consecutive misses
instead of grinding through a stale list.

`ishop` and `isac` scan the disposal sacks themselves (`l "<sack>"`) instead of
refusing and asking you to type it, probe any unproven handles first, then work
ONE item at a time. A get/value/put cycle that fails now stops the run after
three consecutive failures instead of cascading, and "You do not have <item>."
prunes the phantom entry that caused it. A container scan that cannot be
attributed to a specific sack is discarded rather than applied to your loose
inventory.

Appraising, selling and sacrificing reference ANY instance in a bag rather
than an indexed one, so they no longer silently do nothing when a container's
stow order is untrusted (which any reconciling scan sets). A bagged item that
cannot be fetched is skipped instead of being sent to `value`, which only ever
reaches loose items.

Every item now reaches both numbers. An item whose category a shop refuses is
still asked about once (a refusal is an answer), and its silver column then
reads `n/a` rather than `?` forever. `isac learn` sacrifices one of each type
whose divine favour has never been measured — the only way to price an item
that no shop will buy.

Container scans are keyed on the bag NAME. A capture-group slip meant the
whole command ('l "loot"') was used as the key, so every scan filled a phantom
bucket that ishop and isac never read — which is why appraisal and sacrifice
kept working from stale contents. Mis-keyed buckets are dropped on load and a
command-shaped key is now refused outright.

In "a piece of rotten bread" the noun is BREAD, not PIECE — a measure word is
not a head noun, and the display form is not an id, which is why sacrificing it
reported nothing while three sat in the bag. Measure words are recognised (but
"sack of oil" and "set of bandages" are real objects and are left alone).

A failed sacrifice or a failed shop fetch walks down the handle ladder (up to
3 alternatives) before concluding the location map is stale. If one works, every
handle that reached nothing is marked bad and the one that worked is proven —
`look` accepts long display forms that `get` and `sacrifice` refuse, so a
probe-proven handle is not automatically an actionable one.

A comma ends the identifying part of a name: "silver necklace, decorated with
sapphires" is a necklace. Commas are also the game's multi-target separator, so
one left inside a handle is misparsed outright.

Bag references pick the shortest proven handle that is unambiguous among the
other types in THAT bag, so two kinds of heart in one sack escalate to the
qualified form instead of grabbing whichever came first.

Two bags can share one description ("loot" and "gear" are both huge leather
sacks). When that is detected, echoes naming that description are no longer
attributed by description at all.

Loose inventory is refreshed (`i weight`) before ishop and isac run, so items
carried in hand are appraised and sacrificed alongside bagged ones instead of
waiting for something else to re-read them.

One command can produce several outcome lines — a keeplist refusal is followed
by a second refusal, and a vendor rejection also carries a price, matching two
patterns at once. Each of those used to advance the queue, sending the next
command per line and desynchronising replies from requests. Advancement is now
deferred by one pass, so a reply advances exactly once.

"You cannot sacrifice items from your keeplist." is learned: that type is never
offered to the altar again. A sacrifice that gets no reply skips that item
rather than ending the run.

"That is not worth anything." is a real appraisal of zero, not a refusal.
Unrecorded, such an item stayed "unknown" and was pulled out, shown and
restowed on every single ishop run.

One `sell` moves ONE item, so eleven skins need eleven commands. Sales now run
inside the paced queue like everything else — fired loose alongside the
appraisals, their replies advanced the appraisal queue early and prices landed
on whichever item happened to be in flight. A vendor's refusal drops the rest
of that category instead of asking once per instance.

### Shops are profiled, not just blacklisted
Every shop deals in some categories and refuses others. Refusals were already
remembered; now the positive side is too — which categories a shop buys, and
the best price it has paid for each item. `ishops` prints the map. `iitem`
shows an item's category and where it has fetched the most.

"<Item> has no value." names the item, so if that is not the item we asked
for, the handle reached something else: it is marked ambiguous and the sale
retried with a better one. Two kinds of skin loose at once made `sell skin`
reach the wrong one — loose handles are now checked for collisions the same
way bagged ones are. A shop declining a sale is an ordinary answer and no
longer counts toward the three-strikes abort.

### Provenance and identification (6.7)
A corpse is a source, not a container. Treating one as a container invented a
"corpse" bucket that outlived the corpse and, worse, let a get from it
decrement a real bag. It is also the one moment the origin of an item is
knowable: the kill report and the corpse header both name the monster, so
items taken "from a corpse" record who dropped them. `idrops` lists monsters
and what they have been seen to drop; `iitem` shows an item's origins.

Identification renames an object in place — "Steel dagger" becomes "Steel
elven long dagger with red runes" — which, keyed on the display name, orphans
everything already learned. It is the same object, so weight, volume, proven
handles and origins now transfer both ways, and the link is remembered in both
directions. One generic name can hide several real items (red-runed and
blue-runed daggers share the name "Steel dagger"), so proven handles are
pooled across the whole family: a handle discovered on an identified item is
tried first on the next unidentified drop.

The probe also mines the description prose. "This steel long dagger is
definitely made by elven smiths" yields `steel long dagger`, `long dagger` and
`elven long dagger` — the last of which is the handle that works, and appears
nowhere in the item's name.

### One name, several items (6.8)
"Steel dagger <intense chartreuse glow>" and "Steel dagger <intense yellow
glow>" came off the same corpse and are not the same dagger. The glow survives
in every listing, so it is the only discriminator available without paying to
identify. Handles stay shared — the parser matches the words and both answer to
the same ones — while VALUES are kept per glow variant. Pooling them produced
"sell ~13641 range 2704-19308". `iitem` shows the split.

"You see no '<handle>' around here." is a bad handle, not scenery. It shared a
trigger with "You cannot move the <x>." — so one hand-typed `drop steel dagger`
marked a 13,000 silver dagger permanently un-lootable. The two are now
separated: a failed handle is demoted, the item is untouched. Anything already
on the non-item list that has a measured weight or price is restored on load,
and `iloot include <name>` clears one by hand.

### Ghost containers and ghost items (6.9)
A bag's DESCRIPTION is not a place. "huge leather sack" describes both `loot`
and `gear`, so an unattributable put used to create a bucket under it — one no
scan ever covered and nothing ever pruned, which is how 39 iron scale mail
armours accumulated somewhere that does not exist. Such a put now records
nothing and flags the candidate bags for a rescan instead of guessing. Existing
description-keyed buckets are dropped on load.

A shop's quote carries its own short form ("...for the skin"), not the item's
name. Taking that as a name filled the database with handle-shaped ghosts —
"symbol", "platinum dagger" — that no listing ever matches. Short forms are now
rejected, and `iclean ghosts` removes the ones already stored: types never seen
in a listing, held nowhere, never weighed.

### Queue re-addressing and map noise (7.0)
A queue is built up front, so every job for a type carries the handle that was
best at build time. When that handle turned out to be wrong, the other
seventeen queued sales still held it — three identical failures then aborted an
eighteen-item run. Demoting a handle now re-addresses every command already
queued for that item, in both the shop and sacrifice queues.

Running out of handles for one item is a problem with that item, not the run:
its remaining commands are dropped and the rest continues.

A sale scoped to a bag was seen reaching a LOOSE item of another type, so sale
handles must be unambiguous in both places at once.

The mapper draws an ASCII map with the room description beside it. Those lines
were being ingested as items, which is where thousands of junk types with names
like "#####  the road. The sky is overcas" came from. Room lines that are
mostly map glyphs, over-long, or letterless are rejected.

### Skinning ends when the lines say so, not when the clock does (9.7)

9.6 serialised the corpses on two things that turned out to be wrong: a
30-second timeout measured from the moment `skin corpse` was sent, and the
prompt's skill field going empty. A logged run showed both failing.

**The timeout was measuring the wrong thing.** How long a skinning takes varies
by monster and by skill, and nothing here may depend on knowing that number. A
slow corpse would have been abandoned mid-work with the knife still going. The
watchdog now measures SILENCE: every line the skinning produces — the start
line, each finish, each retrieve, every busy prompt — kills it and starts it
again. Thirty seconds now means "half a minute with nothing happening at all",
never "half a minute of work", so a slow monster simply keeps poking it. Raise
it with `iskin quiet 60` if some monster really does go quiet for that long.

**The prompt never came.** Icesus sends a prompt in reply to input, not when a
skill finishes on its own. In the log the four "You finish the skinning" lines
and the "You retrieve" lines arrived with nothing behind them; the cleared
"Skill:" field only appeared two seconds later, when a `l` was typed. Waiting
on it would have stalled every corpse until the watchdog gave up — a 30-second
pause per corpse and no skins registered.

So the finish lines close the corpse. They arrive as a burst — four finishes
and two retrieves inside the same millisecond — so the burst is allowed 1.5
seconds to settle before the next corpse is asked for, and every line in it
pushes that moment back. A prompt that does happen to arrive with the skill
clear still short-circuits the wait; it is a shortcut now, not the mechanism.

Two smaller ones. A skill ending can no longer be mistaken for a corpse
finishing when the character was already busy with something else when the run
began — only an attempt we watched start can end. And if `skin corpse` produces
no "You take your knife" line within three seconds, there is nothing here to
skin: the run stops and says so, instead of waiting out the full watchdog for a
refusal message whose text has never been captured.

    iskin quiet 60     seconds of SILENCE before giving up (default 30)

### Skinning: iskin (9.6)

Skinning is the other way to empty a corpse, and it differs from digging in one
way that matters to a tracker: the skins go straight into LOOSE INVENTORY with
no "You get" echo to attribute. Every other route into the pack announces
itself; this one does not, so sixteen skins can pile up that the location map
has never heard of. Everything else the corpse held spills on the floor exactly
as digging does, and the corpse is consumed either way.

The gap is narrower than it looks — a plain `i` registers the skins by name and
count, and `i weight` adds mass and bulk. So the answer is not to guess the
skins from the skinning lines, which never name them, but to ask for a weigh
once the knife is down. `iskin off` turns that off.

One `skin corpse` produces several "finish the skinning" lines, one per
attempt, some succeeding and some not; it runs about thirteen seconds and holds
the skill busy throughout. So the corpses are worked one at a time, serialised
on the prompt's own skill field — "Skill: busy" while it runs, empty when done
— with a 30-second backstop. The count comes from the same free `l corpse N`
walk icorpse already uses, so the loop ends on a number we measured rather than
on a refusal message nobody has captured yet.

`icorpse skin` runs the lot in the only order that works: walk the corpses for
provenance, skin them (which takes the hides AND does the grave's job), weigh
the skins, bury anything that could not be skinned, then loot the spill.
Digging first would throw the hides away.

Two supporting fixes. "You take your knife and start skinning the corpse of X"
is the only line that says which monster the skins and the spill came from, so
it now sets the origin. And `resolveFragment` ignored no articles, so "You
retrieve a clod of snake lard" never matched the stored "Clod of raw snake
lard" — it failed on the "a" alone, the same flaw nameFits had against the
shop's "…for the boots".

    iskin              skin every corpse here, then weigh the skins
    iskin on|off       whether to weigh afterwards
    icorpse skin       walk, skin, weigh, dig the remains, loot the spill

### "and" inside a name is not a separator (9.5)

A room line can list several items joined by " and ", so it has to be split —
but "and" is also an ordinary word inside a name, and splitting on every
occurrence turned "Flint and steel" into a "Flint" and a "steel", and "Fishing
rod with a line and a hook" into a rod and "a hook". None of those objects
exist, so each became a permanent phantom type no listing ever matched again.

The discriminator is capitalisation. A room listing prints DISPLAY names, and
those always begin with a capital or a digit:

    Heavy cloth shoes and Iron dagger    -> two items
    Flint and steel                      -> one item
    Fishing rod with a line and a hook   -> one item
    Flint and steel and Iron dagger      -> two items

So the split happens only where the text after " and " starts a new display
name. A line that is already a known type is never split at all, which covers
any name that breaks the habit once we have seen it whole even once.

`iclean junk` used the same naive rule and would have DELETED "Flint and steel"
along with its price, its favour and its proven handles. A composite is now
defined as a type the splitter would break up; a real name is one it leaves
whole.

Two related handle fixes. "Flint and steel" has no clause marker, so "and"
survived as a leading modifier and the ladder offered `and steel` — spent as a
real command, then filed as a refused handle forever. No candidate may now
begin with a connective, and the blind ladder picks the nearest modifier that
is actually an id word. The full form "flint and steel" is still generated and
still probed, since it may well be the handle that works. ("Fishing rod with a
line and a hook" was already correct: "with" is a clause marker, so the head
noun is the rod.)

### The gate was cleared before it was read (9.4)

9.3 gated the room scan on `roomScan.atItems` so a foreign prompt could not
close it. But `atItems` is a CURSOR, not a fact: roomLine clears it as soon as
the item block ends, and the prompt line is one of the things that ends it. The
"Scan line" trigger sits earlier in the package than "Prompt reset", so it
fired first and cleared the flag on the very line the prompt trigger was about
to check. The scan then never closed at all, and five seconds later every run
reported "no room description came back".

`sawRoom` is the durable fact — our own look's room block arrived — set once by
the exits line and never cleared. That is what the prompt gates on now.

Both this and 9.3's bug are the same shape: behaviour that depends on the order
triggers fire in, tested by calling the functions directly. So the test harness
now GENERATES a dispatcher from the package's own trigger list, in package
order, and replays real MUD transcripts through it line by line. The reception
desk room, the dig-and-loot race and a full icorpse run are all driven that way
now, and reverting either fix makes them fail. There is also a check that every
one of the 38 trigger scripts survives a degenerate line without throwing.

### The room scan was closed by somebody else's prompt (9.3)

Type `dig grave` and `iloot` together and iloot answered "no items here" a
moment before the room listed nine of them. The scan is closed by a PROMPT, and
the dig's prompt arrives before the look's reply — so a command already in
flight when iloot starts would close the scan while the room block was still on
its way. Any command would do it, not just a dig.

The exits line is the marker that our own look's room block has begun, so
`inv.onPrompt` now ignores prompts until it has been seen, with a five-second
backstop that closes the run out rather than leaving it open forever.

`icorpse` had the same fault built in, since it dug and then called iloot in one
breath. It now waits for the grave's own reply ("You dig a grave for the corpse
and bury it carefully.", or the mass-grave form) before looting, which also
confirms the spill is on the floor before we go looking for it. If that reply
never comes the run says so — most likely the grave command is wrong for your
setup — and loots anyway.

### Fix: iloot died silently (9.2)

8.9 named the carrying-capacity table `inv.load` — which was already the
function that reads the save file back. The assignment shadowed it, so every
reader indexed a function value, `inv.tooHeavyNow` threw for the first item in
any room, and the trigger aborted before iloot printed a single line. Worse,
`noteCarry` assigning to that name would have destroyed the loader for the rest
of the session. The table is `inv.carry` now.

Two guards so this class of mistake cannot come back quietly: a build-time
check that no `inv.*` name is both defined as a function and assigned a value,
and a startup assertion over the shape of 71 functions and 9 tables the package
calls. Plus a regression test that simply runs a plain room end to end and
fails if iloot issues no commands — the previous suite exercised every branch
of the decision logic and never once checked that an ordinary loot still ran.

### Corpses: icorpse (9.1)

`dig grave` SPILLS every corpse's contents onto the floor before destroying
them — visible in the logs, and it changes the whole shape of the problem.
There is no reason to loot corpses item by item: that would mean a second set
of handle problems (a corpse is a container you cannot name reliably, holding
items indexed against contents you can only see by looking) for no benefit.
Dig first and the room becomes an ordinary `iloot`, so coin densities, the
cutoff, the surplus sweep and every other rule apply unchanged, in one place.

What IS worth doing first is looking inside each corpse. `look` is free, and it
is the only moment the game will say which monster carried what — scanEnd
already routes a corpse scan to noteOrigin rather than the location map, which
is what fills in `idrops`. Once they are in a mass grave that link is gone.

Corpse display names vary with how the thing died ("Burned slush of snake",
"Mutilated lump of carrion crawler"), so they cannot be picked out of the room
listing. They all answer to `corpse` and to a positional index on it, so the
walk is `l corpse`, `l corpse 2`, ... until "Look at what?".

No separate check is needed for items that spilled: iloot opens with its own
`look`, Icesus answers chronologically, and so that look already describes the
room after the grave was dug. Anything a corpse held is on the floor by then,
including anything the walk failed to see inside.

    icorpse            look in each corpse, dig, loot the spill
    icorpse quick      skip the look, just dig and loot
    icorpse scan       look only, leave the corpses alone
    icorpse nodig      look and dig, but do not loot afterwards
    icorpse dig dg     change the grave command

### Types that share their only handle (9.0)
Every heart in the game answers to exactly `heart` and to nothing else — the
mob words are not id words, so `heart of troll` and `troll heart` do not parse.
A room holding troll hearts and guard dog hearts therefore offers no string
that reaches one without risking the other, and no amount of handle discovery
can improve on that. Nor can it be indexed from the floor: positional order on
the GROUND has never been observed, since we watch our own pack change and
never the room.

So take the lot, and put it right afterwards, where the order IS ours:

  * a wanted type whose only handle is shared with a type we passed over on
    VALUE (not trash, not excluded, not unreachable) sweeps that type up as
    surplus, and both come out loose
  * the sort stows every keeper first, then drops the surplus. That ordering is
    the point: while a keeper and its lookalike are both in hand no bare string
    separates them, but once the keepers are stowed the only heart left in hand
    is surplus and `drop heart` is exact, with no positional form to trust
  * the puts that stow the keepers are the one command that must name a
    specific item while a lookalike is present, so they carry an index — over
    the loose order, which is genuinely known because every arrival was named
    by its own get echo. An index is a claim, so the drops WAIT for the put
    echoes and go ahead only if every one landed where it was aimed. If not,
    nothing is dropped and the surplus is carried to an altar instead, which is
    the safe outcome rather than a broken one.

`heart` is also no longer recordable as ambiguous, for the same reason
`handleRecordBad` has always refused it: a collision between two kinds of heart
is structural, there is nothing more specific to escalate to, and marking it
only blocks the one handle that works.

### "Too heavy" is a fact about now (8.9)
It was being stored as a permanent property of the item. It is not: it is the
item's mass measured against the room left in your pack, and it stops being
true the moment you drop something, bank coins or empty a bag at a shop. A
Shovel you could not lift at 97% load was never offered again for the rest of
the session, in any room, however light you had become.

Every listing opens with "You are carrying 157.3kg (56%) of 277.5kg and 100.0l
(65%) of 153.5l" and the package was throwing that line away — which is exactly
why the refusal had to be remembered as a verdict instead of recomputed as a
condition. It is now parsed, and weight is decided on the present:

  * a refusal records the load it happened AT, and is re-tested as soon as you
    are lighter than that
  * the table is cleared at the start of every `iloot` run, so nothing carries
    between rooms
  * when the item's mass is already known, the skip is a prediction with its
    working shown — "heavier than the room left (12.4kg vs 2.5kg free)" —
    rather than a memory of an old failure

### Nothing is written off on one number (8.8)
Divine favour turns out to be a near-constant fraction of silver. Measured
across every type on this profile that has both figures:

    Bone earrings          16938 s    928 df   18.25 s/df
    Steel staff             2991 s    168 df   17.80
    Wyvern scales           7103 s    380 df   18.69
    Small set of bandages    525 s     30 df   17.50
    Flint and steel          156 s      9 df   17.33
    Fur robe                 583 s     27 df   21.59
    ------------------------------------------------
    range 17.33-21.59, median 18.03 (spread about 12%)

The exception is the class the shop prices at ZERO. Hearts carry 13-88 favour
and no silver at all, so their ratio is infinite and no silver figure predicts
it. That is the argument for measuring rather than assuming: the items where
favour matters most are exactly the ones whose silver column says nothing.

Which exposed a closed loop in iloot. A sell-only type below the cutoff was
skipped on the floor because its favour was unknown — and its favour stayed
unknown because it was never picked up. "Pay for the lesson out of stock we
already carry" is right only while there IS stock. For a type never held, one
instance is now taken once, purely to price it at an altar; holding one makes
the next copy skippable and a measured type never returns here, so the cost is
one item per type, ever. An altar that refuses the type is not chased.

Appraisals no longer require the shop's short form to match the item. Andolal
priced an "aluminium chain mail byrnie" at 48,691 silver and called it "the
bracers" — the quoted name need not share a single word with the display name,
and insisting on one threw away the most valuable appraisal of the run. We know
what we are holding because we watched it leave the bag; the quote line cannot
overrule that. The mismatch is noted rather than obeyed, and the price cannot
leak onto the unrelated type the shop's word happens to resemble. Separately,
`nameFits` was failing on the article: "the" is three letters, so the length
guard let it through and every comparison against "…for the boots" failed on
that word alone.

### Positional disambiguation: `stone cap 2` (8.7)
When two TYPES in one bag answer to the same handle, no string separates them.
The shortest-unambiguous search has nothing left to offer, returns the
colliding handle anyway, and `get stone cap from "loot"` fetches whichever cap
the game reaches first — every time, so the other is never appraised at all.

The remaining lever is the positional index, and the case that needs it was
precisely the case that never got one: `refFor` indexes among instances of a
single type, so three identical breads got `bread 1` while one cap of each kind
got nothing. The index actually counts items answering the HANDLE, in stow
order, newest = 1. `inv.loc` is already kept in that order (locAdd inserts at
the front), so the position is a lookup rather than a guess, and rivals are
counted with the same three tests used everywhere else — a proven handle, a
rung of the blind ladder, or the word appearing in the name.

Three deliberate limits, because stow order is the least trustworthy thing the
package knows:

  * **Gets only.** `get` is the one verb whose reply names the object it
    moved, so an index sent there is checked against the echo. `sell` and
    `sacrifice` would be sending an unverified guess and their echoes are short
    forms that cannot confirm it, so they still reference any instance. `put`
    has no positional form at all and keeps the bare handle.
  * **Built at send time, never at queue time.** An index is only true of the
    bag as it stands, and every put-back returns an item to the FRONT of the
    stow order — so a reference computed three jobs ago is describing a
    container that no longer exists. shopValueNext rebuilds each fetch
    immediately before sending it.
  * **A miss teaches.** No listing can restore stow order once it desyncs,
    because `i`, a container look and `i weight` are all alphabetical. So when
    the echo says a different type arrived, that is treated as the truth: the
    observed type is moved into the slot we asked for, the bag is flagged
    untrusted, and the type we missed is re-queued to be tried again this run
    (bounded, so a bag that cannot be pinned down does not loop).

### The get echo is the answer, not the quote line (8.6)
An `ishop` run appraised three items and recorded none of them.

The shop quotes its own SHORT form — "…would probably give you 108 silver coins
for the boots" — and that was being resolved against the whole type list, where
three tracked types end in "boots". Ambiguous, so the price was dropped. But
nothing was being guessed at: a `value` follows a `get` whose echo named the
item in full ("You get the tin leather ring mail boots"). That echo is now
recorded as the job's `heldKey` and it decides the attribution outright.

Note it is heldKey, NOT the key we asked for. `get stone cap` fetched the soft
leather cap twice while the heavy cloth cap was never appraised — one handle,
two matching types in one bag. Recording the price against what we MEANT to
fetch would have been the corrupting answer. The mismatch is now caught at the
get: the handle is marked ambiguous in that bag and the remaining commands for
that type are requeued with a longer one, so the second cap becomes reachable.

`inv.locMove` no longer loses an item when the source removal fails. It used to
return false and add nothing, so a fetch out of a bag the map disagreed about
left the item nowhere at all — and "where is this held?" is exactly the
tiebreak the old fragment matcher used, so an otherwise unambiguous fetch came
out ambiguous. The game said "You get"; the item is in hand; record that.

Ground handle requests no longer follow you around. They are only actionable
where they were raised (the probe hint is `l YOURGUESS on ground`), so a room
scan that does not list the item drops the request as stale, and shop and altar
runs do not nag about ground-only requests at all — that was the phantom "Steel
dagger on ground" complaint at the end of an ishop in another room entirely.

### Coins face the same cutoff as everything else (8.5)
Coins were the one exemption: coinInfo short-circuits classify to "sell" before
any threshold test, so every denomination was always taken. Measured from your
own `i weight` lines, that is wrong for exactly one of them:

    silver     1 s each   2.00 ml         500 s/l   leave
    gold      10 s each   1.00 ml      10,000 s/l   take
    platinum 100 s each   1.05 ml      95,238 s/l   take
    mithril 1000 s each   1.00 ml   1,000,000 s/l   take

Silver runs about 500 silver per litre — half the default keep line, and the
only denomination that fails it. Nearly 10,000 silver coins is 19.8 litres, an
eighth of a full pack, for less than the same space in ordinary loot.

Densities are learned, not assumed: a coin line in `i weight` carries its own
count, so it measures ml-per-coin directly, and the seeds correct themselves.
`iloot coins` prints the table and the take/leave call; `iloot coins off`
restores the old take-everything behaviour.

`get all money` is still used whenever every denomination present clears the
cutoff — one command, no reason to spend more. Only a mixed room falls back to
per-denomination `get all &lt;denom&gt; coins`, which is the `all foo` form from
`help object handling` but is not separately documented for money. If the
parser refuses it, that refusal is caught: the run takes everything the blunt
way that once, the feature turns itself off permanently, and it says so.
Leaving platinum behind on a syntax guess would be much the worse failure.

### Money is not evidence (8.4)
Coins arrive from `get all money` — ONE command covering every pile in the
room, with no per-item request behind it. So a coin pickup always looks like
"something turned up that nobody asked for", which is how 8.3's wrong-item
check blamed `get axe to "loot"` for delivering 5 platinum coins and marked
`axe` ambiguous on the ground. Money is now excluded from that check outright,
and the check itself only fires when exactly ONE get is in flight: with a burst
in the air, any attribution is the positional guesswork that produced the last
two false accusations, and a wrongly blocked handle costs more than an
unclaimed queue entry.

Money also cannot be a "non-item" or an exclude any more. A pile of coins is
never fetched by its own handle, so a refusal naming one came from some other
command — and filing it made iloot announce "leaving 1" immediately before
`get all money` hoovered it up anyway. Existing entries are purged on load, and
the room scan no longer consults those lists for coins at all.

### Burst attribution, 0.0l items, and why an item was left (8.3)
Three things, found in one ten-item loot run.

**The single verification slot could not survive a burst.** 8.0 removed the old
guard that armed inv.verifyArm only for a lone deliberate get. Right idea,
wrong layer: inv.pendingGet is ONE slot, so ten gets overwrote it nine times
and the FIRST echo was matched against the LAST handle sent. The visible
symptom was "'tin bracers' reached the wrong item (Bloodstone) — marked
ambiguous"; the invisible one was worse, filing `tin bracers` as an
ACTION-PROVEN handle for the Bloodstone, which would then be the preferred
command for fetching it. The loot path no longer arms verifyArm at all —
inv.loot.issued already correlates replies by name, and now falls back to send
order (Icesus answers chronologically) to spot a genuine wrong-item grab. It
marks the handle ambiguous for the item it was aimed at and, deliberately,
records nothing for the item that actually arrived: that would be a guess, and
guessing there is what corrupted the Bloodstone.

If a handle from an unrelated item is already on one of yours, clear it with
`ihandle reset NAME`.

**0.0l is not zero.** `i weight` prints one decimal, so anything under 0.05l
displays as 0.0 — and a stored volume of zero is indistinguishable from no
volume at all, because every test asks `volume > 0`. A Bloodstone appraised at
22,973 silver sat in "loot" unroutable for exactly that reason. A 0.0 reading
is now recorded as 0.05l: the top of the possible range, which is the
conservative choice, since the largest possible volume yields the smallest
possible value-per-litre. Existing zeroes are lifted on load.

**"leaving 4" answers the wrong question.** Skips are now printed grouped by
cause — too heavy, learned non-item, excluded, trash, or below the cutoff with
the actual s/l figure. The causes are not interchangeable: one is a fact about
your pack, one is a threshold you can retune, and one is a guess the package
made from an earlier refusal and may have got wrong. Collapsing them into a
number is what made the loot engine look arbitrary and hid bad non-item
entries indefinitely.

### Items are sized while they are out (8.2)
`i weight` reads LOOSE inventory only, and it is the only thing that ever
writes a volume. So a type that reached a disposal bag without passing through
your hands — dropped in by hand, or first seen by a `l "loot"` scan, which
creates the row from the name alone — never acquired one. Without a volume
classify cannot compute silver-per-litre, so it returns `unknown` forever, and
an `unknown` is pulled out, shown to the keeper and stowed again on EVERY ishop
run while isac refuses to route it at all. Found with a Bloodstone sitting in
"loot" carrying 18,004 silver and 2,688 DF, both learned, and still `? s/l`.

The one moment such an item IS loose is between the get that fetches it for
appraisal and the put that returns it, so that is where it is now measured:
one `i weight` before the put, only when the type has no volume, so it happens
once per type ever and never again. That measurement scan deliberately does
NOT reconcile the location map — the listing was generated before the put and
before the next item's get, so applying its census would prune entries that
are merely in flight. It takes the measurements and drops the count.

### Exhausted ladders are visible and recoverable (8.1)
Three faults that only showed up once 8.0 started demoting handles for real.

A refused handle is now only blamed when the room still holds the item. If the
run has already taken every one the floor had, "You see no 'X' around here." is
a true statement about the room and says nothing about the string — blaming it
there burns a handle that just worked, and a few of those in a row leave a type
with no ladder at all. That is how a plain, visible item ends up unreachable.

When every rung IS on the bad list there is no command left to send, so no
action can run, so nothing can ever be promoted — a dead end with no exit. It
now says so as a warning rather than a grey aside, and `ihandle reset <name>`
clears a type's refusals and lets the ladder start over.

And the 7.9 self-pruning was too eager: it dropped any request whose item the
location map could not find, but the map models the pack, not the floor, so
every request iloot raised for a ROOM item was pruned the instant it was made —
and the run then reported "nothing is stuck". Ground requests are now taken at
face value, and `ihandle` scopes their probe hint `on ground` instead of
suggesting the invalid `in "ground"`.

### A `look` hit is not a handle (8.0)
The prober uses `look` because it is free. But Icesus' `look` parser is more
permissive than the ones behind `get`, `sell` and `sacrifice`, so a look hit
proves only that the string names the item TO LOOK. Recording that as a proven
handle is how the package talked itself into certainty about a string no action
could use: `l cerbie's skin on ground` answers, `get cerbie's skin` does not,
and every run afterwards sent the same dead string with full confidence.

Handles now carry the verb that proved them. `act` (a get / put / sell /
sacrifice actually moved the item, or you typed `ihandle ... force`) outranks
`look`, never downgrades, and shadows it entirely when choosing what to send —
so a look-proven string is a candidate for the ladder, not a command. `iitem`
marks the difference. Existing saves are seeded as look-proven, which costs
nothing: the first successful action promotes the string that worked.

Four mechanisms that should have caught the bad handle were all disabled at
once, and each is fixed:
  * verification was armed only when NO handle was known, so the check that
    can disprove a handle was off exactly when the package was most sure of
    itself. Every get is armed now.
  * iloot never read the answer to its own gets. `ishop` and `isac` walk the
    ladder when a command reaches nothing; the loot path now does too, matching
    replies by the handle they quote (a refusal names the exact string sent),
    up to 3 alternatives, then raising an `ihandle` request.
  * `i weight` fired immediately after the get burst, so the sort ran and
    closed the run while any retry was still in flight. It is now gated on
    every get having been answered, with a 4-second backstop.
  * the room scan was discarded before the refusal arrived, leaving the
    failure with no owner: the type key "piece of cerbie's skin" does not
    contain the handle "cerbie's skin", so nothing was demoted. The scan is
    kept until the run ends.

Ambiguity scopes accumulate into a set instead of collapsing. A second,
different scope used to rewrite the entry as "any" — blocking the handle
everywhere, permanently. Two ordinary observations (`skin` is shadowed in your
pack; `skin` is shadowed on this floor) were enough to forbid `skin from
"loot"` forever, a context neither observation described. Recording
{inventory, ground} keeps both facts and invents no third. A ground shadow is
also re-checked against the room: with no rival actually present it is stale,
and it is cleared rather than obeyed.

### ihandle: stale requests self-prune (7.9)
A type only needs a handle from you while you still hold one to test it on.
Both give-up sites — `onSacNothing` and `onNotCarried` — prune the instance
from the location map immediately after marking the type stuck, so an entry
raised on the LAST instance was born dead and then nagged at the tail of every
ishop / isac / iprobe run forever after. `inv.stuckList` only asked whether the
TYPE was known, which is permanent knowledge and says nothing about what is in
the bags. It now checks the map: an entry with no instance anywhere is dropped,
one that moved bags is re-pointed at its current container, and one with other
instances left is kept. Dropping is safe because markStuck fires at the point
of failure — an entry pruned on a stale map comes straight back the next time
an action misses — and the refused-handle list it would have shown you lives on
the type, not on the entry.

### Which bags are touched automatically
Only the disposal sacks: `loot` and `treasure`. iloot fills them, and ishop and
isac appraise, sell and sacrifice from them. `gear` is never read for disposal
and nothing is ever pulled from it — it is only tracked and annotated when you
look inside. Change the set with the disposalSacks/bagOrder config values.

The altar's echo is used as a VETO: it cannot say which type was consumed, but
if it names a word the queued type does not contain, the handle reached
something else, so the favour is not recorded and the handle is marked
ambiguous. A container scan now always reports what it concluded.

Handles that have not been proven are sent using a conservative ladder — the
"of" form, the compound-noun tail, then the bare noun. The full display name is
enumerated only while probing, never sent as a command, because it is usually
not a valid handle.

Room lines listing several items joined by " and " are split, and
`iclean junk` removes composite types created by the old parser.

### Auto-loot: iloot
Scans the room and attempts individual gets. Mobs and fixtures are learned
empirically: a get that refuses ("you cannot move" / "you see no") marks that
name as a non-item, persisted and skipped on future runs. For the items:
  * individual `get <item>` for each wanted item (keep -> bag, unknown -> loose)
  * trash / established-cheap / excluded / known non-items -> left in the room
  * unknowns go loose, auto-weighed via `i weight`, then sorted into bags
  * keep items (max(silver, favour*10) per litre >= cutoff) -> disposal bags
    (loot, treasure, in order; spills to next when full)
  * trash (>=1 sample, <= cutoff/5) and established-below-cutoff -> left
  * un-pickable (too heavy / cannot move / no room) -> skipped & remembered
Every command is echoed. Exclude items manually with `iloot exclude <name>`.

### Shop & altar disposal
  * `ishop` (at a shop): `value` unknowns (pulled loose if bagged), `sell`
    sell-route items, defer sacrifice-route to an altar.
  * `isac` (at an altar): sacrifice all sac-route items, one at a time.

### Commands
* `iloot` | `iloot sort` | `iloot cutoff <n>`
* `iloot exclude <name>` | `iloot unexclude <name>` | `iloot excludes`
* `iloot include <name>` - undo a wrongly learned "non-item"
* `iloot coins` | `iloot coins on|off` - coin densities, and which pass the cutoff
* `icorpse` | `icorpse skin|quick|scan|nodig` | `icorpse dig <cmd>` - loot a room's corpses
* `iskin` | `iskin on|off` | `iskin quiet <n>` - skin every corpse here, then register the hides
* `ihandle reset <name>` - forget every refused handle for a type
* `ishop` | `isac` | `isac learn` | `ishops` | `idrops [mob]` | `ibank` - deposit all but 500 mithril, from bags & loose
* `iinv` | `iitem <name>` | `iworth [rate <n>]` | `icont`
* `iprobe` | `iprobe all` | `iprobe <name>` | `iprobe status` | `iprobe stop`
* `iprobe auto on|off` | `iprobe room on|off` | `iprobe quiet on|off`
* `iclean junk` | `iclean ghosts` - purge composite and short-form junk types
* `iannot [on|off|col <n>]` | `itrack on|off|save`

Tuning: cutoffSL=100, dfToSilver=10, trashDiv=5, estN=3, probeMax=24.
Data persists to icesus_inventory2.lua (autosave 2 min).
]]
version = [[9.14]]
created = "2026-06-09T12:30:00+02:00"
