{
  lib,
  stdenv,
  flutter341,
  mpv-unwrapped,
  patchelf,
  copyDesktopItems,
  makeDesktopItem,
  src,
}:

let
  versionLine = lib.findFirst (
    line: builtins.match ''version:[[:space:]]*.*'' line != null
  ) null (lib.splitString "\n" (builtins.readFile "${src}/pubspec.yaml"));
  versionMatch =
    if versionLine == null then null else builtins.match ''version:[[:space:]]*([^[:space:]]+)'' versionLine;
  version =
    if versionMatch == null then
      "redesign-local"
    else
      builtins.elemAt versionMatch 0;
in
flutter341.buildFlutterApplication {
  pname = "finamp";
  inherit version src;

  pubspecLock = lib.importJSON ./pubspec.lock.json;
  gitHashes = lib.importJSON ./git-hashes.json;

  postPatch = ''
    rm -rf build .dart_tool
  '';

  nativeBuildInputs = [
    patchelf
    copyDesktopItems
  ];

  buildInputs = [ mpv-unwrapped ];

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
