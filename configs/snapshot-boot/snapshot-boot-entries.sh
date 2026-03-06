#!/usr/bin/env bash
# Generate systemd-boot entries for recent Btrfs/snapper snapshots.
# Called by pacman hook and snapper post-snapshot hook.

set -euo pipefail

ENTRIES_DIR="/boot/loader/entries"
MAIN_ENTRY="${ENTRIES_DIR}/arch.conf"
SNAPSHOT_DIR="/.snapshots"
MAX_ENTRIES=5
PREFIX="arch-snapshot"

# Clean old snapshot entries
rm -f "${ENTRIES_DIR}/${PREFIX}"-*.conf

# Bail if main entry or snapshot dir missing
[[ -f "$MAIN_ENTRY" ]] || { echo "Main boot entry not found"; exit 1; }
[[ -d "$SNAPSHOT_DIR" ]] || { echo "Snapshot directory not found"; exit 1; }

# Read main entry to extract kernel, initrd, and options
MAIN_LINUX=$(grep '^linux' "$MAIN_ENTRY" | head -1 | sed 's/^linux[[:space:]]*//')
MAIN_OPTIONS=$(grep '^options' "$MAIN_ENTRY" | head -1 | sed 's/^options[[:space:]]*//')
# Collect all initrd lines
MAIN_INITRDS=$(grep '^initrd' "$MAIN_ENTRY" | sed 's/^initrd[[:space:]]*//')

# Get snapshot numbers sorted newest first
SNAPSHOTS=()
for dir in "$SNAPSHOT_DIR"/*/info.xml; do
    [[ -f "$dir" ]] || continue
    num=$(basename "$(dirname "$dir")")
    SNAPSHOTS+=("$num")
done

# Sort numerically descending (higher number = newer)
IFS=$'\n' SNAPSHOTS=($(sort -rn <<<"${SNAPSHOTS[*]}")); unset IFS

count=0
for num in "${SNAPSHOTS[@]}"; do
    [[ $count -ge $MAX_ENTRIES ]] && break

    info_xml="${SNAPSHOT_DIR}/${num}/info.xml"
    snapshot_subvol="${SNAPSHOT_DIR}/${num}/snapshot"

    # Verify the snapshot subvolume exists
    [[ -d "$snapshot_subvol" ]] || continue

    # Parse info.xml for date and description
    date=$(sed -n 's/.*<date>\(.*\)<\/date>.*/\1/p' "$info_xml" | head -1)
    desc=$(sed -n 's/.*<description>\(.*\)<\/description>.*/\1/p' "$info_xml" | head -1)
    snap_type=$(sed -n 's/.*<type>\(.*\)<\/type>.*/\1/p' "$info_xml" | head -1)

    # Format date for display (2026-03-05 13:00:00 -> 2026-03-05 13:00)
    display_date="${date%:*}"

    # Build title
    label="${desc:-${snap_type}}"
    title="Arch Linux (Snapshot #${num} - ${label} - ${display_date})"

    # Replace rootflags=subvol=@ with snapshot subvolume path
    snap_options=$(echo "$MAIN_OPTIONS" | sed "s|rootflags=subvol=@|rootflags=subvol=@snapshots/${num}/snapshot|")

    # Write entry with sort-key to push snapshots below main entry
    entry_file="${ENTRIES_DIR}/${PREFIX}-${num}.conf"
    {
        echo "title   ${title}"
        printf "sort-key 1-snapshot-%04d\n" "$num"
        echo "linux   ${MAIN_LINUX}"
        while IFS= read -r initrd; do
            echo "initrd  ${initrd}"
        done <<< "$MAIN_INITRDS"
        echo "options ${snap_options}"
    } > "$entry_file"

    count=$((count + 1))
done

echo "Generated ${count} snapshot boot entries"
