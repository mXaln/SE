echo embedding ScriptureEditor extensions

while IFS=': ' read -r name url; do
  echo ${url} test ${name}
  wget -O "$name".zip "$url"
  mkdir -p ./extensions/"$name"
  tar xvf "$name".zip --strip-components=1 -C ./extensions/"$name"
  # unzip "$name".zip -d ./extensions/"$name"
  # mv .extensions/"$name"/*/*(D) .extensions/"$name"
  # mv ./extensions/"$name"/extension/* ./extensions/"$name"/
  # yarn install --cwd ./extensions/"$name"
  npm install --omit=dev --prefix ./extensions/"$name"
  find ./extensions/"$name" ! -path "*/node_modules/*" -name "package.json" -execdir npm install \;
  rm "$name".zip
done <<EOF
custom.codex-project-manager: https://github.com/genesis-ai-dev/codex-project-manager/archive/refs/heads/main.zip
custom.codex-chat-and-comments: https://github.com/genesis-ai-dev/codex-comments-and-chat/archive/refs/heads/main.zip
custom.codex-scripture-viewer: https://github.com/genesis-ai-dev/codex-scripture-viewer/archive/refs/heads/main.zip
custom.codex-editor-extension: https://github.com/genesis-ai-dev/codex-editor/archive/refs/heads/main.zip
custom.scripture-language-support: https://github.com/ryderwishart/scripture-language-support/archive/refs/heads/main.zip
custom.shared-state-store: https://github.com/genesis-ai-dev/shared-state-store/archive/refs/heads/main.zip
custom.pythoninstaller: https://github.com/genesis-ai-dev/PythonInstaller/archive/refs/heads/main.zip
custom.python: https://github.com/microsoft/vscode-python/archive/refs/heads/main.zip
EOF