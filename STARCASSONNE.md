# 🖖 Starcassonne — Star Trek Carcassonne

A Star Trek-themed reskin of the classic tile-placement game Carcassonne.

---

## 🗺️ Feature Type Mappings

| Carcassonne | Starcassonne | Notes |
|-------------|--------------|-------|
| **City** | **Sector** | Enclosed, must be completed to score fully. Represents a fully controlled region of space (e.g. a star system under unified control) |
| **Road** | **Warp Corridor** | Linear hyperspace lanes connecting sectors. Must terminate at a junction, sector, or dead-end to score |
| **Field / Meadow** | **Open Space** | The vast background of unclaimed space. Scores at game end based on adjacent completed Sectors |
| **Monastery / Cloister** | **Colony** | An isolated inhabited world or outpost. Scores based on how many surrounding tiles are placed |
| **River** | **Nebula** | A hazardous flowing region that shapes the initial layout of the map (used in the setup variant) |

---

## 🛡️ Pennant Equivalent

> **Starbase** 🚀

A Starbase built within a Sector increases its value when scored. Each Starbase icon on a Sector tile adds bonus points when that Sector is completed.

---

## 👾 Factions (Meeple Colors)

| Color | Faction |
|-------|---------|
| 🔵 Blue | Federation |
| 🟡 Yellow | Cardassian |
| 🔴 Red | Klingon |
| ⚫ Black | Borg |
| 🟢 Green | Romulan |
| 🟣 Purple | Bajoran |

---

## 🚀 Meeple Equivalent — Ship

Each player's claim piece is a **Ship**, shaped and styled to match their chosen faction. Each faction has a distinct ship silhouette true to Star Trek lore.

| Faction | Ship Type |
|---------|-----------|
| 🔵 Federation | Constitution / Galaxy-class (Starfleet silhouette) |
| 🟡 Cardassian | Galor-class Warship |
| 🔴 Klingon | Bird-of-Prey |
| ⚫ Borg | Borg Cube |
| 🟢 Romulan | D'deridex Warbird |
| 🟣 Bajoran | Bajoran Solar Sailor |

> **Mining Ship** (Abbot equivalent) is a separate shared piece — a generic freighter/mining vessel, distinct from faction ships.

---

## ⛏️ Special Feature Mappings

| Carcassonne | Starcassonne | Notes |
|-------------|--------------|-------|
| **Garden** | **Dilithium Asteroid** | A rare resource-rich asteroid field. Scores like a Colony (based on surrounding tiles). Can only be claimed by a Mining Ship |
| **Abbot** | **Mining Ship** | Special meeple placed on a Dilithium Asteroid (or Colony). Can be recalled on your turn to score immediately, then redeployed |
| **Farmer** | **Trader** | A ship deployed to Open Space. Never returns during the game. Scores 3pts per completed adjacent Sector at game end. |
| **Crossroads / Village** | **Space Outpost** | Junction where Warp Corridors branch and terminate. Roads end at outposts (score as complete). Ships cannot occupy outposts. |

---

## 🃏 Tile Set (72 Tiles)

Tile distribution mirrors the base Carcassonne game. Labels A–X with thematic names TBD.

| Label | Base Game Description | Count | Starcassonne Name (TBD) |
|-------|-----------------------|-------|--------------------------|
| A | Monastery only | 4 | Colony (isolated) |
| B | Monastery + road | 2 | Colony + Warp Corridor |
| C | Full 4-sided city (pennant) | 1 | *(Sector — all sides, pennant)* |
| D | Single city + through road | 4 | *(Sector + Warp Corridor through)* |
| E | Single city only | 5 | *(Single-side Sector)* |
| F | Two opposite cities connected (pennant) | 2 | *(Dual Sector, pennant)* |
| G | Two opposite cities connected | 1 | *(Dual Sector)* |
| H | Two separate cities (opposite) | 3 | *(Split Sectors)* |
| I | Two separate cities (corner) | 2 | *(Corner Split Sectors)* |
| J | Single city + curved road | 3 | *(Sector + Warp turn)* |
| K | Single city + curved road | 3 | *(Sector + Warp turn alt)* |
| L | Single city + 3-way road junction | 3 | *(Sector + Tri-junction)* |
| M | Two adjacent cities connected (pennant) | 2 | *(Adjacent Sectors, pennant)* |
| N | Two adjacent cities connected | 3 | *(Adjacent Sectors)* |
| O | Two adjacent cities connected + road (pennant) | 2 | *(Adjacent Sectors + Warp, pennant)* |
| P | Two adjacent cities connected + road | 3 | *(Adjacent Sectors + Warp)* |
| Q | Three-sided city (pennant) | 1 | *(3-sided Sector, pennant)* |
| R | Three-sided city | 3 | *(3-sided Sector)* |
| S | Three-sided city + road (pennant) | 2 | *(3-sided Sector + Warp, pennant)* |
| T | Three-sided city + road | 1 | *(3-sided Sector + Warp)* |
| U | Straight road (N–S) | 8 | *(Straight Warp Corridor)* |
| V | Curved road (corner) | 9 | *(Warp Corridor bend)* |
| W | Three-way road junction | 4 | *(Tri-junction)* |
| X | Four-way road junction | 1 | *(Quad-junction / Crossroads)* |

---

## 📐 Rules Notes

- Core mechanics are unchanged from base Carcassonne
- **Sectors** = Cities (must be enclosed/completed to score fully)
- **Warp Corridors** = Roads (score when they terminate)
- **Open Space** = Fields (score at game end based on adjacent completed Sectors)
- **Colonies** = Monasteries (score based on surrounding tile count, max 9 pts)
- **Nebula** = River (setup variant only, replaces standard starting tile sequence)

---

## 🚧 Still To Decide

- [x] Garden → Dilithium Asteroid
- [x] Abbot → Mining Ship
- [x] Pennant → Starbase
- [x] Meeple → Ship (faction-specific silhouette)
- [x] Thematic names for each tile (A–X) — N/A, not needed
- [x] Starting tile — N/A, covered by the Nebula setup (Nebula Core is the first tile placed; River rules replace the standard starting tile entirely)
- [ ] Any special/unique tiles beyond the base 72?
- [x] Art style — SVG wireframe for prototype phase, proves out mechanics before final art
- [x] Implementation — Native iPad app (Swift / SwiftUI), offline play. Tiles drawn in SwiftUI Canvas. No Xcode-less path — requires Mac + Xcode to build and deploy.
