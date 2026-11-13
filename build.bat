@echo off
setlocal
set "SDK_DIR=C:\Dev\Android\SDK"
set "BUILD_TOOLS=%SDK_DIR%\build-tools\36.0.0"
set "ANDROID_JAR=%SDK_DIR%\platforms\android-34\android.jar"

set "ROOT_DIR=%~dp0"
set "BUILD_DIR=%ROOT_DIR%build"
set "STUB_CLASSES=%BUILD_DIR%\stub-classes"
set "APP_CLASSES=%BUILD_DIR%\app-classes"
set "GEN_DIR=%BUILD_DIR%\gen"
set "RES_ZIP=%BUILD_DIR%\res.zip"
set "DEX_DIR=%BUILD_DIR%\dex"
set "KEYSTORE=%BUILD_DIR%\debug.keystore"

if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
mkdir "%STUB_CLASSES%" "%APP_CLASSES%" "%GEN_DIR%" "%DEX_DIR%"

echo [1/6] Compiling Xposed API stubs...
javac -encoding UTF-8 --release 8 -d "%STUB_CLASSES%" ^
  "%ROOT_DIR%xposed-stub\de\robv\android\xposed\IXposedHookLoadPackage.java" ^
  "%ROOT_DIR%xposed-stub\de\robv\android\xposed\callbacks\XC_LoadPackage.java" ^
  "%ROOT_DIR%xposed-stub\de\robv\android\xposed\XC_MethodHook.java" ^
  "%ROOT_DIR%xposed-stub\de\robv\android\xposed\XposedBridge.java" ^
  "%ROOT_DIR%xposed-stub\de\robv\android\xposed\XposedHelpers.java"
if errorlevel 1 exit /b 1

echo [2/6] Compiling Android resources...
"%BUILD_TOOLS%\aapt2.exe" compile --dir "%ROOT_DIR%app\src\main\res" -o "%RES_ZIP%"
if errorlevel 1 exit /b 1

"%BUILD_TOOLS%\aapt2.exe" link ^
  -I "%ANDROID_JAR%" ^
  --manifest "%ROOT_DIR%app\src\main\AndroidManifest.xml" ^
  -A "%ROOT_DIR%app\src\main\assets" ^
  --java "%GEN_DIR%" ^
  -o "%BUILD_DIR%\base.apk" ^
  "%RES_ZIP%"
if errorlevel 1 exit /b 1

echo [3/6] Compiling module Java sources...
javac -encoding UTF-8 --release 8 -cp "%ANDROID_JAR%;%STUB_CLASSES%" -d "%APP_CLASSES%" ^
  "%GEN_DIR%\io\transcend\anyconnect\unmetered\R.java" ^
  "%ROOT_DIR%app\src\main\java\io\transcend\anyconnect\unmetered\HookEntry.java"
if errorlevel 1 exit /b 1

echo [4/6] Converting classes to classes.dex...
jar cf "%BUILD_DIR%\app.jar" -C "%APP_CLASSES%" .
if errorlevel 1 exit /b 1
call "%BUILD_TOOLS%\d8.bat" --min-api 29 --lib "%ANDROID_JAR%" --output "%DEX_DIR%" "%BUILD_DIR%\app.jar"
if errorlevel 1 exit /b 1

echo [5/6] Packaging classes.dex and aligning APK...
copy /y "%BUILD_DIR%\base.apk" "%BUILD_DIR%\unaligned.apk" >nul
pushd "%DEX_DIR%"
jar uf "%BUILD_DIR%\unaligned.apk" classes.dex
popd
if errorlevel 1 exit /b 1

"%BUILD_TOOLS%\zipalign.exe" -f 4 "%BUILD_DIR%\unaligned.apk" "%BUILD_DIR%\aligned.apk"
if errorlevel 1 exit /b 1

echo [6/6] Signing APK...
keytool -genkeypair -v -keystore "%KEYSTORE%" -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=AnyConnectUnmetered,O=Transcend,C=JP" >nul 2>&1
if errorlevel 1 exit /b 1

call "%BUILD_TOOLS%\apksigner.bat" sign --ks "%KEYSTORE%" --ks-pass pass:android --ks-key-alias androiddebugkey --key-pass pass:android --out "%BUILD_DIR%\AnyConnectUnmetered.apk" "%BUILD_DIR%\aligned.apk"
if errorlevel 1 exit /b 1

echo Build succeeded: %BUILD_DIR%\AnyConnectUnmetered.apk
