#!/usr/bin/env bash
# Script to add test contacts to iOS Simulator
# This adds contacts that match the users in the backend

set -euo pipefail

# Get the UDID of the booted simulator
UDID=$(xcrun simctl list devices | grep -E "iPhone.*\(.*\).*Booted" | head -1 | sed -E 's/.*\(([0-9A-Fa-f-]+)\).*/\1/')

if [[ -z "$UDID" ]]; then
    echo "❌ No booted iOS simulator found. Please start the simulator first."
    exit 1
fi

echo "📱 Adding test contacts to simulator (UDID: $UDID)..."

# Create a temporary vCard file
VCARD_FILE=$(mktemp)

cat > "$VCARD_FILE" << 'EOF'
BEGIN:VCARD
VERSION:3.0
FN:Sonia
TEL;TYPE=CELL:+34606014680
END:VCARD
BEGIN:VCARD
VERSION:3.0
FN:Miquel
TEL;TYPE=CELL:+34626034421
END:VCARD
BEGIN:VCARD
VERSION:3.0
FN:Ada
TEL;TYPE=CELL:+34623949193
END:VCARD
BEGIN:VCARD
VERSION:3.0
FN:Sara
TEL;TYPE=CELL:+34611223344
END:VCARD
BEGIN:VCARD
VERSION:3.0
FN:TDB
TEL;TYPE=CELL:+34600000001
END:VCARD
BEGIN:VCARD
VERSION:3.0
FN:PolR
TEL;TYPE=CELL:+34600000002
END:VCARD
EOF

# Add contacts to simulator using simctl
xcrun simctl addmedia "$UDID" "$VCARD_FILE"

# Clean up
rm -f "$VCARD_FILE"

echo "✅ Test contacts added successfully!"
echo "📝 Added contacts:"
echo "   - Sonia: +34606014680"
echo "   - Miquel: +34626034421"
echo "   - Ada: +34623949193"
echo "   - Sara: +34611223344"
echo "   - TDB: +34600000001"
echo "   - PolR: +34600000002"
echo ""
echo "💡 These contacts match the users in the backend database"
