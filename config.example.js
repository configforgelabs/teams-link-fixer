const CONFIG = {
    // Azure App Registration - Application (client) ID
    // Get this from: Azure Portal > App registrations > your app > Overview
    clientId: "YOUR-APPLICATION-CLIENT-ID",

    // Leave as "common" for multi-tenant (works across any Microsoft 365 org)
    authority: "https://login.microsoftonline.com/common",

    // Must exactly match the SPA redirect URI registered in Azure
    // Production: "https://meetfix.opsora.io"
    // Local dev:  "http://localhost:5500"
    redirectUri: "https://meetfix.opsora.io",

    // Required Microsoft Graph delegated permissions - do not change
    graphScopes: ["Calendars.ReadWrite", "OnlineMeetings.ReadWrite", "User.Read"],

    // Default cancellation message shown to users (they can edit it before sending)
    defaultCancellationMessage: "This meeting has been migrated to our new system. You will receive a new invitation shortly."
};
