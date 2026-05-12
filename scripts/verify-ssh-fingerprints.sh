#!/bin/sh

set -eu

# Arguments
# $1: hostname
# $2: file containing the known fingerprints
# $3: optional: file to append the ssh-keyscan results to

# Constants

HOST_KEYS="${3:-host-keys}"
HASH_ALG='sha256'

# Functions

die() {
	printf '%s\n' "$1"
	exit 1
}

# Main

SCAN_TYPES=''
SEP=''
while IFS= read -r line ; do
	ALGO=$(echo "$line" | cut -d: -f1 | tr '[:lower:]' '[:upper:]')
	echo "$line" | cut -d: -f2-3 | tr -d '[= =]' > "$ALGO-fp"
	SCAN_TYPES="${SCAN_TYPES}${SEP}${ALGO}"
	SEP=','
done < "$2"

test "$SCAN_TYPES" || die "No key scan types given"

ssh-keyscan -O hashalg="$HASH_ALG" -t "$SCAN_TYPES" "$1" >> "$HOST_KEYS"
ssh-keygen -lf "$HOST_KEYS" > scanned-fingerprints

while IFS= read -r line ; do
	ALGO=$(echo "$line" | cut -d'(' -f2 | tr -d ')')
	FP=$(echo "$line" | cut -d' ' -f2)
	set +e
	RES=$(echo "$FP" | cmp "$ALGO-fp")
	test "$RES" && die "$ALGO fingerprint $FP does not match given value"
	set -e
done < scanned-fingerprints

#rm -rf *-fp host-keys scanned-fingerprints
