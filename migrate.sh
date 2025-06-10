#!/bin/bash

set -e

# --------------------------------------
# CONFIGURATION
# --------------------------------------
REPOS_FILE="repos.txt"
CLONE_DIR="output"
BRANCH_NAME="rewrite-migration"
LOG_FILE="migration.log"

# --------------------------------------
# LOGGING UTILS
# --------------------------------------
log() {
  local type="$1"; shift
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')

  case "$type" in
    INFO) echo -e "[${ts}] \033[1;34mINFO\033[0m: $*" | tee -a "$LOG_FILE" ;;
    SUCCESS) echo -e "[${ts}] \033[1;32mSUCCESS\033[0m: $*" | tee -a "$LOG_FILE" ;;
    WARN) echo -e "[${ts}] \033[1;33mWARNING\033[0m: $*" | tee -a "$LOG_FILE" ;;
    ERROR) echo -e "[${ts}] \033[1;31mERROR\033[0m: $*" | tee -a "$LOG_FILE" ;;
    *) echo -e "[${ts}] $*" | tee -a "$LOG_FILE" ;;
  esac
}

# --------------------------------------
# START
# --------------------------------------
log INFO "🚀 Starting migration runner..."

if [[ ! -f "$REPOS_FILE" ]]; then
  log ERROR "Repository list file '$REPOS_FILE' not found!"
  exit 1
fi

mkdir -p "$CLONE_DIR"

while IFS= read -r repo_url || [[ -n "$repo_url" ]]; do
  [[ -z "$repo_url" || "$repo_url" =~ ^# ]] && continue

  repo_name=$(basename "$repo_url" .git)
  repo_dir="${CLONE_DIR}/${repo_name}"

  log INFO "📦 Cloning $repo_url..."
  if [ -d "$repo_dir" ]; then
    log WARN "Repository $repo_name already exists. Pulling latest changes..."
    (cd "$repo_dir" && git pull) || { log ERROR "Failed to pull $repo_name"; continue; }
  else
    git clone "$repo_url" "$repo_dir" || { log ERROR "Failed to clone $repo_url"; continue; }
  fi

  cd "$repo_dir" || { log ERROR "Failed to enter directory $repo_dir"; continue; }

  # Check for Gradle
  if [[ ! -f "build.gradle" && ! -f "build.gradle.kts" ]]; then
    log WARN "No Gradle build file found in $repo_name. Skipping..."
    cd - >/dev/null
    continue
  fi

  # Create migration branch
  git checkout -b "$BRANCH_NAME" || git checkout "$BRANCH_NAME"
  log INFO "🛠️  Running OpenRewrite migration in $repo_name..."

  # Run Rewrite (logs will be appended to file)
  {
    ./gradlew rewriteRun --init-script ../../init.gradle --stacktrace
  } &>> "../../$LOG_FILE" || {
    log ERROR "Rewrite run failed in $repo_name"
    cd - >/dev/null
    continue
  }

  # Check for changes
  if [[ -n $(git status --porcelain) ]]; then
    git add .
    git commit -m "Applied OpenRewrite migrations" || log WARN "Nothing to commit in $repo_name"
    log SUCCESS "✅ Migration complete for $repo_name (changes committed on $BRANCH_NAME)"
  else
    log INFO "No changes detected for $repo_name"
  fi

  cd - >/dev/null
done < "$REPOS_FILE"

log SUCCESS "🎉 Migration script completed. Check '$LOG_FILE' for details."