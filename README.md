# Example combat game

That's an ECS game

## Basic instructions
clone the repo and sync with rojo in a local place

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
- [HitboxClass](https://github.com/RedTrioVirus/HitboxClass) V1.1A