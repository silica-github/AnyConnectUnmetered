# AnyConnect Unmetered

A lightweight LSPosed / Xposed module that allows Cisco Secure Client (AnyConnect) VPN to inherit the unmetered status of its underlying Wi-Fi network on Android 10+, preventing apps like Google Photos from misidentifying Wi-Fi VPN connections as metered cellular networks.

## Background

Starting with Android 10 (API 29), `VpnService.Builder.setMetered(boolean)` defaults to `true`. If a VPN app does not explicitly call `builder.setMetered(false)` when establishing the tunnel, the resulting VPN `NetworkAgent` lacks the `NET_CAPABILITY_NOT_METERED` capability—even when `UnderlyingNetworks` is bound to an unmetered Wi-Fi network.

As a result, apps and background jobs that check for unmetered connectivity (such as Google Photos Wi-Fi-only backup or Google Play updates) treat the VPN connection as metered and stay paused with messages like "Waiting for Wi-Fi".

## How It Works

This module hooks only the target process `com.cisco.anyconnect.vpn.android.avf` without touching `system_server` or other apps:

1. Calls `setMetered(false)` on the `android.net.VpnService$Builder` instance right before `establish()` is invoked.
2. Hooks `android.net.VpnService$Builder.setMetered(boolean)` to ensure `true` is overridden to `false`.

### Why Cellular (4G / 5G) Metering Remains Unaffected

In Android's connectivity model, calling `setMetered(false)` means the VPN tunnel itself does not impose an extra metered flag; instead, its meteredness follows the active `UnderlyingNetworks`:

- **On Wi-Fi (`NOT_METERED`)**: The VPN inherits `NOT_METERED`, so background Wi-Fi backups work normally.
- **On 4G / 5G Cellular**: Since the underlying cellular network lacks `NOT_METERED`, Android automatically removes `NOT_METERED` from the VPN network, and apps continue to respect your cellular data restrictions.

## Requirements

- Android 10 (API 29) or higher
- Rooted device with LSPosed (or a compatible Xposed framework)
- Cisco Secure Client (`com.cisco.anyconnect.vpn.android.avf`)

## Usage

1. Download and install `AnyConnectUnmetered.apk` (or build from source).
2. Open **LSPosed Manager** and enable **AnyConnect Unmetered**.
3. Ensure **Cisco Secure Client** (`com.cisco.anyconnect.vpn.android.avf`) is selected in the module scope.
4. Force-stop AnyConnect and reconnect the VPN. No reboot is required.

## Building from Source

This project uses a minimal pure-Java layout with zero external Gradle dependencies. On Windows, you only need a JDK and Android SDK Build-Tools:

1. Verify or adjust `SDK_DIR`, `BUILD_TOOLS`, and `ANDROID_JAR` in `build.bat` to match your environment.
2. Run in the project root:
   ```cmd
   build.bat
   ```
3. The signed APK will be generated at `build\AnyConnectUnmetered.apk`.

## Project Structure

- `app/src/main/java/io/transcend/anyconnect/unmetered/HookEntry.java` — Core Xposed hook implementation
- `app/src/main/AndroidManifest.xml` — Module metadata and default scope declaration
- `app/src/main/res/values/arrays.xml` — Default Xposed scope list
- `app/src/main/assets/xposed_init` — Xposed entry point
- `xposed-stub/` — Compile-time Xposed API stubs (not packaged into the APK)
- `build.bat` — Windows CMD build and signing script
