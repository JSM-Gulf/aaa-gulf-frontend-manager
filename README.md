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
| `gulfbusinesssupport` | [`gulfbusinesssupport`](https://github.com/JSM-Gulf/gulfbusinesssupport) | `gulfbusinesssupport_frontend2` | `3lw4e-riaaa-aaaag-azafa-cai` | `www.gulfbusinesssupport.com` (since 2026-09-05), `gulfbusinesssupport.com` (since 2026-09-05) — see [Domain](#gulfbusinesssupport-domain) |
| `gulfbusinesssupport` (old Dubai site) | same repo, `master` before the Erbil redesign | `gulfbusinesssupport_frontend` | `lgydc-kqaaa-aaaag-ay6uq-cai` | none any more — idle, to be recycled |

Per site, in this repo: `dist-<slug>/` (production source, git-ignored),
`<slug>-custom-domain-files/` (`.ic-assets.json5`, `.well-known/ic-domains`),
one canister in `dfx.json` and `canister_ids.json`, three `<slug>:*` scripts.
`gulfbusinesssupport` is the exception with two canisters, explained next.

### Why gulfbusinesssupport has two canisters

`gulfbusinesssupport_frontend` (`lgydc-…`, the original Dubai site) has a
single controller, `feau5-…` — the dfx identity that lives on the machine
in Kochcice. The identity used here (`DevTest`, `i5tik-…`) is not a
controller, so from this machine nothing can be deployed to `lgydc-…`.
Rather than wait for access, the Erbil redesign (2026-09-05) went to a
second canister, `gulfbusinesssupport_frontend2` (`3lw4e-…`), created from
the DevTest cycles ledger with both `i5tik-…` and `feau5-…` as controllers.
`npm run gulfbusinesssupport:deploy:prod` targets `frontend2`; both
hostnames were repointed to it on 2026-09-05, so `lgydc-…` now serves
nothing and only waits to be recycled.

**This is temporary.** The plan is to recycle one of the two canisters and
return to a single one — either add `i5tik-…` as a controller of `lgydc-…`
from Kochcice and deploy there, or move both hostnames to `3lw4e-…`. Either
way the unused canister gets deleted (`dfx canister delete … --ic` refunds
its remaining cycles to the caller; the 0.5 TC creation fee is gone).

Creating a canister when the cycles wallet is empty: do not let
`dfx deploy` create it (it goes through the wallet and fails with
"out of cycles"); create it from the cycles ledger first —
`dfx canister create <canister> --ic --no-wallet --with-cycles 600000000000
--next-to <existing canister id>` — then top it up
(`dfx cycles top-up <canister> 400000000000 --ic`): the network burns
0.5 TC of the deposit as the creation fee, so 0.6 TC leaves ~0.1 TC.

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
| `npm run prod:deploy` | production deploy of that site, custom-domain files included (for gulfbusinesssupport: to `gulfbusinesssupport_frontend2`) |

Both Gulf sites default to `frontend3`, so they overwrite each other there:
the last test deploy wins. That is fine for a look, not for showing two sites
at once — use `-- frontend2` for the second one, after checking what it holds
(`~/motoko-crafting-table/frontend2/index.html`).

Run **here**, after the web project's `npm run copy`:

| Command | Result |
|---|---|
| `npm run deploy:test -- <slot>` | copy `./dist` into `~/motoko-crafting-table/<slot>` and deploy that slot |
| `npm run gulf-enterprise-solutions:deploy:prod` | production deploy of gulf-enterprise-solutions |
| `npm run gulfbusinesssupport:deploy:prod` | production deploy of gulfbusinesssupport to `gulfbusinesssupport_frontend2` (`3lw4e-…`) |
| `npm run dfx:cycles-balance` | cycles of the current `dfx` identity (a new canister needs some) |

## gulfbusinesssupport domain

- **Registrar:** GoDaddy — the domain `gulfbusinesssupport.com` was bought
  by Yasameen. GoDaddy only holds the registration; its nameservers were
  switched to Cloudflare on 2026-08-17 (the apex needs CNAME flattening,
  which GoDaddy does not do).
- **DNS:** Cloudflare, account `michal.s.limeacademy@gmail.com`,
  nameservers `clark.ns.cloudflare.com` and `jewel.ns.cloudflare.com`.
  Every record is **DNS only** (grey cloud — the IC boundary nodes must
  see the real hostname), TTL Auto.
- **Canister side:** `gulfbusinesssupport-custom-domain-files/.well-known/ic-domains`
  lists both hostnames; `<slug>:deploy:prod` copies it into the deployed
  site, so both canisters carry it.

DNS records (state of 2026-09-05):

| Type | Name | Content | Role |
|---|---|---|---|
| CNAME | `gulfbusinesssupport.com` (apex, flattened by Cloudflare) | `gulfbusinesssupport.com.icp1.io` | traffic for the apex goes to the IC boundary nodes |
| CNAME | `www` | `www.gulfbusinesssupport.com.icp1.io` | the same for `www` |
| CNAME | `_acme-challenge` | `_acme-challenge.gulfbusinesssupport.com.icp2.io` | lets the IC obtain the TLS certificate for the apex |
| CNAME | `_acme-challenge.www` | `_acme-challenge.www.gulfbusinesssupport.com.icp2.io` | the same for `www` |
| TXT | `_canister-id` | `3lw4e-riaaa-aaaag-azafa-cai` | which canister serves the apex (was `lgydc-…` until 2026-09-05) |
| TXT | `_canister-id.www` | `3lw4e-riaaa-aaaag-azafa-cai` | which canister serves `www` (was `lgydc-…` until 2026-09-05) |
| TXT | `_dmarc` | `v=DMARC1; p=quarantine; adkim=r; aspf=r; rua=mailto:dmarc_rua@onsecureserver.net;` | mail policy left over from GoDaddy; no mail is set up for the domain |

Registration status with the IC (`https://icp0.io/custom-domains/v1/<hostname>`):

- `www.gulfbusinesssupport.com` — registered 2026-08-17 on `lgydc-…`,
  repointed to `3lw4e-…` on 2026-09-05 with one `PATCH` (accepted at
  once, live after ~10 minutes, no downtime, same certificate).
- `gulfbusinesssupport.com` — the first registration (2026-08-17/18)
  **failed on the IC side**: an orphaned ACME challenge TXT at
  `_acme-challenge.gulfbusinesssupport.com.icp2.io` made every `POST`
  answer "existing DNS TXT challenge record" although `/validate` passed,
  and two clean-up cycles did not clear it. On 2026-09-05, with the TXT
  naming `3lw4e-…`, a fresh `POST` was accepted without that error and the
  apex was `registered` three minutes later (certificate valid to
  2026-12-04; the IC renews it). Both hostnames now serve `3lw4e-…`.

The API (`https://icp.net/custom-domains/v1/<hostname>`; `icp0.io` answers
too) is keyed by the hostname, there is no registration id, and the write
calls are run by hand (`curl -sL -X … "<url>"`, no body):

| Call | When |
|---|---|
| `GET …/<host>/validate` | checks the DNS records and `.well-known/ic-domains` only |
| `POST …/<host>` | first registration of a hostname (status `not_found`) |
| `GET …/<host>` | status: `registering` → `registered` (certificate takes minutes), `failed`, `not_found` |
| `PATCH …/<host>` | **repoint** a registered hostname to the canister now in its `_canister-id` TXT — change the TXT first, wait ~5 min, then PATCH |
| `DELETE …/<host>` | remove the registration; refused while the `_canister-id` TXT still exists, so delete the TXT first, wait ~5 min |

Moving a hostname to another canister is therefore: the target canister's
deployed site lists the hostname in `.well-known/ic-domains` (both Gulf
canisters do) → change the `_canister-id.<host>` TXT in Cloudflare → wait
~5 min → `PATCH`. `DELETE` + `POST` is only the fallback for a registration
that is `failed`. The old `POST https://icp0.io/registrations` API is
retired (`canister_id_not_resolved`).

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
   creates the canister on mainnet (costs cycles, through the identity's
   cycles wallet — with an empty wallet create it from the cycles ledger
   first, see above) and adds it to `canister_ids.json` — commit that file.
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
