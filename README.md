# teams-link-fixer

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

## Setup

### 1. Azure App Registration

Run the included script to create it automatically:

```powershell
.\scripts\Register-App.ps1
```

Or create it manually in the [Azure Portal](https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade):

- Supported account types: **Accounts in any organizational directory (Multitenant)**
- Platform: **Single-page application (SPA)**
- Redirect URI: `https://meetfix.opsora.io` (and `http://localhost:5500` for local dev)
- API permissions (delegated): `Calendars.ReadWrite`, `OnlineMeetings.ReadWrite`, `User.Read`

### 2. Configure the app

Copy `config.example.js` to `config.js` and fill in your client ID:

```bash
cp config.example.js config.js
```

`config.js` is in `.gitignore` and will not be committed.

### 3. Deploy to Vercel

1. Push this repo to GitHub.
2. Import it at [vercel.com](https://vercel.com) - no build step needed.
3. In Vercel project settings → Domains, add `meetfix.opsora.io`.
4. In your DNS, add a `CNAME`: `meetfix` → `cname.vercel-dns.com`.
5. Vercel will provision the SSL certificate automatically.

### 4. Run locally

```bash
python3 -m http.server 5500
```

Then open `http://localhost:5500`. Make sure `redirectUri` in `config.js` matches.

## Files

| File | Purpose |
|---|---|
| `index.html` | The complete SPA - HTML, CSS, and JavaScript in one file |
| `config.js` | Azure App Registration settings (**not committed**) |
| `config.example.js` | Template - copy to `config.js` and fill in values |
| `vercel.json` | Vercel routing config |
| `scripts/Register-App.ps1` | PowerShell script to create the Azure App Registration |

## Security

- **No backend.** Runs entirely in the browser. No data goes anywhere except Microsoft login and Graph API endpoints.
- **PKCE auth.** No client secret.
- **Session storage only.** Tokens are cleared when the tab closes.
- **No persistence.** Meeting data is in memory only, discarded on refresh.

## License

Internal tool - not licensed for distribution.


## The Problem

After a cross-tenant migration, calendar events are copied to the new mailbox but Teams meeting links still point to the old tenant. The organizer can't start these meetings and attendees join an orphaned session.

## What This Tool Does

1. Signs in to **both** the old and new tenant via popup login.
2. Loads future meetings (where you are the organizer) from both tenants into two independent, selectable lists.
3. Lets you **cancel** selected meetings in the old tenant — so external attendees receive a proper cancellation from your original email address.
4. **Silently deletes and recreates** selected meetings in the new tenant with fresh Teams links — attendees get a new invitation from your new address without a confusing cancellation first.

## Prerequisites

- A modern browser (Edge, Chrome, Firefox, Safari).
- An **Azure App Registration** (see below).
- A local web server to serve the files (Live Server, Python, Node, etc.).

## Azure App Registration

1. Go to [Azure Portal → App registrations](https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade).
2. Click **New registration**.
3. Name: `Teams Meeting Migration Portal` (or any name you like).
4. Supported account types: **Accounts in any organizational directory (Multitenant)**.
5. Redirect URI:
   - Platform: **Single-page application (SPA)**
   - URI: `http://localhost:5500`
6. Click **Register**.
7. Copy the **Application (client) ID** — you'll need it for `config.js`.
8. Go to **API permissions → Add a permission → Microsoft Graph → Delegated permissions** and add:
   - `Calendars.ReadWrite`
   - `OnlineMeetings.ReadWrite`
   - `User.Read`
9. Click **Grant admin consent** (or have a tenant admin do it). If admin consent is not possible, users will be prompted to consent individually on first login.
10. No client secret is needed — this app uses PKCE (Proof Key for Code Exchange).

## Configuration

Edit `config.js` and fill in your values:

```js
const CONFIG = {
    clientId: 'YOUR-APPLICATION-CLIENT-ID',  // from step 7 above
    authority: 'https://login.microsoftonline.com/common',
    redirectUri: 'http://localhost:5500',
    graphScopes: ['Calendars.ReadWrite', 'OnlineMeetings.ReadWrite', 'User.Read'],
    oldTenantDomain: 'old-company.com',       // used to detect old Teams links
    cancellationMessage: 'This meeting has been migrated to a new organizer. Please check your inbox for an updated invitation.'
};
```

| Key | Description |
|---|---|
| `clientId` | The Application (client) ID from your Azure App Registration. |
| `authority` | Leave as `common` for multi-tenant. Can be tenant-specific if needed. |
| `redirectUri` | Must match the SPA redirect URI registered in Azure. |
| `graphScopes` | Required Graph permissions. Do not remove any. |
| `oldTenantDomain` | The domain of the old tenant (e.g. `contoso.com`). Used to flag meetings with old Teams links. |
| `cancellationMessage` | Not used in the current implementation but reserved for future use. |

## Running the App

Serve the files from a local web server on **port 5500** (must match `redirectUri`).

### Option A — Python

```bash
cd TeamsMigrationApp-PublicClient
python3 -m http.server 5500
```

### Option B — Node.js (npx)

```bash
cd TeamsMigrationApp-PublicClient
npx serve -l 5500
```

### Option C — VS Code Live Server

1. Install the **Live Server** extension.
2. Set the port to `5500` in settings (`liveServer.settings.port`).
3. Right-click `index.html` → **Open with Live Server**.

Then open **http://localhost:5500** in your browser.

## Usage

1. **Sign in to Old Tenant** — Click the button and authenticate with your old tenant credentials.
2. **Sign in to New Tenant** — Click the button and authenticate with your new tenant credentials.
3. **Load Meetings** — Fetches future meetings (where you are the organizer) from both tenants.
4. **Review** — Two side-by-side panels show your meetings. Use checkboxes to select/deselect individual meetings. Badges indicate:
   - 🔁 **Series** — recurring meeting
   - ⚠️ **Old Link** — contains a Teams link pointing to the old tenant
   - 📹 **Teams** — has a working Teams link
5. **Migrate Selected Meetings** — Cancels selected old-tenant meetings and recreates selected new-tenant meetings with fresh Teams links.
6. **Cancel All Future in Old Tenant** — A separate action that cancels every future meeting you organise in the old tenant, regardless of selection. Useful for a complete cleanup.

After migration, click **Download Report** to save a JSON log of all actions.

## Testing Tips

- Start with a **test user** who has only a few meetings.
- Verify that external attendees receive the cancellation email from the old address and a new invitation from the new address.
- Check that the recreated meeting has a working Teams link by opening it in the Teams client.
- For recurring meetings, confirm that the entire series was recreated (not just a single occurrence).

## Security Notes

- **No backend.** This app runs entirely in the browser. No data is sent to any server other than Microsoft's login and Graph API endpoints.
- **PKCE authentication.** No client secret is stored or transmitted.
- **Session storage.** Tokens are stored in `sessionStorage` and cleared when the browser tab is closed.
- **No data persistence.** Meeting data is held in memory only and discarded on page refresh.

## URL Parameters

All parameters are optional. They pre-fill the app and persist across the MSAL redirect.

| Parameter | Description | Example |
|---|---|---|
| `source` | Display name for the old tenant | `?source=Contoso` |
| `destination` | Display name for the new tenant | `?destination=Fabrikam` |
| `mode` | Show only one section: `source` or `destination` | `?mode=destination` |

Example: `https://your-app.vercel.app/?source=Contoso&destination=Fabrikam&mode=destination`

## Deploying to Vercel

1. Push the folder as a GitHub repository. Make sure `config.js` is **not** committed (it is in `.gitignore`).
2. Go to [vercel.com](https://vercel.com) and import the repository.
3. No build step is needed — Vercel serves the static files directly.
4. After the first deploy, copy the Vercel URL and add it as a redirect URI in your Azure App Registration (SPA platform), then update `redirectUri` in `config.js`.

For a **public** repository: do not commit `config.js`. Instead, use a Vercel build command to generate it from an environment variable.
For a **private** repository: committing `config.js` directly is fine.

## Files

| File | Purpose |
|---|---|
| `index.html` | The complete SPA - HTML, CSS, and JavaScript in one file |
| `config.js` | Your Azure App Registration settings (**not committed**) |
| `config.example.js` | Template - copy to `config.js` and fill in your values |
| `vercel.json` | Vercel routing config (serves `index.html` for all routes) |
| `scripts/Register-App.ps1` | PowerShell script to create the Azure App Registration |

## License

Internal tool — not licensed for distribution.
