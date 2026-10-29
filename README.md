# apparently-site

Built files for https://apparentlyappdashboard.nationalcompliancehub.com — the admin dashboard
(from `apparentlyappdash`), the Apparently web app under `/app` (from `apparently-app`), and
the public `/concierge.html` page. No source code lives here.

cPanel pulls this repo and `.cpanel.yml` copies `site/` into the site's folder.

## Updating

1. `scripts/build.sh "what changed"` rebuilds `site/` from `apparentlyappdash` and `apparently-app`
   (checked out next to this repo) and pushes.
2. In cPanel → Git™ Version Control → apparently-site: **Update from Remote**, then **Deploy HEAD Commit**
   (UAPI: `VersionControl/update` with `repository_root=/home/jovialem/repositories/apparently-site`,
   then `VersionControlDeployment/create`).
