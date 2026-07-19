# Example combat game

This is an adaptable ECS combat system I made as a template to use in future projects.
Notes about the combat system:
- Hitboxes are fully client sided (what you see is what you get), but can still be used on server
- Server verifies the hitbox results
- You can spawn dummies using F4 -> `dummy`
- VFX is instant on the client and is also replicated to all other clients

## Basic instructions
You can download the .rbxl in the Releases tab.
You can also build the project yourself using `rojo build -o build.rbxl`, but it will lack cooldown ScreenGUI and a baseplate.

### Combat system features
- Stun
- Healthbars
- Cooldowns
- Hitbox visualizer
- Admin panel
- Dummies

### ECS Template info
Contains modules:

- Server, client and shared environment
- A shared controller
- A logger module
- Replication setup via mirror
- Data saving via ProfileStore
- World provider
- Project structure
- Player system
- Living system
- Packages

### Packages included
- [jecs](https://github.com/Ukendio/jecs) v.0.11.0
^ This has a custom iterator `world:targets(id, relation)` added, see https://github.com/Ukendio/jecs/issues/309
- [mirror](https://github.com/bajsucks/mirror)
^ This is a custom fork with manual hydration
- [jTools](https://github.com/bajsucks/jTools) version 7
- [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore)
- [Conch](https://github.com/alicesaidhi/conch)
- [Jabby](https://github.com/alicesaidhi/jabby/)
- [Hammer](https://github.com/Mark-Marks/hammer)
- [EZHitbox](https://github.com/Breezy1214/EZ-Hitbox) V5.0.0