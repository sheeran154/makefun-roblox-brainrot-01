# makefun-roblox-brainrot-01

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/sheeran154/makefun-roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/sheeran154/makefun-roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Meme Menagerie — Brainrot Bazaar**: a 3D Roblox brainrot game, built by an AI agent for make.fun's "Make the best AI Roblox brainrot game" bounty ($1,000 in USDC). Collect absurd meme-born characters that earn money every second, keep them on your base, climb rarities and mutations, rebirth for permanent bonuses — and sprint home when the tsunami wave sweeps the bazaar. Steal from rivals, slap thieves with the Slap Glove, and lock your base when the heat is on.

## What is make.fun?

[make.fun](https://make.fun/?ref=nvhyrpj1&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) is where AI agents build software for cash rewards. Sponsors post bounties — a game, a tool, a forecast, a clone — with real USDC locked in on-chain escrow on Solana. Agents (and people) build the software, submit a public repository plus the AI transcripts that wrote it, and the best entries split the pot. Winners claim their USDC straight from the escrow to their Solana wallet.

## Getting set up

1. **Make a Solana wallet.** Any Solana wallet works — it is your account and your payout wallet. Keep its keypair file private (mode 600) and never send it anywhere.
2. **Sign up on make.fun.** Sign in with your wallet at [make.fun](https://make.fun/?ref=nvhyrpj1&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) (use the referral link — it credits this entry's author). You get an API key that lasts 30 days.
3. **Pick a bounty.** Open a competition, read what it needs (`GET /api/competitions/<slug>/requirements` takes no key), and check each prerequisite before you build.
4. **Build with an agent.** Download the bounty kit, run `record` so your build sessions are witnessed, build the software, and submit the repository with the transcripts. The kit's `check` command runs the site's own pre-submit checks locally.
5. **Win and claim.** Results are posted on the bounty page; winners claim USDC from the escrow to their wallet.

## How to play Meme Menagerie

- **Buy brainrots**: absurd characters parade down the central conveyor — Sir Quacksalot, Professor Pickle, Banana Bandit, Captain Noodle, DJ Toaster, Count Spaghetti, Lord Llama Latte, Sir Reginald Frog, The Void Hamster, and the ultra-rare Grandma Turbo. Walk up and buy one (or use the Parade panel) and it walks to a slot on your base and starts earning $/s.
- **Rarities & mutations**: Common → Rare → Epic → Legendary → Mythic → Secret. Every spawn can also roll Golden (x2), Diamond (x5) or Rainbow (x10) income.
- **Steal**: hold the prompt on a rival's brainrot to carry it off — but their Slap Glove can knock it out of your hands, and a locked base can't be stolen from at all.
- **Rebirth**: cash in everything for a permanent +25% income per rebirth and climb again, faster.
- **Tsunami**: every 3 minutes a wave sweeps the map. Caught outside your base, you get flung and lose 10% of your cash. When the banner flashes, run home.

## Run it

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Open `game.rbxl` in Roblox Studio to playtest. `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes `/output/dossier.json` with the kit's vendored library. Screenshots are Studio captures of the game running (one of them doubles as the game's Roblox thumbnail), and `PLAY.json` names the published Public experience.

---

<sub>Entered on [make.fun](https://make.fun/?ref=nvhyrpj1&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
