# Flash guide — Aurora Sweep (Jonatan)

Splitkb **Aurora Sweep** (34-key columnar split) with **nice!nano v2** on each half. Flash **left** and **right** separately; they use different UF2 files from the same CI build.

---

## Hardware

| Half | MCU | Shield (ZMK) |
|------|-----|--------------|
| Left | nice!nano v2 | `splitkb_aurora_sweep_left` |
| Right | nice!nano v2 | `splitkb_aurora_sweep_right` |

Connect **one half at a time** over USB for flashing. Power off or disconnect the other half to avoid confusion.

---

## Where the UF2s come from

Builds run in GitHub Actions on [`jborkowski/zmk-config`](https://github.com/jborkowski/zmk-config) (`build.yaml` → `nice_nano//zmk` + Aurora Sweep shields).

**Option A — download locally**

```bash
gh workflow run build.yml -R jborkowski/zmk-config
gh run watch -R jborkowski/zmk-config --exit-status
gh run download <run-id> -R jborkowski/zmk-config \
  -D /Users/jonatan/sources/zmk-config/firmware-artifacts
```

**Option B — GitHub UI:** Actions → latest successful **Build** run → Artifacts.

Look for Aurora Sweep UF2s under `firmware-artifacts/firmware/` (or the Actions artifact zip):

- `splitkb_aurora_sweep_left-nice_nano__zmk-zmk.uf2`
- `splitkb_aurora_sweep_right-nice_nano__zmk-zmk.uf2`

Latest successful build: https://github.com/jborkowski/zmk-config/actions/runs/29640814207

Local copies (already downloaded):

- `/Users/jonatan/sources/zmk-config/firmware-artifacts/firmware/splitkb_aurora_sweep_left-nice_nano__zmk-zmk.uf2`
- `/Users/jonatan/sources/zmk-config/firmware-artifacts/firmware/splitkb_aurora_sweep_right-nice_nano__zmk-zmk.uf2`

---

## Flash steps (LEFT, then RIGHT)

Use UF2s from the **same** workflow run for both halves.

### Left half

1. Plug in the **left** half only (USB on the nice!nano).
2. **Double-tap RST** on the nice!nano (or tap RST twice quickly). A drive named **NICE!NANO** appears.
3. Copy the **left** `zmk.uf2` onto the drive root. The board reboots when done.
4. Unplug when the drive ejects / LED activity stops.

### Right half

5. Plug in the **right** half only.
6. Double-tap **RST** → **NICE!NANO** drive mounts.
7. Copy the **right** `zmk.uf2` onto the drive root.
8. Unplug after reboot.

Both halves should now run the same firmware revision.

---

## Bluetooth after long idle

If the keyboard does not reconnect after weeks/months:

1. **On the host** (Mac): remove the old “Sweep” / “nice!nano” pairing in System Settings → Bluetooth.
2. **On the keyboard:** pair again from the host’s Bluetooth menu (usually the left half advertises first).
3. **Clear stale bonds on the keyboard** if needed: open the **FUN** layer (see smoke-check) and tap **BT_CLR** (clears the active BT profile). **BT_SEL 0–2** switch profiles on that layer.

Bond data survives reflashing; clearing host + keyboard bonds avoids mismatched keys.

---

## Smoke-check (your keymap)

Keymap: `config/splitkb_aurora_sweep.keymap`

| Check | How |
|-------|-----|
| **Colemak (DEF)** | Top row `Q W F P G`; home-row mods unchanged (`hm_*`). |
| **SYM** | Hold thumb **Tab** key (left inner thumb). |
| **NAV** | Hold thumb **Space** (left outer thumb). |
| **MEDIA** | Hold thumb **Esc** (right inner thumb). |
| **NUM** | Hold thumb **Enter** (right outer thumb). |
| **MOUSE** (conditional) | Hold **SYM + NUM** together → pointer layer (`mkp` / `mmv` / `msc`). |
| **FUN** (conditional) | Hold **NAV + MEDIA** together → F-keys, **BT_SEL** / **BT_CLR**, bootloader reset. |

Home-row mods (`hm_o`, `hm_m`, `hm_i`) and combos/macros come from shared `behaviors.dtsi` / `combos.dtsi`.

---

## Troubleshooting

- **Wrong half flashed:** symptoms include keys mirrored or half not talking over TRRS — re-flash with the correct left/right UF2.
- **No NICE!NANO drive:** retry double-tap RST; try another USB cable/port (data-capable).
- **Split not working:** both halves must share the same build; check TRRS cable is seated before wireless use.
