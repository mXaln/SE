#!/usr/bin/env bash
# shellcheck disable=SC1091,2154

set -e

# include common functions
. ./utils.sh

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  cp -rp src/insider/* vscode/
else
  cp -rp src/stable/* vscode/
fi

cp -f LICENSE vscode/LICENSE.txt

cd vscode || { echo "'vscode' dir not found"; exit 1; }

../update_settings.sh

# apply patches
{ set +x; } 2>/dev/null
# mv ../patches/build-version.patch ../patches/build-version.patchIgnore // Avoiding the below line because we are keeping the same version number
for file in ../patches/*.patch; do
  if [[ -f "${file}" ]]; then
    echo applying patch: "${file}";
    # grep '^+++' "${file}"  | sed -e 's#+++ [ab]/#./vscode/#' | while read line; do shasum -a 256 "${line}"; done
    if ! git apply --ignore-whitespace "${file}"; then
      echo failed to apply patch "${file}" >&2
      exit 1
    fi
  fi
done

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  for file in ../patches/insider/*.patch; do
    if [[ -f "${file}" ]]; then
      echo applying patch: "${file}";
      if ! git apply --ignore-whitespace "${file}"; then
        echo failed to apply patch "${file}" >&2
        exit 1
      fi
    fi
  done
fi

for file in ../patches/user/*.patch; do
  if [[ -f "${file}" ]]; then
    echo applying user patch: "${file}";
    if ! git apply --ignore-whitespace "${file}"; then
      echo failed to apply patch "${file}" >&2
      exit 1
    fi
  fi
done

#Add below content manually
for file in ../scribe/patches/*.patch; do
  if [[ -f "${file}" ]]; then
    echo applying scribe main patch: "${file}";
    # grep '^+++' "${file}"  | sed -e 's#+++ [ab]/#./vscode/#' | while read line; do shasum -a 256 "${line}"; done
    if ! git apply --3way "${file}"; then
      echo failed to apply scribe main patch "${file}" >&2
      exit 1
    fi
  fi
done
chmod a+x ../scribe/scribe.sh
../scribe/scribe.sh

if [[ -d "../patches/${OS_NAME}/" ]]; then
  for file in "../patches/${OS_NAME}/"*.patch; do
    if [[ -f "${file}" ]]; then
      echo applying patch: "${file}";
      if ! git apply --ignore-whitespace "${file}"; then
        echo failed to apply patch "${file}" >&2
        exit 1
      fi
    fi
  done
fi

set -x

export ELECTRON_SKIP_BINARY_DOWNLOAD=1
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

if [[ "${OS_NAME}" == "linux" ]]; then
  export VSCODE_SKIP_NODE_VERSION_CHECK=1

   if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi

  CHILD_CONCURRENCY=1 yarn --frozen-lockfile --check-files --network-timeout 180000
elif [[ "${OS_NAME}" == "osx" ]]; then
  CHILD_CONCURRENCY=1 yarn --frozen-lockfile --network-timeout 180000

  yarn postinstall
else
  # TODO: Should be replaced with upstream URL once https://github.com/nodejs/node-gyp/pull/2825
  # gets merged.
  rm -rf .build/node-gyp
  mkdir -p .build/node-gyp
  cd .build/node-gyp

  git config --global user.email "$( echo "${GITHUB_USERNAME}" | awk '{print tolower($0)}' )-ci@not-real.com"
  git config --global user.name "${GITHUB_USERNAME} CI"
  git clone https://github.com/nodejs/node-gyp.git .
  git checkout v10.0.1
  npm install

  npm_config_node_gyp="$( pwd )/bin/node-gyp.js"
  export npm_config_node_gyp

  cd ../..

  if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi

  CHILD_CONCURRENCY=1 yarn --frozen-lockfile --check-files --network-timeout 180000
fi

setpath() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --arg 'path' "${2}" --arg 'value' "${3}" 'setpath([$path]; $value)' "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

setpath_json() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --arg 'path' "${2}" --argjson 'value' "${3}" 'setpath([$path]; $value)' "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

# product.json
cp product.json{,.bak}

setpath "product" "checksumFailMoreInfoUrl" "https://go.microsoft.com/fwlink/?LinkId=828886"
setpath "product" "documentationUrl" "https://go.microsoft.com/fwlink/?LinkID=533484#vscode"
setpath_json "product" "extensionsGallery" '{"serviceUrl": "https://open-vsx.org/vscode/gallery", "itemUrl": "https://open-vsx.org/vscode/item"}'
setpath "product" "introductoryVideosUrl" "https://go.microsoft.com/fwlink/?linkid=832146"
setpath "product" "keyboardShortcutsUrlLinux" "https://go.microsoft.com/fwlink/?linkid=832144"
setpath "product" "keyboardShortcutsUrlMac" "https://go.microsoft.com/fwlink/?linkid=832143"
setpath "product" "keyboardShortcutsUrlWin" "https://go.microsoft.com/fwlink/?linkid=832145"
setpath "product" "licenseUrl" "https://github.com/Bridgeconn/oak/blob/master/LICENSE"
setpath_json "product" "linkProtectionTrustedDomains" '["https://open-vsx.org"]'
setpath "product" "releaseNotesUrl" "https://go.microsoft.com/fwlink/?LinkID=533483#vscode"
setpath "product" "reportIssueUrl" "https://github.com/Bridgeconn/oak/issues/new"
setpath "product" "requestFeatureUrl" "https://go.microsoft.com/fwlink/?LinkID=533482"
setpath "product" "tipsAndTricksUrl" "https://go.microsoft.com/fwlink/?linkid=852118"
setpath "product" "twitterUrl" "https://go.microsoft.com/fwlink/?LinkID=533687"

if [[ "${DISABLE_UPDATE}" != "yes" ]]; then
  setpath "product" "updateUrl" "https://vscodium.now.sh"
  setpath "product" "downloadUrl" "https://github.com/Bridgeconn/oak/releases"
fi

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  setpath "product" "nameShort" "ScriptureEditor - Insiders"
  setpath "product" "nameLong" "ScriptureEditor - Insiders"
  setpath "product" "applicationName" "codium-insiders"
  setpath "product" "dataFolderName" ".scriptureEditor-insiders"
  setpath "product" "linuxIconName" "scriptureEditor-insiders"
  setpath "product" "quality" "insider"
  setpath "product" "urlProtocol" "scriptureEditor-insiders"
  setpath "product" "serverApplicationName" "codium-server-insiders"
  setpath "product" "serverDataFolderName" ".scriptureeditor-server-insiders"
  setpath "product" "darwinBundleIdentifier" "com.scriptureEditor.ScriptureInsiders"
  setpath "product" "win32AppUserModelId" "ScriptureEditor.ScriptureInsiders"
  setpath "product" "win32DirName" "ScriptureEditor Insiders"
  setpath "product" "win32MutexName" "scriptureeditorinsiders"
  setpath "product" "win32NameVersion" "ScriptureEditor Insiders"
  setpath "product" "win32RegValueName" "ScriptureEditorInsiders"
  setpath "product" "win32ShellNameShort" "ScriptureEditor Insiders"
  setpath "product" "win32AppId" "{{EF35BB36-FA7E-4BB9-B7DA-D1E09F2DA9C9}"
  setpath "product" "win32x64AppId" "{{B2E0DDB2-120E-4D34-9F7E-8C688FF839A2}"
  setpath "product" "win32arm64AppId" "{{44721278-64C6-4513-BC45-D48E07830599}"
  setpath "product" "win32UserAppId" "{{ED2E5618-3E7E-4888-BF3C-A6CCC84F586F}"
  setpath "product" "win32x64UserAppId" "{{20F79D0D-A9AC-4220-9A81-CE675FFB6B41}"
  setpath "product" "win32arm64UserAppId" "{{2E362F92-14EA-455A-9ABD-3E656BBBFE71}"
else
  setpath "product" "nameShort" "ScriptureEditor"
  setpath "product" "nameLong" "ScriptureEditor"
  setpath "product" "applicationName" "ScriptureEditor"
  setpath "product" "linuxIconName" "ScriptureEditor"
  setpath "product" "quality" "stable"
  setpath "product" "urlProtocol" "ScriptureEditor"
  setpath "product" "serverApplicationName" "scriptureEditor-server"
  setpath "product" "serverDataFolderName" ".scriptureEditor-server"
  setpath "product" "darwinBundleIdentifier" "com.scriptureEditor"
  setpath "product" "win32AppUserModelId" "ScriptureEditor.ScriptureEditor"
  setpath "product" "win32DirName" "ScriptureEditor"
  setpath "product" "win32MutexName" "scriptureeditor"
  setpath "product" "win32NameVersion" "ScriptureEditor"
  setpath "product" "win32RegValueName" "scriptureeditor"
  setpath "product" "win32ShellNameShort" "scriptureeditor"
  setpath "product" "win32AppId" "{{763CBF88-25C6-4B10-952F-326AE657F16B}"
  setpath "product" "win32x64AppId" "{{88DA3577-054F-4CA1-8122-7D820494CFFB}"
  setpath "product" "win32arm64AppId" "{{67DEE444-3D04-4258-B92A-BC1F0FF2CAE4}"
  setpath "product" "win32UserAppId" "{{0FD05EB4-651E-4E78-A062-515204B47A3A}"
  setpath "product" "win32x64UserAppId" "{{2E1F05D1-C245-4562-81EE-28188DB6FD17}"
  setpath "product" "win32arm64UserAppId" "{{57FD70A5-1B8D-4875-9F40-C5553F094828}"
fi

jsonTmp=$( jq -s '.[0] * .[1]' product.json ../product.json )
echo "${jsonTmp}" > product.json && unset jsonTmp

cat product.json

# package.json
cp package.json{,.bak}

 #setpath "package" "version" "$( echo "${RELEASE_VERSION}")" //Removing the below lines because we will be using same versioning
setpath "package" "version" "$( echo "${RELEASE_VERSION}" | sed -n -E "s/^(.*)\.([0-9]+)(-insider)?$/\1/p" )"
setpath "package" "release" "$( echo "${RELEASE_VERSION}" | sed -n -E "s/^(.*)\.([0-9]+)(-insider)?$/\2/p" )"

replace 's|Microsoft Corporation|ScriptureEditor|' package.json

# announcements
replace "s|\\[\\/\\* BUILTIN_ANNOUNCEMENTS \\*\\/\\]|$( tr -d '\n' < ../announcements-builtin.json )|" src/vs/workbench/contrib/welcomeGettingStarted/browser/gettingStarted.ts

../undo_telemetry.sh

replace 's|Microsoft Corporation|ScriptureEditor|' build/lib/electron.js
replace 's|Microsoft Corporation|ScriptureEditor|' build/lib/electron.ts
replace 's|([0-9]) Microsoft|\1 ScriptureEditor|' build/lib/electron.js
replace 's|([0-9]) Microsoft|\1 ScriptureEditor|' build/lib/electron.ts

if [[ "${OS_NAME}" == "linux" ]]; then
  # microsoft adds their apt repo to sources
  # unless the app name is code-oss
  # as we are renaming the application to ScriptureEditor
  # we need to edit a line in the post install template
  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    sed -i "s/code-oss/codium-insiders/" resources/linux/debian/postinst.template
  else
    sed -i "s/code-oss/codium/" resources/linux/debian/postinst.template
  fi

  # fix the packages metadata
  # code.appdata.xml
  sed -i 's|Visual Studio Code|ScriptureEditor|g' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/Bridgeconn/oak/blob/master/README.md|' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com/home/home-screenshot-linux-lg.png|https://vscodium.com/img/vscodium.png|' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com|https://scribe.bible/|' resources/linux/code.appdata.xml

  # control.template
  sed -i 's|Microsoft Corporation <vscode-linux@microsoft.com>|ScriptureEditor Team https://github.com/Bridgeconn/oak/graphs/contributors|'  resources/linux/debian/control.template
  sed -i 's|https://code.visualstudio.com|https://scribe.bible/|' resources/linux/debian/control.template
  sed -i 's|Visual Studio Code|ScriptureEditor|g' resources/linux/debian/control.template
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/Bridgeconn/oak/blob/master/README.md|' resources/linux/debian/control.template

  # code.spec.template
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/Bridgeconn/oak/blob/master/README.md|' resources/linux/rpm/code.spec.template
  sed -i 's|Microsoft Corporation|ScriptureEditor Team|' resources/linux/rpm/code.spec.template
  sed -i 's|Visual Studio Code Team <vscode-linux@microsoft.com>|ScriptureEditor Team https://github.com/Bridgeconn/oak/graphs/contributors|' resources/linux/rpm/code.spec.template
  sed -i 's|https://code.visualstudio.com|https://scribe.bible/|' resources/linux/rpm/code.spec.template
  sed -i 's|Visual Studio Code|ScriptureEditor|' resources/linux/rpm/code.spec.template

  # snapcraft.yaml
  sed -i 's|Visual Studio Code|ScriptureEditor|'  resources/linux/rpm/code.spec.template
elif [[ "${OS_NAME}" == "windows" ]]; then
  # code.iss
  sed -i 's|https://code.visualstudio.com|https://scribe.bible/|' build/win32/code.iss
  sed -i 's|Microsoft Corporation|ScriptureEditor|' build/win32/code.iss
fi

cd ..