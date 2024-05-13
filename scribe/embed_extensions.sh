echo embedding ScriptureEditor extensions

mkdir -p .build/extensions
cd .build

while IFS=': ' read -r name url; do
  echo ${url} test ${name}
  wget -nv -O "$name".zip "$url"
  mkdir -p ./extensions/"$name"
  # tar xf "$name".zip --strip-components=1 -C ./extensions/"$name"
  unzip -qq "$name".zip -d ./extensions/"$name"
  # mv .extensions/"$name"/*/*(D) .extensions/"$name"
  mv ./extensions/"$name"/extension/* ./extensions/"$name"/
  find ./extensions/"$name"/ -type d -name "node_modules" -exec rm -rf {} +
  # yarn install --cwd ./extensions/"$name"
  # npm install --omit=dev --prefix ./extensions/"$name"
  # find ./extensions/"$name" ! -path "*/node_modules/*" -name "package.json" -execdir npm install \;
  rm "$name".zip
done <<EOF
project-accelerate.codex-editor-extension: https://open-vsx.org/api/project-accelerate/codex-editor-extension/0.0.12/file/project-accelerate.codex-editor-extension-0.0.12.vsix
project-accelerate.scripture-language-support: https://open-vsx.org/api/project-accelerate/scripture-language-support/0.0.6/file/project-accelerate.scripture-language-support-0.0.6.vsix
project-accelerate.shared-state-store: https://open-vsx.org/api/project-accelerate/shared-state-store/0.0.2/file/project-accelerate.shared-state-store-0.0.2.vsix
project-accelerate.pythoninstaller: https://open-vsx.org/api/project-accelerate/pythoninstaller/0.0.6/file/project-accelerate.pythoninstaller-0.0.6.vsix
project-accelerate.codex-chat-and-comments: https://open-vsx.org/api/project-accelerate/codex-chat-and-comments/0.0.2/file/project-accelerate.codex-chat-and-comments-0.0.2.vsix
project-accelerate.codex-project-manager: https://open-vsx.org/api/project-accelerate/codex-project-manager/0.0.2/file/project-accelerate.codex-project-manager-0.0.2.vsix
project-accelerate.codex-scripture-viewer: https://open-vsx.org/api/project-accelerate/codex-scripture-viewer/0.0.2/file/project-accelerate.codex-scripture-viewer-0.0.2.vsix
EOF

cd ..