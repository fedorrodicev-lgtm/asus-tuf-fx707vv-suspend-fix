/*
 * ASUS TUF F17 FX707VV (BIOS 332): wake from s2idle with the power button,
 * the lid and the keyboard.
 *
 * The EC signals these events through GPE 0x02 (_GPE._L02 -> ECLV -> LGPA).
 * No device in the DSDT lists GPE 0x02 in its _PRW, so Linux does not keep
 * it enabled during s2idle. Add a _PRW to the active LID0, as in the fix for
 * the FX507 (github.com/rexoos/linux_sleep_fix).
 *
 * Loaded at boot through the mkinitcpio acpi_override hook.
 */
DefinitionBlock ("", "SSDT", 2, "FX707", "LIDPRW", 0x00000001)
{
    External (\_SB.PC00.LPCB.LID0, DeviceObj)

    Scope (\_SB.PC00.LPCB.LID0)
    {
        Name (_PRW, Package (0x02)
        {
            0x02,
            Zero
        })
    }
}
