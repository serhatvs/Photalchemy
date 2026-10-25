# Photalchemy

**Explore the real world. Turn photos into cards. Fight your way home.**

Photalchemy is a **location-based, turn-based card game for mobile** where the places you visit and the photos you take shape your deck. The game combines real-world exploration, photo-based card generation, and strategic dungeon battles.

> **Project status:** Early planning / pre-development. The mechanics described below are the current design direction, not a list of completed features.

## The Story

You are an alchemist whose experiment goes wrong, leaving you trapped inside a mysterious dungeon. Your bag is more than an ordinary bag: it connects the dungeon to the real world.

Use that connection to bring the world into your adventure. Capture photos, transform them into cards, defeat enemies, grow stronger, and find a way home.

## Core Gameplay

1. **Explore** — Visit different places in the real world.
2. **Capture** — Take photos using your phone.
3. **Transmute** — Convert each photo into a playable card based on its visual properties.
4. **Build a strategy** — Choose when to attack, defend, stun, or reflect an enemy's move.
5. **Battle** — Progress through turn-based dungeon encounters and improve your collection.

### Photo-to-Card System

The proposed card-generation system analyzes **color distribution and intensity** in an image rather than relying on full object recognition. Those visual properties help determine the resulting card's type or attributes.

Location contributes to **card rarity and power**. Repeatedly taking pictures in the same area may yield weaker cards, while exploring unfamiliar places should offer better opportunities. The exact distance thresholds and balance rules are still being designed.

### Card Classes

The initial design includes four core card classes:

| Class | Role |
| --- | --- |
| **Attack** | Deal damage to enemies. |
| **Defense** | Reduce or block incoming damage. |
| **Stun** | Disrupt an enemy's turn or action. |
| **Reflect** | Turn an opponent's attack back against them. |

Further card attributes, effects, and balancing rules are subject to prototyping.

### Dungeon Battles

Combat is designed around **turn-based card choices**, with enemies that respond to the player's strategy. **AI-assisted enemy decision-making** is being considered; the final approach has not yet been selected.

## Why Photalchemy?

Many mobile games can be played without ever changing your surroundings. Photalchemy aims to make *going somewhere new* part of the game: exploring your city becomes a meaningful way to expand your deck.

Instead of rewarding players for repeatedly photographing one spot, the design encourages discovery and variety.

## Development Roadmap

- [ ] Finalize the core gameplay rules and mobile tech stack.
- [ ] Prototype photo color analysis and card generation.
- [ ] Implement location-based rarity and anti-repetition rules.
- [ ] Build the four card classes and turn-based combat.
- [ ] Create dungeon encounters and enemy decision-making.
- [ ] Add progression, balancing, and a playable mobile interface.
- [ ] Test the complete exploration-to-battle gameplay loop.

## Getting Started

Photalchemy is currently in the **concept and planning phase**. No runnable application or installation instructions are available yet. Setup steps will be added when the first implementation is committed.

## Team

Created for the **COMP205 Mobile Programming** course.

- [Serhat Yavuz](https://github.com/serhatvs)
- [Ali Çavdar](https://github.com/cavdara549-create)
- [Kadir Zongur](https://github.com/kadirzongur64-byte)
- [Şükrü Öztürk](https://github.com/sukrucanozturk98)

## License

Distributed under the [MIT License](LICENSE).
