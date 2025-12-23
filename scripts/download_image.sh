#!/bin/bash

# URL for DietPi NanoPi NEO image (ARMv7)
# Note: Links can change, checking DietPi website is recommended.
# This is the direct link for NanoPi NEO (Bullseye/Bookworm depending on release)
IMAGE_URL="https://dietpi.com/downloads/images/DietPi_NanoPiNEO-ARMv7-Bookworm.7z"
OUTPUT_FILE="DietPi_NanoPiNEO.7z"

echo "Downloading DietPi image for NanoPi NEO..."
curl -L -o "$OUTPUT_FILE" "$IMAGE_URL"

if [ $? -eq 0 ]; then
    echo "Download complete: $OUTPUT_FILE"
    echo "Please unzip this file and flash the .img to your SD card."
    echo "Recommended tool: BalenaEtcher or Raspberry Pi Imager."
else
    echo "Download failed."
    exit 1
fi
