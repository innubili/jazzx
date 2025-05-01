#!/bin/bash
# Usage: ./scripts/switch_audio_backend.sh [web|io]
# Switches flutter_sound dependency and IO implementation for web or mobile/desktop builds.

set -e
cd "$(dirname "$0")/.."

if [ "$1" = "web" ]; then
  echo "Switching to WEB audio backend (removing flutter_sound)..."
  # Comment out flutter_sound in pubspec.yaml
  sed -i '' "s/^\s*flutter_sound:/  # flutter_sound:/" pubspec.yaml
  # Comment out IO implementation code that references flutter_sound
  sed -i '' "s/^import \\?package:flutter_sound\/flutter_sound.dart\\?;/\/\/import 'package:flutter_sound\/flutter_sound.dart';/" lib/widgets/metronome_sound_player_io.dart
  sed -i '' "s/^  final FlutterSoundPlayer _tickPlayer/  \/\/  final FlutterSoundPlayer _tickPlayer/" lib/widgets/metronome_sound_player_io.dart
  sed -i '' "s/^  final FlutterSoundPlayer _tockPlayer/  \/\/  final FlutterSoundPlayer _tockPlayer/" lib/widgets/metronome_sound_player_io.dart
  echo "Running flutter pub get..."
  flutter pub get
  echo "Now ready for WEB build."
elif [ "$1" = "io" ]; then
  echo "Switching to IO (mobile/desktop) audio backend (restoring flutter_sound)..."
  # Uncomment flutter_sound in pubspec.yaml
  sed -i '' "s/^  # flutter_sound:/  flutter_sound:/" pubspec.yaml
  # Uncomment IO implementation code
  sed -i '' "s/^\/\/import 'package:flutter_sound\/flutter_sound.dart';/import 'package:flutter_sound\/flutter_sound.dart';/" lib/widgets/metronome_sound_player_io.dart
  sed -i '' "s/^  \/\/  final FlutterSoundPlayer _tickPlayer/  final FlutterSoundPlayer _tickPlayer/" lib/widgets/metronome_sound_player_io.dart
  sed -i '' "s/^  \/\/  final FlutterSoundPlayer _tockPlayer/  final FlutterSoundPlayer _tockPlayer/" lib/widgets/metronome_sound_player_io.dart
  echo "Running flutter pub get..."
  flutter pub get
  echo "Now ready for IO (mobile/desktop) build."
else
  echo "Usage: $0 [web|io]"
  exit 1
fi
