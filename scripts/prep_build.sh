#!/bin/bash
set -e

PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3

echo "--- 1. DOSYA ARANIYOR ---"
# MainActivity.java dosyası nerede olursa olsun BULUYORUZ
TARGET_FILE=$(find app/src/main/java -name "MainActivity.java")

if [ -z "$TARGET_FILE" ]; then
    echo "❌ HATA: MainActivity.java dosyası HİÇBİR YERDE BULUNAMADI!"
    echo "   Lütfen 'app/src/main/java' klasörüne dosyayı yüklediğinizden emin olun."
    exit 1
else
    echo "✅ Dosya Bulundu: $TARGET_FILE"
fi

echo "--- 2. URL ENJEKSİYONU ---"
# URL'yi değiştiriyoruz (Ayraç olarak | kullanıyoruz)
sed -i "s|REPLACE_THIS_URL|$CONFIG_URL|g" "$TARGET_FILE"

# Kontrol ediyoruz
if grep -q "$CONFIG_URL" "$TARGET_FILE"; then
    echo "✅ URL BAŞARIYLA DEĞİŞTİRİLDİ!"
else
    echo "❌ URL DEĞİŞTİRİLEMEDİ! REPLACE_THIS_URL yazısı dosyada yoktu."
    exit 1
fi

echo "--- 3. TEMİZLİK ---"
# Bozuk resim dosyalarını temizle
rm -rf app/src/main/res/drawable*
rm -rf app/src/main/res/mipmap*
rm -rf app/src/main/res/values/themes.xml
rm -rf app/src/main/res/values/styles.xml
rm -rf app/src/main/res/values/colors.xml

echo "--- 4. KİMLİK GÜNCELLEME ---"
# Paket adını güncelle
sed -i "s/applicationId \"com.base.app\"/applicationId \"$PACKAGE_NAME\"/g" app/build.gradle
# App adını güncelle
sed -i "s/android:label=\"BASE_APP_NAME\"/android:label=\"$APP_NAME\"/g" app/src/main/AndroidManifest.xml

echo "--- İŞLEM BAŞARIYLA TAMAMLANDI ---"
