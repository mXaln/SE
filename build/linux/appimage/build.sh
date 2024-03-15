#!/usr/bin/env bash

set -ex

CALLER_DIR=$( pwd )

cd "$( dirname "${BASH_SOURCE[0]}" )"

if [[ "${VSCODE_ARCH}" == "x64" ]]; then
  GITHUB_RESPONSE=$( curl --silent --location "https://api.github.com/repos/AppImage/pkg2appimage/releases/latest" )
  APPIMAGE_URL=$( echo "${GITHUB_RESPONSE}" | jq --raw-output '.assets | map(select( .name | test("x86_64.AppImage(?!.zsync)"))) | map(.browser_download_url)[0]' )

  if [[ -z "${APPIMAGE_URL}" ]]; then
    echo "The url for pkg2appimage.AppImage hasn't been found"
    exit 1
  fi

  wget -c "${APPIMAGE_URL}" -O pkg2appimage.AppImage

  chmod +x ./pkg2appimage.AppImage

  ./pkg2appimage.AppImage --appimage-extract && mv ./squashfs-root ./pkg2appimage.AppDir
  # ./pkg2appimage.AppImage --appimage-extract && rsync -a ./squashfs-root ./pkg2appimage.AppDir
  echo "bridge 1"
  # add update's url
  sed -i 's/generate_type2_appimage/generate_type2_appimage -u "gh-releases-zsync|Bridgeconn|oak|latest|*.AppImage.zsync"/' pkg2appimage.AppDir/AppRun
echo "bridge 2"
  # remove check so build in docker can succeed
  sed -i 's/grep docker/# grep docker/' pkg2appimage.AppDir/usr/share/pkg2appimage/functions.sh
echo "bridge 3"
  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    sed -i 's|@@NAME@@|ScribeCodex-Insiders|g' recipe.yml
    sed -i 's|@@APPNAME@@|scribecodex-insiders|g' recipe.yml
    sed -i 's|@@ICON@@|vscodium-insiders|g' recipe.yml
  else
    sed -i 's|@@NAME@@|ScribeCodex|g' recipe.yml
    echo "bridge 4"
    sed -i 's|@@APPNAME@@|scribecodex|g' recipe.yml
    echo "bridge 5"
    sed -i 's|@@ICON@@|vscodium|g' recipe.yml
  fi
echo "bridge 6"
  bash -ex pkg2appimage.AppDir/AppRun recipe.yml
echo "bridge 7"
  rm -f pkg2appimage-*.AppImage
  rm -rf pkg2appimage.AppDir
  rm -rf VSCodium*
  rm -rf ScribeCodex*
fi
echo "bridge 8"
cd "${CALLER_DIR}"
