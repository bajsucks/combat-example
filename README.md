# Example combat game

That's an ECS game

## Basic instructions
You can build the project using `argon build` or, in Visual Studio Code, Ctrl + Shift + P -> Argon: Open Menu -> Build

Note that if built from source, the place will only contain scripts!

### Info
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