#!/bin/sh

set -eu

if [ $# -ne 1 ]; then
    echo "Usage: $0 [path to ghidra folder]" >&2
    exit 1
fi

rm -rf Ghidra.app

mkdir -p Ghidra.app/Contents/MacOS
clang -x objective-c -arch x86_64h -arch arm64 -fmodules -framework Foundation ghidraRun.m -o Ghidra.app/Contents/MacOS/Ghidra

mkdir -p Ghidra.app/Contents/Resources/
cp -R "$(echo "$1" | sed s,/*$,,)" Ghidra.app/Contents/Resources/ghidra
sed "s/bg Ghidra/fg Ghidra/" < "$1/ghidraRun" > Ghidra.app/Contents/Resources/ghidra/ghidraRun
sed "s/apple.laf.useScreenMenuBar=false/apple.laf.useScreenMenuBar=true/" < "$1/support/launch.properties" > Ghidra.app/Contents/Resources/ghidra/support/launch.properties
echo "APPL????" > Ghidra.app/Contents/PkgInfo
jar -x -f Ghidra.app/Contents/Resources/ghidra/Ghidra/Framework/Gui/lib/Gui.jar images/GhidraIcon256.png
for size in 16 24 32 40 48 64 128 256; do
    jar -u -f Ghidra.app/Contents/Resources/ghidra/Ghidra/Framework/Generic/lib/Generic.jar "images/GhidraIcon${size}.png"
done

iconutil -c icns Ghidra.iconset
cp Ghidra.icns Ghidra.app/Contents/Resources
SetFile -a B Ghidra.app

sed "s/GHIDRA_VER1/$(grep application.version < "$1/Ghidra/application.properties" | sed "s/application.version=//")/" < Info.plist | \
    sed "s/GHIDRA_VER2/$(grep application.version < "$1/Ghidra/application.properties" | sed "s/application.version=//" | sed "s/\.//g")/" > Ghidra.app/Contents/Info.plist

javac -cp "$(find Ghidra.app -regex '.*\.jar' | tr '\n' ':')" docking/widgets/filechooser/GhidraFileChooser.java
cp -R docking Ghidra.app/Contents/Resources/Ghidra/ghidra/patch/

javac OpenGhidra.java
cp OpenGhidra.class Ghidra.app/Contents/Resources

javac -cp "$(find Ghidra.app -regex '.*\.jar' | tr '\n' ':')" OpenGhidraAgent.java
jar --create --file OpenGhidra.jar --manifest manifest OpenGhidraAgent*.class
cp OpenGhidra.jar Ghidra.app/Contents/Resources
