#!/usr/bin/env bash
set -e

# Install dependencies
sudo apt-get update -y
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# Install Flutter SDK
FLUTTER_VERSION=3.35.5 # pick the version you use
curl -LO https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
tar xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
sudo mv flutter /usr/local/flutter
echo 'export PATH="/usr/local/flutter/bin:$PATH"' >> ~/.bashrc

# Precache web dependencies
export PATH="/usr/local/flutter/bin:$PATH"
flutter config --enable-web
flutter precache --web
flutter doctor

