<#
.SYNOPSIS
    Creates the Entra App Registration for Teams Link Fixer (meetfix.opsora.io).

.DESCRIPTION
    Registers a multi-tenant SPA application in Entra ID with the required
    Microsoft Graph delegated permissions (Calendars.ReadWrite, OnlineMeetings.ReadWrite, User.Read).
    Outputs the values to paste into config.js.

.NOTES
    Requires: Microsoft.Graph PowerShell module
    Run once per the tenant where the app registration should live.
#>

#Requires -Modules Microsoft.Graph.Applications

param(
    [string]$AppName = "Teams Link Fixer",
    [string]$RedirectUri = "https://meetfix.opsora.io"
)

# -------------------------------------------------------------------
#  Connect to Microsoft Graph
# -------------------------------------------------------------------
Write-Host "`n🔐 Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "Application.ReadWrite.All" -NoWelcome

$context = Get-MgContext
if (-not $context) {
    Write-Error "Failed to connect to Microsoft Graph. Aborting."
    return
}
Write-Host "   Connected as: $($context.Account) | Tenant: $($context.TenantId)" -ForegroundColor Green

# -------------------------------------------------------------------
#  Check if app already exists
# -------------------------------------------------------------------
$existingApp = Get-MgApplication -Filter "displayName eq '$AppName'" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($existingApp) {
    Write-Warning "An app registration named '$AppName' already exists (AppId: $($existingApp.AppId))."
    $answer = Read-Host "Do you want to use the existing registration? (Y/N)"
    if ($answer -notin @('Y', 'y')) {
        Write-Host "Aborted." -ForegroundColor Yellow
        return
    }
    $app = $existingApp
    Write-Host "   Using existing app registration." -ForegroundColor Green
}
else {
    # ---------------------------------------------------------------
    #  Microsoft Graph well-known IDs for delegated permissions
    # ---------------------------------------------------------------
    #  Resource App ID for Microsoft Graph
    $graphResourceId = "00000003-0000-0000-c000-000000000000"

    #  Delegated permission IDs (stable across all tenants)
    $permissions = @(
        @{ Id = "ef54d2bf-783f-4e0f-bcea-3ef109e3f9c0"; Type = "Scope" }  # Calendars.ReadWrite
        @{ Id = "a65f4166-1ca6-449a-9346-1b5d13a47060"; Type = "Scope" }  # OnlineMeetings.ReadWrite
        @{ Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"; Type = "Scope" }  # User.Read
    )

    $requiredResourceAccess = @(
        @{
            ResourceAppId  = $graphResourceId
            ResourceAccess = $permissions
        }
    )

    # ---------------------------------------------------------------
    #  Create the App Registration
    # ---------------------------------------------------------------
    Write-Host "`n📝 Creating app registration '$AppName'..." -ForegroundColor Cyan

    $appBody = @{
        DisplayName            = $AppName
        SignInAudience         = "AzureADMultipleOrgs"
        Spa                    = @{ RedirectUris = @($RedirectUri) }
        RequiredResourceAccess = $requiredResourceAccess
    }

    $app = New-MgApplication -BodyParameter $appBody

    if (-not $app) {
        Write-Error "Failed to create app registration."
        return
    }

    Write-Host "   ✅ App registration created successfully." -ForegroundColor Green

    # ---------------------------------------------------------------
    #  Create a Service Principal (required for consent)
    # ---------------------------------------------------------------
    Write-Host "   Creating service principal..." -ForegroundColor Cyan
    New-MgServicePrincipal -AppId $app.AppId -ErrorAction SilentlyContinue | Out-Null
    Write-Host "   ✅ Service principal created." -ForegroundColor Green
}

# -------------------------------------------------------------------
#  Output — values for config.js
# -------------------------------------------------------------------
$tenantDomain = ($context.Account -split '@')[1]

Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              Teams Link Fixer — Config.js values           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  App Name       : $($app.DisplayName)"
Write-Host "  Application ID : $($app.AppId)" -ForegroundColor Yellow
Write-Host "  Object ID      : $($app.Id)"
Write-Host "  Tenant ID      : $($context.TenantId)"
Write-Host "  Redirect URI   : $RedirectUri"
Write-Host "  Sign-in        : Multi-tenant (AzureADMultipleOrgs)"
Write-Host "  Permissions    : Calendars.ReadWrite, OnlineMeetings.ReadWrite, User.Read (Delegated)"
Write-Host ""
Write-Host "──────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Paste the following into config.js:" -ForegroundColor Cyan
Write-Host "──────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  clientId: `"$($app.AppId)`"" -ForegroundColor Green
Write-Host "  redirectUri: `"$RedirectUri`"" -ForegroundColor Green
Write-Host ""
Write-Host "──────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
Write-Host "⚠️  Next steps:" -ForegroundColor Yellow
Write-Host "  1. Grant admin consent for the API permissions in the Azure Portal:"
Write-Host "     https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/$($app.AppId)" -ForegroundColor DarkCyan
Write-Host "  2. Paste the clientId above into config.js."
Write-Host "  3. Ensure '$RedirectUri' is listed as a redirect URI in the app registration."
Write-Host ""
