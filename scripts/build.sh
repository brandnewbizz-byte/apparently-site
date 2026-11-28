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
# --clear: Metro's cache is shared by every checkout of the app on this Mac
# (they share node_modules), and a cached router could point at another
# checkout's screens. On Nov 27 2026 that shipped a web app with no screens.
(cd "$APP" && rm -rf dist-web-app && WEB_BASE_URL=/app npx expo export -p web --output-dir dist-web-app --clear)
# Never ship a web app without its screens.
if ! grep -rqs "Welcome back" "$APP/dist-web-app/_expo/static/js/web/"; then
  echo "The web app build has no sign-in screen: something's wrong with the build. Not shipping it." >&2
  exit 1
fi

rm -rf "$HERE/site"
cp -a "$DASH/dist" "$HERE/site"
cp -a "$APP/dist-web-app" "$HERE/site/app"
cat > "$HERE/site/app/.htaccess" <<'HT'
# Apparently web app: send any /app/... path to the app's start file.
# The start file must never be cached, or browsers keep running an old build
# (its scripts have new names every build, so those can be cached forever).
# The QR decoder (zxing_reader.wasm) is served from here, not a CDN.
AddType application/wasm .wasm
<IfModule mod_headers.c>
<FilesMatch "\.html$">
Header set Cache-Control "no-cache, no-store, must-revalidate"
</FilesMatch>
<FilesMatch "\.(js|css|png|jpg|ttf|woff2?|wasm)$">
Header set Cache-Control "public, max-age=31536000, immutable"
</FilesMatch>
</IfModule>
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /app/
# The app's address is theapparentlyapp.com (Nov 27 2026): the old address
# and www forward there with the same path. (The site's root .htaccess does
# the same for everything outside /app.)
RewriteCond %{HTTP_HOST} ^apparentlyappdashboard\.nationalcompliancehub\.com$ [NC,OR]
RewriteCond %{HTTP_HOST} ^www\.theapparentlyapp\.com$ [NC]
RewriteRule ^ https://theapparentlyapp.com%{REQUEST_URI} [L,R=301]
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
# Only the built site: never sweep up other local files in this repo.
git add -A site
git commit -q -m "$MSG" || { echo "No changes"; exit 0; }
git push -q origin main
echo "Pushed $(git rev-parse --short HEAD). Now in cPanel: Git Version Control → apparently-site → Update from Remote → Deploy HEAD Commit."
