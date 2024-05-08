echo embedding ScriptureEditor extensions

while IFS=': ' read -r name url; do
  echo ${url} test ${name}
  wget -O "$name".zip "$url"
  unzip "$name".zip -d ./extensions/"$name"
  mv ./extensions/"$name"/extension/* ./extensions/"$name"/
  # yarn install --cwd ./extensions/"$name"
  rm "$name".zip
done <<EOF
project-accelerate.codex-project-manager: https://open-vsx.org/api/project-accelerate/codex-project-manager/0.0.2/file/project-accelerate.codex-project-manager-0.0.2.vsix
project-accelerate.codex-chat-and-comments: https://open-vsx.org/api/project-accelerate/codex-chat-and-comments/0.0.2/file/project-accelerate.codex-chat-and-comments-0.0.2.vsix
project-accelerate.codex-scripture-viewer: https://open-vsx.org/api/project-accelerate/codex-scripture-viewer/0.0.2/file/project-accelerate.codex-scripture-viewer-0.0.2.vsix
EOF