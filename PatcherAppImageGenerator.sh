#!/bin/bash

current_dir=$(pwd)
download_dir="/tmp/SpaghettiProjectAppImage/download"
pkgdir="/tmp/SpaghettiProjectAppImage/AppDir"

patcher="ItalianPatcherByUSPLinux"
dotnet="dotnet50"
openssl="openssl-1.0.2u"

mkdir -p "$download_dir"
cd "$download_dir"

echo "Downloading $patcher..."
curl -L -# "https://github.com/USPAssets/Installer/releases/latest/download/$patcher.tar.gz" -o "$patcher.tar.gz"

echo "Downloading $dotnet..."
curl -L -# "https://download.visualstudio.microsoft.com/download/pr/a2b96f83-e22a-4fa6-a10e-709b3effac9a/0d6ade6c0ceebc8ef7dbf2b1a6d86f17/aspnetcore-runtime-5.0.17-linux-x64.tar.gz" -o "$dotnet.tar.gz"

echo "Downloading $openssl..."
curl -L -# "https://www.openssl.org/source/$openssl.tar.gz" -o "$openssl.tar.gz"

echo "Downloading AppImageTool..."
curl -L -# https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -o "appimagetool.AppImage"
chmod +x appimagetool.AppImage

mkdir "$pkgdir"

cd "$download_dir"
tar -xzf $openssl.tar.gz
cd "$openssl"

echo "Verrà compilato OpenSSL 1.0. Il processo potrebbe richiedere un paio di minuti..."

echo -n "Configurando openssl..."
./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib/openssl-1.0 shared no-ssl3-method > /dev/null
echo " OK"

echo -n "Generando dipendenze di openssl..."
make depend > /dev/null 2>> "$pkgdir/MAKE_WARNINGS.log"
echo " OK"

echo -n "Compilando OpenSSL..."
make > /dev/null 2>> "$pkgdir/MAKE_WARNINGS.log"
echo " OK"

echo -n "Installando OpenSSL in $pkgdir..."
# ↓ Preso in prestito da https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=openssl-1.0
make INSTALL_PREFIX="$pkgdir" install_sw > /dev/null
install -m755 -d "$pkgdir/usr/include/openssl-1.0"
mv "$pkgdir/usr/include/openssl" "$pkgdir/usr/include/openssl-1.0/"
mv "$pkgdir/usr/lib/openssl-1.0/libcrypto.so.1.0.0" "$pkgdir/usr/lib/"
mv "$pkgdir/usr/lib/openssl-1.0/libssl.so.1.0.0" "$pkgdir/usr/lib/"
ln -sf ../libssl.so.1.0.0 "$pkgdir/usr/lib/openssl-1.0/libssl.so"
ln -sf ../libcrypto.so.1.0.0 "$pkgdir/usr/lib/openssl-1.0/libcrypto.so"
mv "$pkgdir/usr/bin/openssl" "$pkgdir/usr/bin/openssl-1.0"
sed -e 's|/include$|/include/openssl-1.0|' -i "$pkgdir"/usr/lib/openssl-1.0/pkgconfig/*.pc
rm -rf "$pkgdir"/{etc,usr/bin/c_rehash}
install -D -m644 LICENSE "$pkgdir/usr/share/licenses/openssl-1.0/LICENSE"
echo " OK"

cd "$download_dir"
echo -n "Estrazione di dotnet 5.0..."
tar -xzf $dotnet.tar.gz -C "$pkgdir/usr/bin/"
echo " OK"

echo -n "Estrazione del patcher..."
tar -xzf "$patcher.tar.gz"
cd $patcher
mv *.sh "$pkgdir/usr/bin/"
mv Data "$pkgdir"
echo " OK"

echo -n "Modifica script di avvio..."
echo "#!/bin/bash
\$APPDIR/usr/bin/dotnet \$APPDIR/Data/SpaghettiCh2.dll" > "$pkgdir/usr/bin/ItalianPatcherLinux.sh"
echo " OK"

echo -n "Creazione file desktop..."
echo "[Desktop Entry]
Type=Application
Name=Italian Patcher By USP
Exec=ItalianPatcherLinux.sh
Icon=avalonia
Categories=Utility;" > "$pkgdir/spaghetti-project.desktop"
echo " OK"

echo "Download e conversione icona..."
curl -L -# "https://raw.githubusercontent.com/USPAssets/Installer/refs/tags/v1.0.0.0/SpaghettiCh2/SpaghettiCh2/Assets/avalonia-logo.ico" -o "$pkgdir/avalonia.ico"
magick "$pkgdir/avalonia.ico[7]" "$pkgdir/avalonia.png"
rm "$pkgdir/avalonia.ico"

echo -n "Creazione script AppRun..."
cat << 'EOF' > "$pkgdir/AppRun"
#!/bin/bash
if [ -z "$APPDIR" ]; then
    APPDIR="$(dirname "$(readlink -f "$0")")"
fi

export LD_LIBRARY_PATH="$APPDIR/usr/lib/:$LD_LIBRARY_PATH"

exec $APPDIR/usr/bin/ItalianPatcherLinux.sh
EOF
chmod +x "$pkgdir/AppRun"
echo " OK"

cd "$current_dir"

echo "Creazione AppImage..."
"$download_dir/appimagetool.AppImage" "$pkgdir" "ItalianPatcherByUSPLinux.AppImage"

echo -n "Pulizia file temporanei..."
rm -rf "$download_dir"
rm -rf "$pkgdir"
echo " OK"

echo "Build completata con successo!"
