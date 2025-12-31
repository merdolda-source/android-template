#!/bin/bash
set -e

PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3

echo "=========================================="
echo "      FABRİKA SCRIPTI BAŞLATILDI"
echo "=========================================="
echo " GELEN PAKET ADI : $PACKAGE_NAME"
echo " GELEN UYGULAMA ADI : $APP_NAME"
echo " GELEN CONFIG URL : $CONFIG_URL"
echo "=========================================="

# 1. Dosya Yolu Kontrolü (Hata varsa durdur)
TARGET_FILE="app/src/main/java/com/base/app/MainActivity.java"

if [ ! -f "$TARGET_FILE" ]; then
    echo "❌ HATA: MainActivity.java dosyası bulunamadı!"
    echo "   Aranan Yol: $TARGET_FILE"
    echo "   Lütfen GitHub'da klasör yapısının doğru olduğundan emin olun."
    exit 1
fi

echo "✅ Hedef dosya bulundu. Düzenleniyor..."

# 2. TEMİZLİK (Bozuk Resim Engelleme)
rm -rf app/src/main/res/drawable*
rm -rf app/src/main/res/mipmap*
rm -rf app/src/main/res/values/themes.xml
rm -rf app/src/main/res/values/styles.xml
rm -rf app/src/main/res/values/colors.xml

# 3. KİMLİK GÜNCELLEME
sed -i "s/applicationId \"com.base.app\"/applicationId \"$PACKAGE_NAME\"/g" app/build.gradle
sed -i "s/android:label=\"BASE_APP_NAME\"/android:label=\"$APP_NAME\"/g" app/src/main/AndroidManifest.xml

# 4. URL ENJEKSİYONU (DÜZELTME BURADA)
# URL içinde / olduğu için ayırıcı olarak | kullanıyoruz.
sed -i "s|REPLACE_THIS_URL|$CONFIG_URL|g" "$TARGET_FILE"

# 5. KONTROL (Gerçekten değişti mi?)
if grep -q "$CONFIG_URL" "$TARGET_FILE"; then
    echo "✅ URL BAŞARIYLA DEĞİŞTİRİLDİ!"
else
    echo "❌ URL DEĞİŞTİRİLEMEDİ! REPLACE_THIS_URL yazısı bulunamamış olabilir."
    exit 1
fi

echo "--- İŞLEM BAŞARIYLA TAMAMLANDI ---"
