package de.robv.android.xposed;

public abstract class XC_MethodHook {
    public static class MethodHookParam {
        public Object thisObject;
        public Object[] args;
    }

    public class Unhook {}

    protected void beforeHookedMethod(MethodHookParam param) throws Throwable {}
    protected void afterHookedMethod(MethodHookParam param) throws Throwable {}
}
