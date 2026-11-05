# ASUS TUF F17 FX707VV: fix for not waking from suspend on Linux

**Symptom:** after suspend (s2idle) the laptop never wakes up. The power button, the lid and the keyboard do nothing, and only a hard power-off brings it back.

**Tested on:** ASUS TUF Gaming F17 FX707VV, BIOS 332, Arch Linux ([Omarchy](https://omarchy.org/)), Limine bootloader.

## Cause

The embedded controller reports the power button, lid and keyboard events through GPE `0x02` (`_GPE._L02`). No device in the DSDT declares GPE `0x02` in a `_PRW` (wake) method, so Linux disarms it while in s2idle and nothing can wake the machine.

S3 (`deep`) sleep doesn't work at all on this model: it won't even resume on an RTC alarm. That leaves s2idle as the only usable mode.

## Fix

A small SSDT ([`lid-prw.asl`](lid-prw.asl)) adds `_PRW {0x02, 0}` to the lid device `\_SB.PC00.LPCB.LID0`. The kernel loads it at boot through the mkinitcpio `acpi_override` hook. The table has to be present at boot: a dummy device with the same `_PRW` loaded at runtime does **not** work.

```bash
git clone https://github.com/fedorrodicev-lgtm/asus-tuf-fx707vv-suspend-fix
cd asus-tuf-fx707vv-suspend-fix
sudo ./lid-fix.sh install    # copies the table, adds the hook, rebuilds the initramfs
# reboot
./lid-fix.sh status          # LID0 should be *enabled, gpe02 should be EN enabled
```

To undo it, run `sudo ./lid-fix.sh remove` and reboot.

The script rebuilds with `limine-mkinitcpio` when it's available, and otherwise falls back to `mkinitcpio -P`. With another initramfs generator (dracut, booster), load `lid-prw.aml` the way that tool supports instead.

## Rebuilding the table

`lid-prw.aml` is compiled from `lid-prw.asl`. To check it or rebuild it yourself:

```bash
iasl lid-prw.asl    # from the acpica package
```

Before trying this on another model, first check that `LID0` exists at the same path in your DSDT (`sudo acpidump -b -n DSDT && iasl -d dsdt.dat`).

## After a BIOS update

Run `./lid-fix.sh status` again. If ASUS fixes the DSDT, the override is no longer needed and can be removed.

## Credits

Based on [rexoos/linux_sleep_fix](https://github.com/rexoos/linux_sleep_fix) for the FX507.
