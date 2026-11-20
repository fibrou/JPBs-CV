#!/usr/bin/env bash
# publish.sh: rebuild the CV from cv.db and put it on the web in one step.
#
#   ./publish.sh                      rebuild, commit, publish
#   ./publish.sh "Added new paper"    same, with your own commit message
#   ./publish.sh --citations          refresh CrossRef citation counts first
#   ./publish.sh --local              rebuild only; nothing is committed or pushed
#
# What it does, in order:
#   1. (optional) refreshes CrossRef citation counts in cv.db
#   2. renders the PDF CV (jpbDataDrivenCV.pdf) from cv.db
#   3. renders the website into _site/ from cv.db
#   4. commits your source changes (including cv.db) and pushes them to GitHub
#   5. runs `quarto publish gh-pages`, which puts the built site live at
#      https://fibrou.github.io/JPBs-CV/

set -euo pipefail
cd "$(dirname "$0")"

citations=false
local_only=false
message=""
for arg in "$@"; do
  case "$arg" in
    --citations) citations=true ;;
    --local)     local_only=true ;;
    -h|--help)   sed -n 2,16p "$0"; exit 0 ;;
    *)           message="$arg" ;;
  esac
done
[ -n "$message" ] || message="CV update $(date +%Y-%m-%d)"

# Nextcloud syncs this folder, git internals included, and keeps restoring an
# old, empty git lock file (the server refuses to let it be deleted). Clear it
# before each git step, as long as no git command is actually running.
clear_lock() {
  if [ -e .git/index.lock ] && ! pgrep -x git >/dev/null; then
    rm -f .git/index.lock
  fi
}

if $citations; then
  echo "==> Refreshing CrossRef citation counts"
  Rscript fetch_citations.R
fi

echo "==> Rendering the PDF CV"
Rscript -e 'rmarkdown::render("jpbDataDrivenCV.Rmd", output_file = "jpbDataDrivenCV.pdf", quiet = TRUE)'

echo "==> Rendering the website"
quarto render

if $local_only; then
  echo "Done. Preview the site with: quarto preview   (PDF: jpbDataDrivenCV.pdf)"
  exit 0
fi

echo "==> Saving your changes to GitHub"
clear_lock
git add -A
if git diff --cached --quiet; then
  echo "No source changes to commit."
else
  clear_lock
  git commit -m "$message"
fi
clear_lock
git push origin main

echo "==> Publishing the site"
quarto publish gh-pages --no-render --no-prompt --no-browser

echo "Done. The site updates within a minute or two: https://fibrou.github.io/JPBs-CV/"
