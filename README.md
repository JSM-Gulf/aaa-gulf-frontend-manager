# aaa-gulf-frontend-manager

Deploy manager for the Gulf websites: one repo with the production deploy
config of every Gulf site, plus a one-command test deploy through
[`motoko-crafting-table`](https://github.com/JSM-Tooling/motoko-crafting-table).
Built from the
[`ic-frontend-canister-manager`](https://github.com/JSM-Tooling/ic-frontend-canister-manager)
template — the general model, the script reference and the custom-domain
guide (`DOMAIN_SETUP.md`) live there. This file is what is specific to Gulf.

The web projects know nothing about canisters. Each one builds, copies its
`dist` into this repo's `./dist`, and the scripts here route it: to a shared
crafting-table slot for a test, or to the site's own production canister.

## Sites

| Slug | Web repo | Canister | Canister id | Domains |
|---|---|---|---|---|
| `gulf-enterprise-solutions` | [`gulf-enterprise-solutions-hub`](https://github.com/JSM-Gulf/gulf-enterprise-solutions-hub) | `gulf_frontend` | `x3wmq-niaaa-aaaag-axh4q-cai` | `www.gulf-enterprise-solutions.com` |
| `gulfbusinesssupport` | [`gulfbusinesssupport`](https://github.com/JSM-Gulf/gulfbusinesssupport) | `gulfbusinesssupport_frontend` | `lgydc-kqaaa-aaaag-ay6uq-cai` | `gulfbusinesssupport.com`, `www.gulfbusinesssupport.com` |

Per site, in this repo: `dist-<slug>/` (production source, git-ignored),
`<slug>-custom-domain-files/` (`.ic-assets.json5`, `.well-known/ic-domains`),
one canister in `dfx.json` and `canister_ids.json`, three `<slug>:*` scripts.

Layout on disk — this repo and the web repos are siblings:

```
~/workspace-gulf/
├── aaa-gulf-frontend-manager/      ← this repo
├── gulf-enterprise-solutions-hub/
└── gulfbusinesssupport/
```

## Everyday commands

Run in the **web project**:

| Command | Result |
|---|---|
| `npm run craft:deploy` | test deploy to crafting-table slot `frontend3` → https://bxvts-pqaaa-aaaas-qgy3a-cai.icp0.io |
| `npm run craft:deploy -- frontend2` | the same into another slot (`frontend1`/`frontend2` usually hold Sultana builds — check first) |
| `npm run prod:deploy` | production deploy of that site, custom-domain files included |

Both Gulf sites default to `frontend3`, so they overwrite each other there:
the last test deploy wins. That is fine for a look, not for showing two sites
at once — use `-- frontend2` for the second one, after checking what it holds
(`~/motoko-crafting-table/frontend2/index.html`).

Run **here**, after the web project's `npm run copy`:

| Command | Result |
|---|---|
| `npm run deploy:test -- <slot>` | copy `./dist` into `~/motoko-crafting-table/<slot>` and deploy that slot |
| `npm run gulf-enterprise-solutions:deploy:prod` | production deploy of gulf-enterprise-solutions |
| `npm run gulfbusinesssupport:deploy:prod` | production deploy of gulfbusinesssupport |
| `npm run dfx:cycles-balance` | cycles of the current `dfx` identity (a new canister needs some) |

## Adding a Gulf site

Say the new site's slug is `gulf-new`, its canister `gulf_new_frontend`.

1. **Web repo** `~/workspace-gulf/gulf-new`, building into `dist/`, with:

   ```json
   "copy": "rm -rf ../aaa-gulf-frontend-manager/dist && cp -r dist ../aaa-gulf-frontend-manager/dist",
   "craft:deploy": "f() { S=${1:-frontend3}; npm run build && npm run copy && cd ../aaa-gulf-frontend-manager && npm run deploy:test -- $S; }; f",
   "prod:deploy": "npm run build && npm run copy && cd ../aaa-gulf-frontend-manager && npm run gulf-new:deploy:prod"
   ```

2. **Here:**
   * `gulf-new-custom-domain-files/` — copy `gulfbusinesssupport-custom-domain-files/`,
     put the new domain(s) in `.well-known/ic-domains`;
   * `dfx.json` — a `gulf_new_frontend` entry with `entrypoint`
     `dist-gulf-new/index.html` and `source` `["dist-gulf-new"]`;
   * `package.json`:

     ```json
     "gulf-new:task:copy-dist": "rm -rf dist-gulf-new && cp -r dist dist-gulf-new",
     "gulf-new:task:copy-files": "cp -r gulf-new-custom-domain-files/. dist-gulf-new/",
     "gulf-new:deploy:prod": "npm run gulf-new:task:copy-dist && npm run gulf-new:task:copy-files && dfx deploy gulf_new_frontend --ic"
     ```

   * `.gitignore` — add `dist-gulf-new`;
   * commit.
3. **Test:** `npm run craft:deploy` in the web repo, open the slot URL above.
4. **Production:** `npm run prod:deploy` in the web repo. The first run
   creates the canister on mainnet (costs cycles) and adds it to
   `canister_ids.json` — commit that file.
5. **Domain:** follow `DOMAIN_SETUP.md` in the template repo with
   `gulf-new-custom-domain-files/` and the new canister id.
6. Add the site to the table at the top of this file.

## Scripts in this repo

| Script | What it does |
|---|---|
| `deploy:test -- <slot>` | `scripts/copy-to-crafting-table.sh <slot>` (replaces `~/motoko-crafting-table/<slot>` with `./dist`; refuses a slot that is not an `assets` canister in the table's `dfx.json`), then `npm run deploy:<slot>` in the table. |
| `task:copy-to-crafting-table -- <slot>` | the copy step alone. |
| `<slug>:task:copy-dist` | `./dist` → `dist-<slug>` (old content removed). |
| `<slug>:task:copy-files` | `<slug>-custom-domain-files/` → `dist-<slug>/`. |
| `<slug>:deploy:prod` | copy-dist, copy-files, `dfx deploy <canister> --ic`. |
| `dfx:icp-wallet-address`, `dfx:icp-balance`, `dfx:cycles-balance`, `dfx:convert-icp-to-cycles -- <amount>` | ledger and cycles helpers. |
