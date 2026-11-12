#!/usr/bin/env bash
# Rebuild site/ from the two source repos, then commit and push.
# Usage: scripts/build.sh "commit message"
# Expects apparentlyappdash and apparently-app checked out next to this repo.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DASH="${DASH:-$HERE/../apparentlyappdash}"
APP="${APP:-$HERE/../apparently-app}"
MSG="${1:-Site build}"

(cd "$DASH" && npx vite build)
(cd "$APP" && rm -rf dist-web-app && WEB_BASE_URL=/app npx expo export -p web --output-dir dist-web-app)

rm -rf "$HERE/site"
cp -a "$DASH/dist" "$HERE/site"
cp -a "$APP/dist-web-app" "$HERE/site/app"
cat > "$HERE/site/app/.htaccess" <<'HT'
# Apparently web app: send any /app/... path to the app's start file.
# The start file must never be cached, or browsers keep running an old build
# (its scripts have new names every build, so those can be cached forever).
<IfModule mod_headers.c>
<FilesMatch "\.html$">
Header set Cache-Control "no-cache, no-store, must-revalidate"
</FilesMatch>
<FilesMatch "\.(js|css|png|jpg|ttf|woff2?)$">
Header set Cache-Control "public, max-age=31536000, immutable"
</FilesMatch>
</IfModule>
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /app/
# Always use HTTPS.
RewriteCond %{HTTPS} !=on
RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
RewriteRule ^index\.html$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /app/index.html [L]
</IfModule>
HT

cd "$HERE"
git add -A
git commit -q -m "$MSG" || { echo "No changes"; exit 0; }
git push -q origin main
echo "Pushed $(git rev-parse --short HEAD). Now in cPanel: Git Version Control → apparently-site → Update from Remote → Deploy HEAD Commit."
