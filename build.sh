#!/usr/bin/env bash
# shellcheck disable=SC1091

set -ex

. version.sh
echo before scribe-patch
# Added from Scribe v2 side
for file in ./scribe/initial/*.patch; do
  echo "${file}" - test
  if [[ -f "${file}" ]]; then
    echo applying scribe initial patch: "${file}";
    # grep '^+++' "${file}"  | sed -e 's#+++ [ab]/#./vscode/#' | while read line; do shasum -a 256 "${line}"; done
    if ! git apply --ignore-whitespace "${file}"; then
      echo failed to apply scribe initial patch "${file}" >&2
      exit 1
    fi
  fi
done
echo after scribe-patch
if [[ "${SHOULD_BUILD}" == "yes" ]]; then
  echo "MS_COMMIT=\"${MS_COMMIT}\""

  . prepare_vscode.sh

  cd vscode || { echo "'vscode' dir not found"; exit 1; }

  export NODE_OPTIONS="--max-old-space-size=8192"

  yarn monaco-compile-check
  yarn valid-layers-check

  yarn gulp compile-build
  yarn gulp compile-extension-media
  yarn gulp compile-extensions-build
  yarn gulp minify-vscode

  . ../scribe/embed_extensions.sh

  if [[ "${OS_NAME}" == "osx" ]]; then
    yarn gulp "vscode-darwin-${VSCODE_ARCH}-min-ci"

    find "../VSCode-darwin-${VSCODE_ARCH}" -print0 | xargs -0 touch -c

    VSCODE_PLATFORM="darwin"
  elif [[ "${OS_NAME}" == "windows" ]]; then
    . ../build/windows/rtf/make.sh

    yarn gulp "vscode-win32-${VSCODE_ARCH}-min-ci"

    if [[ "${VSCODE_ARCH}" != "ia32" && "${VSCODE_ARCH}" != "x64" ]]; then
      SHOULD_BUILD_REH="no"
    fi

    VSCODE_PLATFORM="win32"
  else # linux
    # in CI, packaging will be done by a different job
    if [[ "${CI_BUILD}" == "no" ]]; then
      yarn gulp "vscode-linux-${VSCODE_ARCH}-min-ci"

      find "../VSCode-linux-${VSCODE_ARCH}" -print0 | xargs -0 touch -c
    fi

    VSCODE_PLATFORM="linux"
  fi

  if [[ "${SHOULD_BUILD_REH}" != "no" ]]; then
    if [[ "${OS_NAME}" == "linux" ]]; then
      export VSCODE_NODE_GLIBC='-glibc-2.17'
    fi

    yarn gulp minify-vscode-reh
    yarn gulp "vscode-reh-${VSCODE_PLATFORM}-${VSCODE_ARCH}-min-ci"
  fi

  cd ..
fi
