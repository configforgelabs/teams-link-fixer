const CONFIG = {
    // Azure App Registration — Application (client) ID
    clientId: "7d767590-09ae-48c4-b1ff-1efc0154963e",

    // Authority — use "common" for multi-tenant
    authority: "https://login.microsoftonline.com/common",

    // Redirect URI — must match what is configured in Azure App Registration
    redirectUri: "https://meetfix.opsora.io",

    // Microsoft Graph delegated scopes
    graphScopes: ["Calendars.ReadWrite", "OnlineMeetings.ReadWrite", "User.Read"],

    // Default cancellation message — users can edit this in the portal
    defaultCancellationMessage: "This meeting has been migrated to our new system. You will receive a new invitation shortly."
};
