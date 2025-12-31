#!/bin/bash
set -e

# Parametreleri Al
PACKAGE_NAME=$1
APP_NAME=$2
M3U_URL=$3

echo "--- BUILD HAZIRLIGI BASLIYOR ---"

# 1. HATA VEREN BOZUK RESİM KLASÖRLERİNİ SİL (HATA ÇÖZÜMÜ BURADA)
echo "Temizlik yapılıyor..."
rm -rf app/src/main/res/mipmap*
rm -rf app/src/main/res/drawable*

# 2. build.gradle içindeki applicationId'yi değiştir
sed -i "s/applicationId \"com.base.app\"/applicationId \"$PACKAGE_NAME\"/g" app/build.gradle

# 3. AndroidManifest.xml içindeki Label'ı değiştir
sed -i "s/android:label=\"BASE_APP_NAME\"/android:label=\"$APP_NAME\"/g" app/src/main/AndroidManifest.xml

# 4. Assets klasörünü oluştur ve Config dosyasını yaz
mkdir -p app/src/main/assets
cat > app/src/main/assets/config.json <<EOF
{
  "app_name": "$APP_NAME",
  "m3u_url": "$M3U_URL"
}
EOF

echo "--- HAZIRLIK TAMAMLANDI ---"
