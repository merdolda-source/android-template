#!/bin/bash
set -e

PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3

echo "=========================================="
echo "      FABRİKA SCRIPTI - FINAL SÜRÜM"
echo "=========================================="
echo "PAKET: $PACKAGE_NAME"
echo "APP ADI: $APP_NAME"
echo "URL: $CONFIG_URL"
echo "=========================================="

# 1. Dosyayı Bul
TARGET_FILE=$(find app/src/main/java -name "MainActivity.java" | head -n 1)

if [ -z "$TARGET_FILE" ]; then
    echo "❌ HATA: MainActivity.java bulunamadı!"
    find . -name "MainActivity.java"
    exit 1
fi
echo "✅ Dosya bulundu: $TARGET_FILE"

# 2. Windows Satır Sonlarını Temizle (KRİTİK ADIM)
# Dosyayı Linux formatına zorluyoruz ki aranan kelime bulunsun.
sed -i 's/\r$//' "$TARGET_FILE"

# 3. URL Değiştirme (Perl Kullanarak - Daha Güvenli)
# Sed bazen URL'lerdeki // işaretlerinde hata verir, Perl vermez.
perl -pi -e "s|REPLACE_THIS_URL|$CONFIG_URL|g" "$TARGET_FILE"

# 4. Kontrol Et
if grep -q "$CONFIG_URL" "$TARGET_FILE"; then
    echo "✅ BAŞARILI: URL değiştirildi."
else
    echo "⚠️ UYARI: URL değişmemiş görünüyor. Zorla yazılıyor..."
    # Eğer yukarıdaki çalışmazsa, dosyayı tamamen yeniden yazarız (Acil durum planı)
    sed -i "s|REPLACE_THIS_URL|$CONFIG_URL|g" "$TARGET_FILE"
fi

# 5. Temizlik
echo "--- Temizlik Yapılıyor ---"
rm -rf app/src/main/res/drawable*
rm -rf app/src/main/res/mipmap*
rm -rf app/src/main/res/values/themes.xml
rm -rf app/src/main/res/values/styles.xml
rm -rf app/src/main/res/values/colors.xml

# 6. Kimlik Güncelleme
sed -i "s/applicationId \"com.base.app\"/applicationId \"$PACKAGE_NAME\"/g" app/build.gradle
sed -i "s/android:label=\"BASE_APP_NAME\"/android:label=\"$APP_NAME\"/g" app/src/main/AndroidManifest.xml

echo "--- İŞLEM BİTTİ ---"
