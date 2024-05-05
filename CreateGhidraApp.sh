#!/bin/sh

set -eu

if [ $# -ne 1 ]; then
	echo "Usage: $0 [path to ghidra folder]" >&2
	exit 1
fi

mkdir -p Ghidra.app/Contents/MacOS
cat << EOF | clang -x objective-c -target arm64-apple-macos11 -fmodules -framework Foundation -o /tmp/Ghidra.arm64 -
@import Foundation;

int main() {
	execl([NSBundle.mainBundle.resourcePath stringByAppendingString:@"/ghidra/ghidraRun"].UTF8String, NULL);
}
EOF
cat << EOF | clang -x objective-c -target x86_64-apple-macos11 -fmodules -framework Foundation -o /tmp/Ghidra.x86_64 -
@import Foundation;

int main() {
	execl([NSBundle.mainBundle.resourcePath stringByAppendingString:@"/ghidra/ghidraRun"].UTF8String, NULL);
}
EOF
lipo -create /tmp/Ghidra.x86_64 /tmp/Ghidra.arm64 -output Ghidra.app/Contents/MacOS/Ghidra
mkdir -p Ghidra.app/Contents/Resources/
rm -rf Ghidra.app/Contents/Resources/ghidra
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
cat << EOF > Ghidra.app/Contents/Info.plist
<?xml version="1.0" ?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>CFBundleDevelopmentRegion</key>
		<string>English</string>
		<key>CFBundleExecutable</key>
		<string>Ghidra</string>
		<key>CFBundleIconFile</key>
		<string>Ghidra.icns</string>
		<key>CFBundleIdentifier</key>
		<string>org.ghidra-sre.Ghidra</string>
		<key>CFBundleDisplayName</key>
		<string>Ghidra</string>
		<key>CFBundleInfoDictionaryVersion</key>
		<string>6.0</string>
		<key>CFBundleName</key>
		<string>Ghidra</string>
		<key>CFBundlePackageType</key>
		<string>APPL</string>
		<key>CFBundleShortVersionString</key>
		<string>$(grep application.version < "$1/Ghidra/application.properties" | sed "s/application.version=//")</string>
		<key>CFBundleVersion</key>
		<string>$(grep application.version < "$1/Ghidra/application.properties" | sed "s/application.version=//" | sed "s/\.//g")</string>
		<key>CFBundleSignature</key>
		<string>????</string>
		<key>NSHumanReadableCopyright</key>
		<string></string>
		<key>NSHighResolutionCapable</key>
		<true/>
	</dict>
</plist>
EOF

javac -cp "$(find Ghidra.app -regex '.*\.jar' | tr '\n' ':')" docking/widgets/filechooser/GhidraFileChooser.java
cp -R docking Ghidra.app/Contents/Resources/Ghidra/ghidra/patch/

javac OpenGhidra.java
cp OpenGhidra.class Ghidra.app/Contents/Resources

javac -cp "$(find Ghidra.app -regex '.*\.jar' | tr '\n' ':')" OpenGhidraAgent.java
jar --create --file OpenGhidra.jar --manifest manifest OpenGhidraAgent*.class
cp OpenGhidra.jar Ghidra.app/Contents/Resources
