# MythDusk Balance Lab

Portable source snapshot of the initial simulator, plus a Cursor handoff.
Copy this folder into your MythDusk repo at `tools/balance-lab/`, open the repo
in Cursor, and start with `CURSOR_HANDOFF.md`.

## Run locally

Requires Python 3 for the development server. No npm install is needed to use the app.
From this folder:

```sh
python3 -m http.server 4173 --bind 127.0.0.1 --directory src
```

Open http://127.0.0.1:4173 in your browser. Serve over HTTP; opening index.html
as a file can block its JavaScript module imports.

## Tests

Requires Node.js 20 or newer:

```sh
npm test
```

Optional browser checks (keep the development server running in another terminal):

```sh
npm install --save-dev playwright
npx playwright install chromium
npm run test:ui
```

The model tests and JavaScript syntax checks passed during packaging. The browser
suite is included but was NOT successfully executed in the build environment:
Chromium was unavailable and downloading it timed out. Earlier claims of complete
visual validation were too broad. Run the browser suite locally before trusting UI validation.

## Files

- src/index.html: controls and layout
- src/styles.css: responsive dark UI
- src/model.js: assumptions, formulas, presets, balance signals
- src/app.js: rendering, events, in-memory baseline
- tests/model.test.mjs: model checks
- tests/visual.cjs: optional Playwright browser checks
- CURSOR_HANDOFF.md: limitations and prioritized integration work

The source files preserve the deployed prototype's behavior. The package manifest
only makes module handling and test commands explicit. No hosting configuration,
Git credentials, authentication tokens, or dependencies are included.

This local copy has no account authentication. The server command binds only to
localhost. The deployed Sites copy remains private; do not publish a new copy
without Apoorv's approval.
