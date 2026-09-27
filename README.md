# stats-fan-keeper

A tiny workaround for the [Stats](https://github.com/exelban/stats) macOS app: it keeps the
manual fan speed you set in Stats from reverting to automatic a few seconds later.

Related upstream issue: [exelban/stats#3371](https://github.com/exelban/stats/issues/3371).
Remove this once Stats handles it itself.

## The problem

On Apple Silicon (M1 to M4), Stats takes over the fans once by writing to the SMC
(`Ftst=1`, then fan mode `F<n>Md=1`) and never checks again. macOS's `thermalmonitord`
can later take the fans back (fan mode goes to `3`, "system"), so the speed you picked in
Stats silently cuts out, even while the Mac is still hot.

Seen on: MacBook Pro M4 Pro, macOS 27.0, Stats 3.0.17.

## What this does

A root launchd job runs `stats-fan-keeper.sh` every 5 seconds. It:

1. does nothing unless Stats is running,
2. reads the fan settings Stats already saves (`fan_<n>_mode`, `fan_<n>_speed` in
   `~/Library/Preferences/eu.exelban.Stats.plist`),
3. for each fan set to manual in Stats, checks the live mode with Stats' own `smc` tool,
4. if macOS took the fan back, re-applies your speed with that same `smc` tool.

Fans on Auto in Stats are left alone. You keep controlling everything from Stats.

## Install

Requires Stats in `/Applications` with its fan helper already installed and working.

```sh
git clone https://github.com/jamubc/stats-fan-keeper.git
cd stats-fan-keeper
./install.sh      # asks for your password
```

Watch it restore settings:

```sh
log stream --predicate 'eventMessage CONTAINS "stats-fan-keeper"'
```

## Uninstall

```sh
./uninstall.sh
```

## Notes

- Your speed can drop for up to 5 seconds before it is restored.
- Setting very low speeds under heavy load is your responsibility. macOS will not step in
  while this is running and Stats is on manual.
- If you edit the script, re-run `./install.sh` to copy it into place.

## License

MIT
