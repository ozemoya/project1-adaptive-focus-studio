# Release check — October 26, 2026

Built the Android release package with `flutter build apk --release --no-pub`.
The resulting APK is 56,043,741 bytes and has SHA-256
`A14DA1EBF90AAD49F4C96D2386A5F5C3764A2AFDF8235FDF5AE7E9544E76E846`.

Installed the release APK on the Pixel 7 Pro Android emulator with `adb install -r` (result: `Success`) and launched it. The saved Practice plan appeared after launch. Opened Dashboard, Plan editor, Focus, History, and Settings and captured a release screenshot of each screen for the presentation.

The release package and screenshots are staged outside this public repository in the private submission folder. The release launch establishes that the APK installs and opens on this emulator; it does not replace a peer trial, a physical-device check, or the required recorded presentation and individual iCollege submissions.
