# AnyConnect Unmetered

一個輕量級的 LSPosed / Xposed 模組，用於解決 Android 10+ 環境下使用 Cisco Secure Client (AnyConnect) 連接 VPN 時，即使底層為 Wi-Fi 仍被系統與 Google Photos 等應用判定為「計費網路（Metered Network）」的問題。

## 問題背景

從 Android 10 (API 29) 開始，`VpnService.Builder.setMetered(boolean)` 的預設值為 `true`。若 VPN 應用在建立隧道時沒有顯式呼叫 `builder.setMetered(false)`，即使 `UnderlyingNetworks` 綁定的是不計費的 Wi-Fi，Android 系統建立的 VPN `NetworkAgent` 仍會缺少 `NET_CAPABILITY_NOT_METERED` 能力標記。

這會導致依賴非計費網路判斷的應用（例如 Google Photos 的僅 Wi-Fi 自動備份、Google Play 背景更新等）將其視為計費網路，進而停留在「正在等待 WLAN 連接」狀態。

## 運作原理

本模組僅針對目標進程 `com.cisco.anyconnect.vpn.android.avf` 進行局部 Hook，不修改系統框架（`system_server`），亦不影響其他應用：

1. 在 `android.net.VpnService$Builder.establish()` 執行前呼叫 `setMetered(false)`。
2. 攔截 `android.net.VpnService$Builder.setMetered(boolean)`，確保不會被目標應用覆寫回 `true`。

### 為什麼不會影響真正的 4G / 5G 流量？

在 Android 的網路模型中，呼叫 `setMetered(false)` 代表「VPN 隧道本身不額外視為計費網路，請依底層網路（`UnderlyingNetworks`）的計費狀態決定」。

- 當手機連線至 Wi-Fi（`NOT_METERED`）時，VPN 會繼承非計費狀態，背景自動備份可正常執行。
- 當手機切換至 4G / 5G 行動網路時，底層網路不具備 `NOT_METERED`，系統會自動移除 VPN 網路的非計費標記，Google Photos 等應用依然會暫停自動備份，不會額外消耗行動數據。

## 系統需求

- Android 10 (API 29) 或以上版本
- 已取得 Root 權限並安裝 LSPosed（或相容之 Xposed 框架）
- Cisco Secure Client (`com.cisco.anyconnect.vpn.android.avf`)

## 使用方式

1. 下載並安裝 `AnyConnectUnmetered.apk`（或自行從源碼編譯）。
2. 開啟 **LSPosed Manager**，進入「模組」頁面啟用 **AnyConnect Unmetered**。
3. 確認作用域（Scope）已勾選 **Cisco Secure Client**（`com.cisco.anyconnect.vpn.android.avf`）。
4. 強制停止並重新開啟 AnyConnect，重新建立 VPN 連線即可生效，無需重開機。

## 自行編譯

本專案採用極簡純 Java 結構，不依賴大型建置工具或外部 Gradle 套件，Windows 環境下僅需 JDK 與 Android SDK Build-Tools 即可編譯：

1. 確認本機已安裝 JDK 與 Android SDK（視環境調整 `build.bat` 內的 `SDK_DIR`、`BUILD_TOOLS` 與 `ANDROID_JAR` 路徑）。
2. 在專案根目錄執行：
   ```cmd
   build.bat
   ```
3. 編譯並簽名後的 APK 會輸出至 `build\AnyConnectUnmetered.apk`。

## 專案結構

- `app/src/main/java/io/transcend/anyconnect/unmetered/HookEntry.java`：核心 Hook 實作
- `app/src/main/AndroidManifest.xml`：模組宣告與 Xposed Meta-Data
- `app/src/main/res/values/arrays.xml`：預設作用域清單
- `app/src/main/assets/xposed_init`：Xposed 入口類別定義
- `xposed-stub/`：編譯期使用的 Xposed API 介面存根（不會打包進 APK）
- `build.bat`：Windows CMD 一鍵編譯與簽名腳本
