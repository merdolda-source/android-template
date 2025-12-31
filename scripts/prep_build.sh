#!/bin/bash
set -e

# GitHub Actions'dan gelen parametreler
NEW_PACKAGE_NAME=$1
NEW_APP_NAME=$2
M3U_URL=$3

echo "--- FABRIKA BASLIYOR ---"
echo "Hedef Paket: $NEW_PACKAGE_NAME"
echo "Hedef Ad: $NEW_APP_NAME"

# 1. build.gradle içindeki applicationId'yi değiştir
# Regex: "applicationId" kelimesini bul ve tırnak içini değiştir.
sed -i "s/applicationId \"com.base.app\"/applicationId \"$NEW_PACKAGE_NAME\"/g" app/build.gradle

# 2. AndroidManifest.xml içindeki Label'ı değiştir
# Regex: "BASE_APP_NAME" yazan yeri bul ve yeni ad ile değiştir.
sed -i "s/android:label=\"BASE_APP_NAME\"/android:label=\"$NEW_APP_NAME\"/g" app/src/main/AndroidManifest.xml

# 3. Assets klasörünü oluştur (yoksa)
mkdir -p app/src/main/assets

# 4. JSON Config dosyasını yaz
cat > app/src/main/assets/config.json <<EOF
{
  "app_name": "$NEW_APP_NAME",
  "m3u_url": "$M3U_URL"
}
EOF

echo "--- CONFIG DOSYALARI GUNCELLENDI ---"
