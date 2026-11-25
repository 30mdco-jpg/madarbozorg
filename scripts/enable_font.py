#!/usr/bin/env python3
"""اگر فایل‌های فونت وزیرمتن دانلود شده باشند، آن‌ها را در pubspec.yaml ثبت می‌کند."""
import os
import sys

REGULAR = "assets/fonts/Vazirmatn-Regular.ttf"
BOLD = "assets/fonts/Vazirmatn-Bold.ttf"
PLACEHOLDER = "  # FONTS_PLACEHOLDER"

ok = all(os.path.exists(p) and os.path.getsize(p) > 20000 for p in (REGULAR, BOLD))
if not ok:
    print("فونت وزیرمتن در دسترس نیست؛ از فونت فارسی سیستم استفاده می‌شود.")
    sys.exit(0)

block = f"""  fonts:
    - family: Vazirmatn
      fonts:
        - asset: {REGULAR}
        - asset: {BOLD}
          weight: 700"""

with open("pubspec.yaml", encoding="utf-8") as f:
    text = f.read()
if PLACEHOLDER not in text:
    print("جای‌نگهدار فونت در pubspec.yaml پیدا نشد.")
    sys.exit(1)
text = text.replace(PLACEHOLDER, block)
with open("pubspec.yaml", "w", encoding="utf-8") as f:
    f.write(text)
print("فونت وزیرمتن در pubspec.yaml ثبت شد.")
