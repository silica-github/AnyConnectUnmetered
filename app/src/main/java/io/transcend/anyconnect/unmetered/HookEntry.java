package io.transcend.anyconnect.unmetered;

import android.os.Build;
import de.robv.android.xposed.IXposedHookLoadPackage;
import de.robv.android.xposed.XC_MethodHook;
import de.robv.android.xposed.XposedBridge;
import de.robv.android.xposed.XposedHelpers;
import de.robv.android.xposed.callbacks.XC_LoadPackage;

/**
 * 攔截 Cisco AnyConnect 的 VpnService.Builder，
 * 在建立 VPN 介面時顯式呼叫 setMetered(false)，讓系統依底層網路決定是否計費。
 */
public class HookEntry implements IXposedHookLoadPackage {

    private static final String TARGET_PACKAGE = "com.cisco.anyconnect.vpn.android.avf";
    private static final String VPN_BUILDER_CLASS = "android.net.VpnService$Builder";
    private static final String LOG_TAG = "[AnyConnectUnmetered] ";

    @Override
    public void handleLoadPackage(XC_LoadPackage.LoadPackageParam lpparam) {
        if (!TARGET_PACKAGE.equals(lpparam.packageName)) {
            return;
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return;
        }

        // 在建立 VPN 介面之前強制將 isMetered 設為 false，交由底層網路狀態決定計費屬性
        try {
            XposedHelpers.findAndHookMethod(
                    VPN_BUILDER_CLASS,
                    lpparam.classLoader,
                    "establish",
                    new XC_MethodHook() {
                        @Override
                        protected void beforeHookedMethod(MethodHookParam param) {
                            XposedHelpers.callMethod(param.thisObject, "setMetered", false);
                            XposedBridge.log(LOG_TAG + "已在 establish() 前設定 setMetered(false)");
                        }
                    }
            );
        } catch (Throwable t) {
            XposedBridge.log(LOG_TAG + "Hook establish() 失敗: " + t);
        }

        // 防禦性攔截：避免目標應用在建構過程中自行傳入 setMetered(true)
        try {
            XposedHelpers.findAndHookMethod(
                    VPN_BUILDER_CLASS,
                    lpparam.classLoader,
                    "setMetered",
                    boolean.class,
                    new XC_MethodHook() {
                        @Override
                        protected void beforeHookedMethod(MethodHookParam param) {
                            if (Boolean.TRUE.equals(param.args[0])) {
                                param.args[0] = false;
                                XposedBridge.log(LOG_TAG + "已將 setMetered(true) 覆寫為 false");
                            }
                        }
                    }
            );
        } catch (Throwable t) {
            XposedBridge.log(LOG_TAG + "Hook setMetered(boolean) 失敗: " + t);
        }
    }
}
