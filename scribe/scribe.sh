jsonfile='{
  "project-accelerate.codex-editor-extension":"https://open-vsx.org/api/project-accelerate/codex-editor-extension/0.0.12/file/project-accelerate.codex-editor-extension-0.0.12.vsix",
  "project-accelerate.scripture-language-support": "https://open-vsx.org/api/project-accelerate/scripture-language-support/0.0.6/file/project-accelerate.scripture-language-support-0.0.6.vsix",
  "project-accelerate.shared-state-store": "https://open-vsx.org/api/project-accelerate/shared-state-store/0.0.2/file/project-accelerate.shared-state-store-0.0.2.vsix",
  "project-accelerate.pythoninstaller": "https://open-vsx.org/api/project-accelerate/pythoninstaller/0.0.6/file/project-accelerate.pythoninstaller-0.0.6.vsix",
  "project-accelerate.codex-chat-and-comments": "https://open-vsx.org/api/project-accelerate/codex-chat-and-comments/0.0.2/file/project-accelerate.codex-chat-and-comments-0.0.2.vsix",
  "project-accelerate.codex-project-manager": "https://open-vsx.org/api/project-accelerate/codex-project-manager/0.0.2/file/project-accelerate.codex-project-manager-0.0.2.vsix",
  "project-accelerate.codex-scripture-viewer": "https://open-vsx.org/api/project-accelerate/codex-scripture-viewer/0.0.2/file/project-accelerate.codex-scripture-viewer-0.0.2.vsix",
  "ms-python.python": "https://open-vsx.org/api/ms-python/python/2024.4.1/file/ms-python.python-2024.4.1.vsix"
}'

echo "$jsonfile" | jq -r 'to_entries | .[] | "\(.key)=\(.value)"' |
while IFS='=' read -r name url; do
  echo ${url} test ${name}
  curl "$url" -L -o "$name".zip
  unzip "$name".zip -d ./extensions/"$name"
  mv ./extensions/"$name"/extension/* ./extensions/"$name"/
  npm install --prefix ./extensions/"$name"
  rm "$name".zip
done