# Carcassonne Mechanics Reference
## (For use when building Starcassonne)

This document is a precise reference to Carcassonne rules so I don't make implementation mistakes.

---

## Tile Features

| Feature | Starcassonne Name | Description |
|---------|-------------------|-------------|
| City | Sector | Enclosed area of connected city edges. Scores when fully surrounded (all open sides walled off) |
| Road | Warp Corridor | Linear path. Scores when both ends terminate (city, crossroads, or dead-end cap) |
| Field (Meadow) | Open Space | Background land. Only scores at game END via farmers |
| Monastery | Colony | Isolated building. Scores 9pts when surrounded by 8 tiles |
| Garden | Dilithium Asteroid | Same as monastery, but only Abbot (Mining Ship) can be placed on it |
| River | Nebula | Setup-only feature. Not a scoreable feature. Ships CANNOT be placed on the stream |

---

## The River / Nebula Phase — EXACT RULES

### Setup
1. **Source tile** is placed at the start by the game (not a player action, not a player turn).
   - Source has **only ONE valid exit direction** — the stream exits in one fixed direction. Players have no choice. Source has **no monastery**.
2. **Lake tile** is set aside and placed at the **bottom** of the shuffled river tile stack so it is always drawn and placed last.
3. The **10 middle river tiles are shuffled** into a random order.

### Placement Turn
4. On their turn a player draws the next river tile and **must** place it extending the stream from the last tile placed.
5. **Tiles CAN be rotated** — including river tiles. The player rotates the tile until the stream entry connects to the current stream endpoint, then places it.
6. **Stream connectivity required**: The tile's stream ENTRY edge must face back toward the previous tile (i.e., connect to where the stream last exited).
7. **U-turn rule**: A river tile cannot be placed so the stream flows back in the exact direction it came from (immediate reversal). e.g. if the stream just flowed South, the next tile cannot flow North.
8. **No same-direction double-turn**: The stream cannot turn twice consecutively in the same rotational direction (prevents circular spirals). e.g. two consecutive right-turn tiles are illegal.
9. If a tile cannot be legally placed it is **silently discarded** and the next tile is drawn automatically. The player never sees or interacts with this — it just happens. In practice with the standard tile set this almost never occurs.

### End of Nebula Phase
10. The **Lake tile** is always last. When the Lake is placed the Nebula phase ends and normal Exploration begins immediately (next player draws from the main deck).
11. The Lake tile **has a Colony (monastery)** on it — the only Nebula tile that does.

### Ship Rules During Nebula Phase
12. Players **MAY** deploy a ship on any city (Sector), road (Warp Corridor), or field (Open Space) region on a Nebula tile after placing it.
13. Ships **CANNOT** be placed on the nebula stream itself — the stream is not a scoreable feature.
14. The nebula stream is drawn visually through each tile from entry edge to exit edge.

### Tile Geometry — CRITICAL
- Each river tile has a **stream edge** on exactly **two** sides — the entry and exit. These edges carry ONLY the stream. No city (Sector), road (Warp Corridor), or other terrain can exist on stream edges.
- The **other two edges** of each river tile carry normal terrain (field, city, or road) — just like any regular tile.
- Adjacent river tiles must connect stream-edge to stream-edge (the stream is continuous).
- The river acts as a **field boundary** — fields on opposite sides of the river are separate farm regions (like a road separating fields).
- This means: **you CANNOT have a Sector or Warp Corridor on top of / across the Nebula stream**. Just as in Carcassonne you cannot have a city on the river.

### Exact Carcassonne River I Tile Set (12 tiles total)
All terrain listed is for non-stream edges only. Stream edges show only the stream.

| Tile | Count | Stream | Non-stream edges | Special |
|------|-------|--------|------------------|---------|
| Source | 1 | exits S | all openSpace | Auto-placed first, exits south |
| Two Cities (CICI) | 1 | W→E | N=sector, S=sector (separate) | Two independent sectors |
| City + Road (CIRI) | 1 | W→E | N=sector, S=warpCorridor | |
| Road + Open (LIRI) | 1 | W→E | N=openSpace, S=warpCorridor | No colony (colony only on Lake) |
| Roads Crossing (RIrI) | 1 | N→S | E=warpCorridor, W=warpCorridor | |
| Plain Straight (IFI) | 2 | W→E | all openSpace | |
| Corner Sector (CcII) | 1 | S→E | N=sector, W=sector (connected) | Corner city spans N+W |
| Corner Roads (RrII) | 1 | W→S | N=warpCorridor, E=warpCorridor | |
| Plain Curved (II) | 2 | W→S | all openSpace | |
| Lake | 1 | enters W | all openSpace | Has Colony. Always last. |

**Total: 12 tiles** (1 source + 10 middle + 1 lake)

---

## Tile Placement Rules

1. A tile must be placed **adjacent to at least one existing tile**.
2. **All shared edges must match**: City-to-City, Road-to-Road, Field-to-Field. You cannot place a city edge against a field edge.
3. The tile **may be rotated** any of 4 ways (0°, 90°, 180°, 270°) before placement.
4. If a drawn tile cannot be placed anywhere legally, it is **discarded** and another tile is drawn.

---

## Ship (Meeple) Placement Rules

1. After placing a tile, the player **may optionally** deploy one ship from their supply onto the **just-placed tile**.
2. A ship may be placed on a **City (Sector)**, **Road (Warp Corridor)**, **Field (Open Space)**, **Monastery (Colony)**, or **Garden (Dilithium Asteroid)**.
3. **A ship can only be placed if that feature is currently unoccupied** — no feature may have ships from different players (checked at game end for connected features that merge).
4. Ships on a **completed feature are returned to their owner** immediately (before next turn).
5. The **Mining Ship (Abbot)** is a special separate piece that can ONLY be placed on a Colony or Dilithium Asteroid. On your turn (instead of placing a tile) you may retrieve and redeploy your Mining Ship.
6. Players have **7 regular ships** each. If all are deployed, you cannot place another until one is returned.

---

## Scoring — During Game (when features complete)

### Sectors (Cities)
- A Sector is **complete** when every open edge is enclosed by other tiles.
- Score: **2 points per tile** in the sector + **2 points per Starbase (pennant)** in the sector.
- If incomplete at game end: **1 point per tile** + **1 point per Starbase**.
- Player(s) with most ships in sector score it. Ties = all tied players score full.

### Warp Corridors (Roads)
- A Corridor is **complete** when both ends terminate at a city, crossroads, or a capped dead-end.
- Score: **1 point per tile** the corridor passes through.
- Incomplete at game end: same 1 point per tile.

### Colonies (Monasteries)
- A Colony is **complete** when all 8 surrounding tiles are placed.
- Score: **9 points** (1 for the colony tile + 8 surrounding).
- Incomplete at game end: 1 point per tile in the 3×3 area (including colony tile).

### Dilithium Asteroids (Gardens)
- Scored **identically to Colonies**. Only Mining Ship can occupy them.

---

## Scoring — End Game (fields/open space)

### Open Space (Fields/Meadows)
- Scored ONLY at game end.
- Each field region is evaluated for adjacent **completed** Sectors.
- The player with the most ships in a field scores **3 points per completed Sector** that field touches.
- Ties = all tied players score full.
- Ships in fields are NEVER returned during the game.

---

## Turn Order

1. **Draw** a tile from the deck (or discard if unplaceable, draw again).
2. **Place** the tile adjacent to existing tiles, edges matching.
3. **Optionally deploy** one ship from your supply onto the placed tile.
4. **Score** any features that are now complete (return ships from completed features).
5. **Pass** to next player.

---

## End Game Trigger

- When the **last tile from the deck is placed**, the game ends after that turn.
- All remaining incomplete features are scored at reduced rates.
- Open Space (field) scoring happens.
- Player with highest total score wins.

---

## Edge Connectivity (Critical for implementation)

Two city edges on the same tile may be:
- **Connected** (same city, forms one region) — e.g. Tile N: N+E connected
- **Separate** (different cities, two independent regions) — e.g. Tile I: N+E separate

This affects:
- Which tiles are part of the same city when placed adjacent
- Which ships compete for the same city
- Whether a city is "complete" (all of its connected tiles must be enclosed)

Roads similarly: Tile X (4-way junction) has 4 **separate** road ends, not one connected road.

---

## Starcassonne-Specific Notes

- **Nebula tiles** are placed first, 12 total, before main deck.
- **Source** = first nebula tile, single fixed exit direction (South), no features.
- **Lake** = last nebula tile, has Colony (monastery). Ends Nebula phase.
- **Mining Ship** (Abbot) can be recalled and redeployed on your turn instead of normal play.
- **Traders** = ships placed on Open Space (the farmer equivalent). They never return during the game and score 3pts per completed Sector adjacent to their field region at game end.
- **Space Outpost** = the village/crossroads equivalent. A junction where Warp Corridors terminate and branch. Roads ending at a crossroads are scored as complete (road ends at the outpost). Ships cannot be placed on outposts.
- All other mechanics identical to base Carcassonne.

## Complete Thematic Name Mapping

| Carcassonne | Starcassonne | Color | Notes |
|-------------|--------------|-------|-------|
| City | Sector | Blue | Enclosed area; scores 2pt/tile when complete |
| Road | Warp Corridor | Cyan | Linear path between terminators |
| Field/Meadow | Open Space | Gray/dark | Ships here = Traders |
| Monastery | Colony | Green | 9pts when surrounded by 8 tiles |
| Garden | Dilithium Asteroid | Yellow | Colony equivalent; Mining Ship only |
| River | Nebula | Purple | Setup phase only; 12 tiles |
| Pennant | Starbase | Orange | Bonus marker in Sectors |
| Meeple | Ship | Faction color | 7 per player |
| Abbot | Mining Ship | Faction color | 1 per player; Colony/Dilithium only |
| Farmer | Trader | Faction color | Ship on Open Space; end-game scorer |
| Crossroads/Village | Space Outpost | — | Terminates Warp Corridors at junction |
