<!-- BPC:STATUS-BEGIN -->

 <!-- BPC:OVERVIEW-BEGIN -->
## Live & status

- **Live site:** https://www.beeplanetconnection.org  
- **Blog JSON:** https://www.beeplanetconnection.org/blog/posts.json  
- **RSS:** https://www.beeplanetconnection.org/blog/rss.xml  
- **Build:** [![Pages Deploy](https://github.com/itshenryrhodes/legendary-octo-garbanzo/actions/workflows/pages.yml/badge.svg)](https://github.com/itshenryrhodes/legendary-octo-garbanzo/actions/workflows/pages.yml)


---

# 2) (Optional) CI button to produce a downloadable snapshot ZIP

You built `scripts/make-snapshot.ps1` and ran it locally, but there’s no “one-click” CI job. If you want that, add this workflow:

```yaml
# .github/workflows/snapshot.yml
name: Make snapshot (manual)

on:
  workflow_dispatch:

permissions:
  contents: read

jobs:
  snapshot:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4

      - name: Use Node
        uses: actions/setup-node@v4
        with:
          node-version: "20"

      - name: Build site (same order as Pages)
        run: |
          node scripts/expand-includes.js
          if (Test-Path scripts/inject-meta.js) { node scripts/inject-meta.js }
          if (Test-Path scripts/build-search.js) { node scripts/build-search.js }
          if (Test-Path scripts/build-blog.js)   { node scripts/build-blog.js }
          if (Test-Path scripts/inject-gtm.js)   { node scripts/inject-gtm.js }

      - name: Make snapshot (zip + manifest)
        shell: pwsh
        run: pwsh -File scripts/make-snapshot.ps1

      - name: Upload snapshot zip
        uses: actions/upload-artifact@v4
        with:
          name: site-snapshot
          path: |
            site-snapshot-*.zip
            snapshots/*/manifest.json
            SNAPSHOT-*.md

### Local dev
Static only. Open files under `/site`. To preview search/build behaviours, run:
```bash
node scripts/expand-includes.js
node scripts/build-search.js
node scripts/build-blog.js
# (optional) inject GTM + meta if you’re inspecting the built HTML locally
node scripts/inject-meta.js
node scripts/inject-gtm.js

[![Pages Deploy](https://github.com/itshenryrhodes/legendary-octo-garbanzo/actions/workflows/pages.yml/badge.svg)](https://github.com/itshenryrhodes/legendary-octo-garbanzo/actions/workflows/pages.yml)
[![Latest Release](https://img.shields.io/github/v/release/itshenryrhodes/=tag&sort=semver)](https://github.com/itshenryrhodes/legendary-octo-garbanzo/releases/latest)

**Live site:** https://www.beeplanetconnection.org

## Releases
- **Latest:** [v0.2.0-wiki-search](https://github.com/itshenryrhodes/legendary-octo-garbanzo/releases/tag/v0.2.0-wiki-search)
- **Previous:** [v0.1.0-site-bootstrap](https://github.com/itshenryrhodes/legendary-octo-garbanzo/releases/tag/v0.1.0-site-bootstrap)

## Changelog (summary)
- **v0.2.0** — Wiki search (client-side) + CI index build.
- **v0.1.0** — Initial Pages deploy, HTTPS, 404/robots/sitemap, directory.js.
<!-- BPC:STATUS-END -->

# Bee Planet Connection (Static Site)
Public static site for Bee Planet Connection. Deployed via GitHub Pages (Actions).

