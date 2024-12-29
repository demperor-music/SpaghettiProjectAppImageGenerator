#!/usr/bin/env bash
set -euo pipefail
current_dir=$(pwd)

_download_dir="/tmp/SpaghettiProjectAppImage/download"
_pkgdir="/tmp/SpaghettiProjectAppImage/AppDir"
_debug_mode=false


readonly PATCHER="ItalianPatcherByUSPLinux"
readonly DOTNET="dotnet50"
readonly OPENSSL="openssl-1.0.2u"

readonly BASE_URL_GITHUB="https://github.com/USPAssets/Installer/releases/latest/download"
readonly PATCHER_URL="$BASE_URL_GITHUB/$PATCHER.tar.gz"
readonly DOTNET_URL="https://download.visualstudio.microsoft.com/download/pr/a2b96f83-e22a-4fa6-a10e-709b3effac9a/0d6ade6c0ceebc8ef7dbf2b1a6d86f17/aspnetcore-runtime-5.0.17-linux-x64.tar.gz"
readonly OPENSSL_URL="https://www.openssl.org/source/$OPENSSL.tar.gz"
readonly APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
readonly ICON_URL="https://raw.githubusercontent.com/USPAssets/Installer/refs/tags/v1.0.0.0/SpaghettiCh2/SpaghettiCh2/Assets/avalonia-logo.ico"
readonly ICON_INDEX=-1
# ↑ Quando si converte un file .ico con imagemagick, si può specificare quale risoluzione sia quella desiderata. Vogliamo la risoluzione più alta (-1).

function debug_echo() {
    if $_debug_mode; then
      echo "${1:-$(cat -)}"
    else
      cat - > /dev/null
    fi
}

function check_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Errore: comando \"$1\" non trovato." >&2
    exit 1
  }
}

echo -n "Controllo dipendenze... "
check_command curl
check_command tar
check_command magick
check_command make
check_command gcc
check_command g++
check_command perl
echo "OK"

function show_help() {
  echo "Usage:	$0 [OPTIONS]"
  echo
  echo "Opzioni:"
  echo "	-f <file>	Usa un file .tar.gz personalizzato invece dell'ultima release."
  echo "	-k		Conserva i file temporanei alla fine."
  echo "	-d		Mostra output verboso."
  echo "	-h		Mostra questa guida e esce."
}

custom_file=""
keep_temp=false

while getopts "df:kch" opt; do
  case $opt in
    f) custom_file=$OPTARG ;;
    k) keep_temp=true ;;
    h) show_help; exit 0 ;;
    d) _debug_mode=true ;;
    *) show_help; exit 1 ;;
  esac
done

download_latest=$([ -z "$custom_file" ] && echo "true" || echo "false")

# Determina il file .tar.gz da usare
if $download_latest; then
  patcher_file="$PATCHER_URL"
else
  if [ ! -f "$custom_file" ]; then
    echo "Errore: il file fornito non esiste. Uscita."
    exit 1
  fi
  patcher_file="$custom_file"
fi


# Se $_pkgdir esiste già e non è vuota...
if [ -e "$_pkgdir" ] && [ -n "$(ls -A "$_pkgdir")" ]; then
  echo -n "La directory $_pkgdir non è vuota e sarà necessario eliminarla. Vuoi continuare? (S/n) "
  local confirmation=""
  read -r confirmation
  if [[ "$confirmation" =~ [nN] ]]; then
    echo "Operazione annullata."
    exit 1
  else
    rm -rf "$_pkgdir"
    echo "$_pkgdir è stato eliminato."
  fi
fi


mkdir -p "$_download_dir" "$_pkgdir"
cd "$_download_dir"

if $download_latest; then
  echo "Scaricamento di $PATCHER..."
  curl -L -# "$patcher_file" -o "$PATCHER.tar.gz"
else
  echo "Usando il file personalizzato fornito: $patcher_file"
fi

echo "Scaricamento di $DOTNET..."
curl -L -# "$DOTNET_URL" -o "$DOTNET.tar.gz"

echo "Scaricamento di $OPENSSL..."
curl -L -# "$OPENSSL_URL" -o "$OPENSSL.tar.gz"

echo "Scaricamento di AppImageTool..."
curl -L -# "$APPIMAGETOOL_URL" -o "appimagetool.AppImage"
chmod +x appimagetool.AppImage


echo "Verrà compilato OpenSSL 1.0. Il processo potrebbe richiedere un paio di minuti..."

echo -n "Estrazione di $OPENSSL..."
mkdir -p openssl_build
cd openssl_build
tar -xzf "$_download_dir/$OPENSSL.tar.gz"
cd "$OPENSSL"
echo " OK"

echo -n "Configurando openssl..."
./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib/openssl-1.0 shared no-ssl3-method 2>&1 | debug_echo
echo " OK"

echo -n "Generando dipendenze di openssl..."
make depend 2>&1 | debug_echo
echo " OK"

echo -n "Compilando OpenSSL..."
make 2>&1 | debug_echo
echo " OK"

echo -n "Installando OpenSSL in $_pkgdir..."
# ↓ Preso in prestito da https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=openssl-1.0
make INSTALL_PREFIX="$_pkgdir" install_sw | debug_echo
install -m755 -d "$_pkgdir/usr/include/openssl-1.0"
mv "$_pkgdir/usr/include/openssl" "$_pkgdir/usr/include/openssl-1.0/"
mv "$_pkgdir/usr/lib/openssl-1.0/libcrypto.so.1.0.0" "$_pkgdir/usr/lib/"
mv "$_pkgdir/usr/lib/openssl-1.0/libssl.so.1.0.0" "$_pkgdir/usr/lib/"
ln -sf ../libssl.so.1.0.0 "$_pkgdir/usr/lib/openssl-1.0/libssl.so"
ln -sf ../libcrypto.so.1.0.0 "$_pkgdir/usr/lib/openssl-1.0/libcrypto.so"
mv "$_pkgdir/usr/bin/openssl" "$_pkgdir/usr/bin/openssl-1.0"
sed -e 's|/include$|/include/openssl-1.0|' -i "$_pkgdir"/usr/lib/openssl-1.0/pkgconfig/*.pc
rm -rf "$_pkgdir"/{etc,usr/bin/c_rehash}
install -D -m644 LICENSE "$_pkgdir/usr/share/licenses/openssl-1.0/LICENSE"
echo " OK"


cd "$_download_dir"
echo -n "Estrazione di dotnet 5.0..."
tar -xzf "$DOTNET.tar.gz" -C "$_pkgdir/usr/bin/"
echo " OK"

echo -n "Estrazione del patcher..."
tar -xzf "$patcher_file"
echo " OK"

mv $PATCHER/*.sh "$_pkgdir/usr/bin/"
mv $PATCHER/Data "$_pkgdir"

echo -n "Modifica script di avvio..."
echo "#!/bin/bash
\$APPDIR/usr/bin/dotnet \$APPDIR/Data/SpaghettiCh2.dll" > "$_pkgdir/usr/bin/ItalianPatcherLinux.sh"
echo " OK"

echo -n "Creazione file desktop..."
echo "[Desktop Entry]
Type=Application
Name=Italian Patcher By USP
Exec=ItalianPatcherLinux.sh
Icon=avalonia
Categories=Utility;" > "$_pkgdir/spaghetti-project.desktop"
echo " OK"

echo "Download e conversione icona..."
curl -L -# "$ICON_URL" -o "$_pkgdir/avalonia.ico"
magick "$_pkgdir/avalonia.ico[$ICON_INDEX]" "$_pkgdir/avalonia.png"
rm "$_pkgdir/avalonia.ico"

echo -n "Creazione script AppRun..."
cat << 'EOF' > "$_pkgdir/AppRun"
#!/bin/bash
if [ -z "$APPDIR" ]; then
    APPDIR="$(dirname "$(readlink -f "$0")")"
fi

export LD_LIBRARY_PATH="$APPDIR/usr/lib/:$LD_LIBRARY_PATH"

exec $APPDIR/usr/bin/ItalianPatcherLinux.sh
EOF
chmod +x "$_pkgdir/AppRun"
echo " OK"

cd "$current_dir"
echo "Creazione AppImage..."
"$_download_dir/appimagetool.AppImage" "$_pkgdir" "ItalianPatcherByUSPLinux.AppImage"

if ! $keep_temp; then
  echo -n "Pulizia file temporanei..."
  rm -rf "$_download_dir"
  rm -rf "$_pkgdir"
  echo " OK"
fi

echo "Build completata con successo!"

