#!/bin/bash
set -e

PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3

echo "--- 1. TEMIZLIK (Bozuk Resim Engelleme) ---"
rm -rf app/src/main/res/drawable*
rm -rf app/src/main/res/mipmap*
rm -rf app/src/main/res/values/themes.xml
rm -rf app/src/main/res/values/styles.xml
rm -rf app/src/main/res/values/colors.xml

echo "--- 2. KIMLIK GUNCELLEME ---"
# build.gradle içindeki paket adını değiştir
sed -i "s/applicationId \"com.base.app\"/applicationId \"$PACKAGE_NAME\"/g" app/build.gradle

# Manifest içindeki App Adını değiştir
sed -i "s/android:label=\"BASE_APP_NAME\"/android:label=\"$APP_NAME\"/g" app/src/main/AndroidManifest.xml

echo "--- 3. URL ENJEKSIYONU ---"
# MainActivity.java içindeki CONFIG_URL yer tutucusunu değiştir
# URL içinde slash (/) olduğu için sed ayıracı olarak | kullanıyoruz.
sed -i "s|https://panel.siteniz.com/default.json|$CONFIG_URL|g" app/src/main/java/com/base/app/MainActivity.java

echo "--- HAZIRLIK BITTI ---"
