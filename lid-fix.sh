#!/bin/bash
# Wake from s2idle on the ASUS TUF F17 FX707VV: adds _PRW to LID0 (GPE 0x02)
# through the mkinitcpio acpi_override hook. Details in lid-prw.asl.
#
#   sudo ./lid-fix.sh install    install and rebuild the initramfs
#   sudo ./lid-fix.sh remove     undo and rebuild the initramfs
#   ./lid-fix.sh status          check that the kernel loaded the table (after a reboot)

set -euo pipefail
DIR="$(dirname "$(readlink -f "$0")")"
AML_SRC="$DIR/lid-prw.aml"
AML_DST=/etc/initcpio/acpi_override/lid-prw.aml
CONF=/etc/mkinitcpio.conf.d/zz-acpi-override.conf

need_root() { [[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }; }

# Omarchy/Limine rebuild with limine-mkinitcpio; plain Arch with mkinitcpio -P.
rebuild() {
  if command -v limine-mkinitcpio >/dev/null; then limine-mkinitcpio; else mkinitcpio -P; fi
}

case "${1:-}" in
  install)
    need_root
    [[ -s $AML_SRC ]] || { echo "Missing $AML_SRC"; exit 1; }
    mkdir -p "$(dirname "$AML_DST")"
    install -m 644 "$AML_SRC" "$AML_DST"
    echo 'HOOKS+=(acpi_override)' > "$CONF"
    echo ">>> Files in place, rebuilding the initramfs..."
    rebuild
    echo
    echo ">>> Done. Reboot, then run: $0 status"
    ;;
  remove)
    need_root
    rm -f "$AML_DST" "$CONF"
    rmdir --ignore-fail-on-non-empty "$(dirname "$AML_DST")" 2>/dev/null || true
    rebuild
    echo ">>> Removed. Reboot."
    ;;
  status)
    echo "--- table in the kernel:"
    journalctl -k -b 0 --no-pager | grep -iE "Table Upgrade|LIDPRW" || echo "NOT found"
    echo "--- /proc/acpi/wakeup (expect LID0 *enabled):"
    grep -E "^(Device|LID0)" /proc/acpi/wakeup
    echo "--- gpe02 (expect EN enabled):"
    cat /sys/firmware/acpi/interrupts/gpe02
    ;;
  *)
    sed -n '2,8p' "$0"
    ;;
esac
