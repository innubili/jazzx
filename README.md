# jazzx
Practice tracking app for jazz musicians

Usage
From your project root, run:


chmod +x scripts/switch_audio_backend.sh
./scripts/switch_audio_backend.sh web   # Prepares for web build (removes flutter_sound)
./scripts/switch_audio_backend.sh io    # Prepares for mobile/desktop build (restores flutter_sound)
When you switch to web, the script:
Comments out flutter_sound in pubspec.yaml
Comments out all lines in your IO implementation that reference flutter_sound
Runs flutter pub get
When you switch to io, the script:
Uncomments flutter_sound in pubspec.yaml
Uncomments all lines in your IO implementation that reference flutter_sound
Runs flutter pub get
