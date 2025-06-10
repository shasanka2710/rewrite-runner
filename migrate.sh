#!/bin/bash

REPO_LIST_FILE="repos.txt"
CLONE_DIR="output"
INIT_SCRIPT="init.gradle"
CUSTOM_RECIPE_DIR="custom-recipe"

echo "Building custom recipe JAR..."
cd "$CUSTOM_RECIPE_DIR" || exit 1
./gradlew clean build || exit 1
cd - || exit 1

mkdir -p "$CLONE_DIR"

while IFS= read -r REPO_URL; do
  [[ -z "$REPO_URL" || "$REPO_URL" =~ ^# ]] && continue

  REPO_NAME=$(basename "$REPO_URL" .git)
  TARGET_DIR="$CLONE_DIR/$REPO_NAME"

  if [ -d "$TARGET_DIR" ]; then
    echo "Skipping $REPO_NAME: already exists."
    continue
  fi

  echo "Cloning $REPO_URL into $TARGET_DIR..."
  git clone "$REPO_URL" "$TARGET_DIR"

  echo "Running OpenRewrite on $REPO_NAME..."
  cd "$TARGET_DIR" || continue
  ./gradlew rewriteRun --init-script "../../$INIT_SCRIPT"
  cd - > /dev/null

done < "$REPO_LIST_FILE"

echo "✅ Migration complete."