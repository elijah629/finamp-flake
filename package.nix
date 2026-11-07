{
  lib,
  stdenv,
  flutter347,
  gtk3,
  libx11,
  libxi,
  makeWrapper,
  mpv-unwrapped,
  patchelf,
  pkg-config,
  copyDesktopItems,
  makeDesktopItem,
  src,
}:

let
  versionLine = lib.findFirst (line: builtins.match "version:[[:space:]]*.*" line != null) null (
    lib.splitString "\n" (builtins.readFile "${src}/pubspec.yaml")
  );
  versionMatch =
    if versionLine == null then
      null
    else
      builtins.match "version:[[:space:]]*([^[:space:]]+)" versionLine;
  version = if versionMatch == null then "redesign-local" else builtins.elemAt versionMatch 0;
in
flutter347.buildFlutterApplication {
  pname = "finamp";
  inherit version src;

  pubspecLock = lib.importJSON ./pubspec.lock.json;
  gitHashes = lib.importJSON ./git-hashes.json;

  postPatch = ''
    rm -rf build .dart_tool
    # Dart 3.13 rejects final modifiers on these upstream parameters.
    sed -i -E 's/(set(Speed|Pitch|Volume)\()final double /\1double /g' \
      lib/services/music_player_background_task.dart
  '';

  nativeBuildInputs = [
    patchelf
    copyDesktopItems
    makeWrapper
    pkg-config
  ];

  buildInputs = [
    gtk3
    libx11
    libxi
    mpv-unwrapped
  ];

  preBuild = ''
    # Dart native-asset hooks strip PKG_CONFIG_PATH from their environment.
    # Capture the setup hooks' complete path in a wrapper for cnativeapi.
    mkdir -p "$TMPDIR/finamp-tools"
    makeWrapper ${lib.getExe pkg-config} "$TMPDIR/finamp-tools/pkg-config" \
      --set PKG_CONFIG_PATH "$PKG_CONFIG_PATH" \
      --set PKG_CONFIG_PATH_${
        lib.replaceStrings [ "-" ] [ "_" ] stdenv.hostPlatform.config
      } "$PKG_CONFIG_PATH"
    export PATH="$TMPDIR/finamp-tools:$PATH"
  '';

  postFixup = ''
    patchelf "$out/app/$pname/finamp" \
      --add-needed libisar.so \
      --add-needed libmpv.so \
      --add-needed libflutter_discord_rpc.so \
      --add-rpath ${lib.makeLibraryPath [ mpv-unwrapped ]}
  '';

  postInstall = ''
    install -Dm444 assets/icon/icon_foreground.svg \
      $out/share/icons/hicolor/scalable/apps/finamp.svg
    install -Dm444 assets/com.unicornsonlsd.finamp.metainfo.xml \
      -t $out/share/metainfo
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "com.unicornsonlsd.finamp";
      desktopName = "Finamp";
      genericName = "Music Player";
      exec = "finamp";
      icon = "finamp";
      startupWMClass = "finamp";
      comment = "An open source Jellyfin music player";
      categories = [
        "AudioVideo"
        "Audio"
        "Player"
        "Music"
      ];
      mimeTypes = [ "x-scheme-handler/finamp" ];
    })
  ];

  meta = {
    description = "Open source Jellyfin music player";
    homepage = "https://github.com/UnicornsOnLSD/finamp";
    license = lib.licenses.mpl20;
    mainProgram = "finamp";
    platforms = lib.platforms.linux;
    broken = stdenv.hostPlatform.isLinux && !stdenv.hostPlatform.isx86_64;
  };
}
