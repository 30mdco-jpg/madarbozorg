#!/usr/bin/env python3
"""تنظیمات اندروید را پس از `flutter create` اعمال می‌کند (قابل اجرا چندباره):

- شناسهٔ برنامه و نام نمایشی
- مجوزهای اینترنت و اعلان (POST_NOTIFICATIONS) و راه‌اندازی مجدد اعلان‌ها بعد از ریبوت
- گیرنده‌های اعلان زمان‌بندی‌شده
- فعال‌سازی core library desugaring (لازم برای flutter_local_notifications)
- آیکن کوچک اعلان (ic_stat_notify) و جلوگیری از حذف آن توسط shrink
- آیکن بزرگ اعلان (notification_large_icon) از روی assets/app_icon.png
"""
import os
import re
import shutil
import subprocess
import sys

APP_ID = "app.madarbozorg.family"
LABEL = "نوبت بی بی"
DESUGAR_VERSION = "2.1.4"
ANDROID_DIR = sys.argv[1] if len(sys.argv) > 1 else "android"
LARGE_ICON_SOURCE = "assets/app_icon.png"
LARGE_ICON_SIZE = 256


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def patch_gradle():
    found = False
    for name in ("build.gradle.kts", "build.gradle"):
        path = os.path.join(ANDROID_DIR, "app", name)
        if not os.path.exists(path):
            continue
        found = True
        kts = name.endswith(".kts")
        s = read(path)
        s = re.sub(r"applicationId\s*=?\s*[\"'][^\"']+[\"']",
                   f'applicationId = "{APP_ID}"', s)
        if "coreLibraryDesugaring" not in s:
            m = re.search(r"compileOptions\s*\{", s)
            if not m:
                sys.exit(f"compileOptions در {path} پیدا نشد")
            flag = ("isCoreLibraryDesugaringEnabled = true" if kts
                    else "coreLibraryDesugaringEnabled true")
            s = s[:m.end()] + "\n        " + flag + s[m.end():]
            dep = (f'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:{DESUGAR_VERSION}")'
                   if kts else
                   f"coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:{DESUGAR_VERSION}'")
            s = s.rstrip() + f"\n\ndependencies {{\n    {dep}\n}}\n"
        write(path, s)
    if not found:
        sys.exit("فایل build.gradle(.kts) پیدا نشد")


PERMISSIONS = [
    "android.permission.INTERNET",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.VIBRATE",
]

RECEIVERS = """    <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
    <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
        <intent-filter>
            <action android:name="android.intent.action.BOOT_COMPLETED"/>
            <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
            <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
            <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
        </intent-filter>
    </receiver>
"""


def patch_manifest():
    path = os.path.join(ANDROID_DIR, "app", "src", "main", "AndroidManifest.xml")
    s = read(path)
    s = re.sub(r'android:label="[^"]*"', f'android:label="{LABEL}"', s, count=1)
    missing = [p for p in PERMISSIONS if p not in s]
    if missing:
        perms = "".join(
            f'    <uses-permission android:name="{p}"/>\n' for p in missing)
        s = s.replace("<application", perms + "    <application", 1)
    if "ScheduledNotificationReceiver" not in s:
        if "</application>" not in s:
            sys.exit("</application> در AndroidManifest پیدا نشد")
        s = s.replace("</application>", RECEIVERS + "    </application>", 1)
    write(path, s)


ICON = """<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M12,22c1.1,0 2,-0.9 2,-2h-4c0,1.1 0.89,2 2,2zM18,16v-5c0,-3.07 -1.64,-5.64 -4.5,-6.32V4c0,-0.83 -0.67,-1.5 -1.5,-1.5s-1.5,0.67 -1.5,1.5v0.68C7.63,5.36 6,7.92 6,11v5l-2,2v1h16v-1l-2,-2z"/>
</vector>
"""

KEEP = """<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@drawable/ic_stat_notify,@drawable/notification_large_icon" />
"""


def add_large_icon(drawable_dir):
    """تصویر آیکن برنامه را (کوچک‌شده) برای نمایش داخل اعلان کپی می‌کند."""
    if not os.path.exists(LARGE_ICON_SOURCE):
        sys.exit(f"{LARGE_ICON_SOURCE} پیدا نشد؛ آیکن بزرگ اعلان ساخته نشد")
    target = os.path.join(drawable_dir, "notification_large_icon.png")
    size = (LARGE_ICON_SIZE, LARGE_ICON_SIZE)
    try:
        from PIL import Image  # اگر نصب باشد

        img = Image.open(LARGE_ICON_SOURCE).convert("RGBA")
        img.thumbnail(size)
        img.save(target, "PNG")
        return
    except Exception:
        pass
    try:
        subprocess.run(
            ["convert", LARGE_ICON_SOURCE, "-resize", f"{size[0]}x{size[1]}", target],
            check=True,
        )
        return
    except Exception:
        pass
    # آخرین راه: همان تصویر اصلی (بزرگ‌تر است ولی کار می‌کند)
    shutil.copyfile(LARGE_ICON_SOURCE, target)


def add_resources():
    res = os.path.join(ANDROID_DIR, "app", "src", "main", "res")
    drawable = os.path.join(res, "drawable")
    write(os.path.join(drawable, "ic_stat_notify.xml"), ICON)
    write(os.path.join(res, "raw", "keep.xml"), KEEP)
    add_large_icon(drawable)


if __name__ == "__main__":
    patch_gradle()
    patch_manifest()
    add_resources()
    print("تنظیمات اندروید اعمال شد.")
