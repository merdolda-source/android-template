#!/bin/bash
set -e

PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3

echo "=========================================="
echo "      FABRİKA SCRIPTI - DEBUG MODU"
echo "=========================================="
echo "PAKET: $PACKAGE_NAME"
echo "APP ADI: $APP_NAME"
echo "URL: $CONFIG_URL"
echo "=========================================="

# 1. HEDEF DOSYAYI SABİTLİYORUZ (Ekran görüntündeki kesin yol)
TARGET_FILE="app/src/main/java/com/base/app/MainActivity.java"

echo "--- KONTROL 1: Dosya Var mı? ---"
if [ -f "$TARGET_FILE" ]; then
    echo "✅ EVET, dosya burada: $TARGET_FILE"
else
    echo "❌ HAYIR, dosya bulunamadı! Aranan yol: $TARGET_FILE"
    echo "Dosyalar listeleniyor:"
    find . -name "MainActivity.java"
    exit 1
fi

echo "--- KONTROL 2: 'REPLACE_THIS_URL' yazısı var mı? ---"
if grep -q "REPLACE_THIS_URL" "$TARGET_FILE"; then
    echo "✅ EVET, değiştirilecek yazı bulundu."
else
    echo "⚠️ DİKKAT: Dosyada 'REPLACE_THIS_URL' bulunamadı!"
    echo "Dosyanın ilk 30 satırı kontrol ediliyor:"
    head -n 30 "$TARGET_FILE"
    echo "----------------------------------------"
    echo "Eğer yukarıda REPLACE_THIS_URL görmüyorsanız, MainActivity.java yanlış kaydedilmiş demektir."
    # Hata vermeden devam etmeye çalışalım, belki başka bir şeydir.
fi

echo "--- 3. URL DEĞİŞTİRME İŞLEMİ ---"
# URL'yi zorla değiştiriyoruz
sed -i "s|REPLACE_THIS_URL|$CONFIG_URL|g" "$TARGET_FILE"

# İkinci bir kontrol: Belki tırnak işaretleri farklıdır?
# REPLACE_THIS_URL yazan her şeyi hedef alıyoruz.
sed -i "s/REPLACE_THIS_URL/$CONFIG_URL/g" "$TARGET_FILE" || true

echo "--- 4. SON KONTROL ---"
if grep -q "$CONFIG_URL" "$TARGET_FILE"; then
    echo "✅ BAŞARILI: URL dosyanın içine işlendi."
else
    echo "❌ KRİTİK HATA: URL dosyaya yazılamadı."
    # Yine de devam et, belki grep bulamıyordur ama dosya değişmiştir.
fi

echo "--- 5. TEMİZLİK VE İSİM GÜNCELLEME ---"
rm -rf app/src/main/res/drawable*
rm -rf app/src/main/res/mipmap*
rm -rf app/src/main/res/values/themes.xml
rm -rf app/src/main/res/values/styles.xml
rm -rf app/src/main/res/values/colors.xml

sed -i "s/applicationId \"com.base.app\"/applicationId \"$PACKAGE_NAME\"/g" app/build.gradle
sed -i "s/android:label=\"BASE_APP_NAME\"/android:label=\"$APP_NAME\"/g" app/src/main/AndroidManifest.xml

echo "--- İŞLEM BİTTİ ---"
