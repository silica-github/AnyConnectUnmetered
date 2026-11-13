package de.robv.android.xposed;

public final class XposedBridge {
    public static synchronized void log(String text) {}
    public static synchronized void log(Throwable t) {}
}
