# Teams Meeting Fix

A browser-based tool that fixes broken Teams meeting links after a **tenant-to-tenant mailbox migration** (e.g. BitTitan). Hosted at [meetfix.opsora.io](https://meetfix.opsora.io).

After a cross-tenant migration, calendar events are copied to the new mailbox but the Teams links still point to the old tenant. The organizer can't start those meetings and attendees land in an orphaned session. This tool cancels the broken meetings in the old tenant and recreates them with fresh links in the new tenant.

## How it works

1. **Old tenant** - sign in with your old account, select meetings to cancel. Attendees receive a cancellation from your old address.
2. **New tenant** - sign in with your new account, select meetings to recreate. Attendees receive a new invitation from your new address.

## URL parameters

All parameters are optional. They pre-fill labels and persist across the MSAL redirect.

| Parameter | Description | Example |
|---|---|---|
| `source` | Display name for the old tenant | `?source=Contoso` |
| `destination` | Display name for the new tenant | `?destination=Fabrikam` |
| `mode` | Show only one section: `source` or `destination` | `?mode=destination` |

Example: `https://meetfix.opsora.io/?source=Contoso&destination=Fabrikam&mode=destination`

> **Part of the [Opsora Toolbox](https://opsora.io/toolbox)** — a collection of free, battle-tested tools and baselines for Microsoft 365 migrations and governance.

## Option A: Use the hosted version (recommended)

The tool is hosted at **[meetfix.opsora.io](https://meetfix.opsora.io)** — no setup, no deployment, just grant access and go.

### Grant app access in your tenant

When a user signs in for the first time, Entra ID shows a consent prompt for the required permissions. If your tenant requires **admin consent**, a Global Administrator or Application Administrator needs to approve the app once:

1. Open the [Enterprise Applications](https://entra.microsoft.com/#view/Microsoft_AAD_IAM/StartboardApplicationsMenuBlade/~/AppAppsPreview) blade in the Entra admin center.
2. Search for **Teams Meeting Fix** (or the app's client ID) after the first sign-in attempt.
3. Go to **Permissions** → **Grant admin consent**.

The app requests these **delegated** permissions:

| Permission | Why |
|---|---|
| `Calendars.ReadWrite` | Read and cancel/recreate calendar events |
| `OnlineMeetings.ReadWrite` | Create new Teams meetings with fresh join links |
| `User.Read` | Display the signed-in user's name and email |

> **No data leaves the browser.** The app talks directly to Microsoft Graph via MSAL.js with PKCE — there is no backend, no data storage, and tokens are cleared when the tab closes.

That's it — your users can now open [meetfix.opsora.io](https://meetfix.opsora.io) and start fixing meetings.

---

## Option B: Self-hosted deployment

If you prefer to host the tool under your own domain, follow the steps below.

### 1. Create an Entra App Registration

Run the included script to create it automatically:

```powershell
.\scripts\Register-App.ps1
```

Or create it manually in the [Entra admin center](https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade):

- Supported account types: **Accounts in any organizational directory (Multitenant)**
- Platform: **Single-page application (SPA)**
- Redirect URIs: your hosting URL (e.g. `https://meetfix.example.com`) and `http://localhost:5500` (for local dev)
- API permissions (delegated): `Calendars.ReadWrite`, `OnlineMeetings.ReadWrite`, `User.Read`

### 2. Configure the app

Copy `config.example.js` to `config.js` and update it with your client ID and redirect URI:

```js
const CONFIG = {
    clientId: "YOUR-APPLICATION-CLIENT-ID",
    authority: "https://login.microsoftonline.com/common",
    redirectUri: "https://meetfix.example.com",
    graphScopes: ["Calendars.ReadWrite", "OnlineMeetings.ReadWrite", "User.Read"],
    defaultCancellationMessage: "This meeting has been migrated. You will receive a new invitation shortly."
};
```

For local development, change `redirectUri` to `http://localhost:5500`.

### 3. Deploy

The app is a static site (HTML + JS, no build step). Deploy it to any static hosting provider:

**Vercel:**
1. Push this repo to GitHub.
2. Import it at [vercel.com](https://vercel.com) — select **Other** as the framework preset, leave all build fields empty.
3. Add your custom domain in Vercel project settings.
4. In your DNS, add a `CNAME` pointing to `cname.vercel-dns.com`.

**Any static host:** Upload `index.html`, `config.js`, and `vercel.json` (optional, for headers) to your web server.

### 4. Run locally

```bash
cd teams-link-fixer
python3 -m http.server 5500
```

Then open `http://localhost:5500`. Make sure `redirectUri` in `config.js` is set to `http://localhost:5500`.

## Files

| File | Purpose |
|---|---|
| `index.html` | The complete app - HTML, CSS, and JavaScript in one file |
| `config.js` | Your Entra app settings - update `clientId` and `redirectUri` |
| `config.example.js` | Reference template showing all config keys |
| `vercel.json` | Vercel routing and security headers config |
| `scripts/Register-App.ps1` | PowerShell script to create the Entra App Registration |

## Security

- **No backend.** Runs entirely in the browser. No data goes anywhere except Microsoft login and Graph API endpoints.
- **PKCE auth.** No client secret.
- **Session storage only.** Tokens are cleared when the tab closes.
- **No persistence.** Meeting data is in memory only, discarded on refresh.

## License

[MIT](LICENSE) — Copyright (c) 2026 Opsora LLC
