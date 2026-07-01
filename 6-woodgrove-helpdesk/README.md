---

languages:
- dotnet
products:
- microsoft entra
- verified id
description: "A code sample for proving identity with Face Check at a helpdesk, using Entra Verified ID"
urlFragment: "6-woodgrove-helpdesk"
---
# Verified ID Code Sample for Woodgrove Helpdesk

This sample showcases how to identify yourself at a helpdesk by presenting your [VerifiedEmployee](https://learn.microsoft.com/en-us/entra/verified-id/how-to-use-quickstart-verifiedemployee) card.
The helpdesk website requires a Face Check together with the presentation for high assurance that the person is who they claim to be before getting support.
More info about this pattern can be found [here](https://learn.microsoft.com/en-us/entra/verified-id/helpdesk-with-verified-id).

**Note** - it is a demo app and not a real helpdesk portal.

## Deploy to Azure

Complete the [setup](#setup) before deploying to Azure so that you have all the required parameters.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fbillmcilhargey%2Factive-directory-verifiable-credentials-dotnet%2Fmain%2F6-woodgrove-helpdesk%2FARMTemplate%2Ftemplate.json)

You need to enter the following parameters:

1. The app name. This needs to be globally unique as it will be part of your URL, like https://your-app-name.azurewebsites.net/

2. Your DID for your Entra Verified ID authority. After setting up Verified ID, you find your DID [here](https://portal.azure.com/#view/Microsoft_AAD_DecentralizedIdentity/InitialMenuBlade/~/issuerSettingsBlade)

3. App Service plan SKU: choose `F1` (Free), `B1` (Basic), or `S1` (Standard). Default is `B1`.

![Deployment Parameters](ReadmeFiles/DeployToAzure.png)

After the ARM deployment finishes, deploy application content to the app service.

1. In Azure portal, open your App Service.
2. Go to `Deployment Center`.
3. Configure source deployment with:
    - Source: `External Git`
    - Repository: `https://github.com/Azure-Samples/active-directory-verifiable-credentials-dotnet.git`
    - Branch: `main`
    - Build provider: `App Service Build Service`
4. Save and run `Sync`.
5. Verify that deployment logs show success, then browse to your site URL.

If you skip this second step, the web app will be created but no application content will be deployed.

## Using the sample

To use the sample, do the following:

- Open the website in your browser.
- Step 1
    - Either click the step 1 button to go to [MyAccount](https://myaccount.microsoft.com) and issue yourself a VerifiedEmployee credential from your company, or click `I already have my card` to advance to step 2.
- Step 2
    - Scan the QR code with your Microsoft Authenticator
    - Select your VerifiedEmployee card
    - Perform the Face Check on your mobile
    - Share the credential and the liveness result
- Step 3
    - In final step, your email and displayName will show together with your face check score.
    - The web app says "a support person will be with you shortly", but do not wait too long because this is just a sample.

## Using the sample on a mobile phone

Follow the steps above, with the additions.

- Launch the website in your mobile browser.
- When clicking on the `I already have my card`, you will be asked to open the Microsoft Authenticator and you have to accept that.
- After sharing the credential and the Face Check result in the Microsoft Authenticator, manually return to your mobile browser app
- Click `Continue` in the middle section

## Extending the sample with Microsoft Teams

The sample is prepared to send a message to a Microsoft Teams channel using a [webhook](https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/what-are-webhooks-and-connectors). 

**Please note:** this is just a sample to show how this Teams integration idea can be achieved. It is not production-ready code. For production, use server-side logic or options like Azure Logic Apps that can read verification state from the application database and send Teams notifications or REST API updates to external systems.

In order to extend the sample, create an [incoming webhook](https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook?tabs=newteams%2Cdotnet) and update the app's configuration in your Azure AppService's configuration:

| Key | Value |
|------|--------|
| AppSettings__UseTeamsWebhook | "true" |
| AppSettings__TeamsWebhookURL | URL of the incoming webhook |

## Setup

### Entra ID tenant

You need an Entra ID tenant to get this sample to work. You can set up a [free tenant](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-create-new-tenant) unless you don't have one already. 

### Setup Verified ID

[Setup Verified ID](https://learn.microsoft.com/en-us/entra/verified-id/verifiable-credentials-configure-tenant-quick) in your tenant and enable MyAccount. 
You do not need to register an app or create a custom Verified ID credential schema.

### Azure subscription

The sample is intended to be deployed to [Azure App Services](https://learn.microsoft.com/en-us/azure/app-service/) 
and use [Managed Identity](https://learn.microsoft.com/en-us/azure/app-service/overview-managed-identity) for authenticating and acquiring an access token to call Verified ID.
You don't need to do an app registration in Entra ID.

### Configuring Managed Identity

1. Enable Managed Identity for your App Service app at `Settings` > `Identity`.
2. In portal.azure.com, open `Cloud Shell` in Bash mode and run the following script to grant your app's managed identity permission to call Verified ID.

```bash
RG="<YOUR RESOURCE GROUP>"
WEBAPP_NAME="<NAME OF YOUR AZURE WEBAPP>"

# Do not change these values.
VERIFIED_ID_APP_ID="3db474b9-6a0c-4840-96ac-1fceb342124f"
VERIFIED_ID_ROLE_VALUE="VerifiableCredential.Create.PresentRequest"

# Managed identity service principal object ID.
MI_SP_OBJECT_ID=$(az webapp identity show -g "$RG" -n "$WEBAPP_NAME" --query principalId -o tsv)

# Service principal object ID for the Verified ID resource app.
RESOURCE_SP_OBJECT_ID=$(az ad sp list --filter "appId eq '$VERIFIED_ID_APP_ID'" --query "[0].id" -o tsv)

# App role ID to assign.
APP_ROLE_ID=$(az ad sp show --id "$VERIFIED_ID_APP_ID" --query "appRoles[?value=='$VERIFIED_ID_ROLE_VALUE' && contains(allowedMemberTypes, 'Application')].id | [0]" -o tsv)

# Grant app role assignment to the managed identity.
az rest --method POST \
    --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$MI_SP_OBJECT_ID/appRoleAssignments" \
    --headers "Content-Type=application/json" \
    --body "{\"principalId\":\"$MI_SP_OBJECT_ID\",\"resourceId\":\"$RESOURCE_SP_OBJECT_ID\",\"appRoleId\":\"$APP_ROLE_ID\"}"
```

You need an account with enough directory permissions to grant app role assignments (for example, Cloud Application Administrator or higher).

#### Can this be fully automated in ARM?

Not in a plain resource group ARM deployment. This permission assignment is an Entra ID (tenant-level Microsoft Graph) operation, while the template deploys Azure resources in a resource group.

It can be automated as an additional step (for example, pipeline/CLI script after deployment, or a deployment script with the right Graph permissions), but it is intentionally kept as a post-deployment step in this sample.

## Troubleshooting

### Deploy to Azure completed but site is empty

If deployment reports a failure for `Microsoft.Web/sites/sourcecontrols`, or the site is empty, the App Service resource was likely created without code content.

Resolve it by opening `Deployment Center` and configuring source deployment using the same repository and branch listed in [Deploy to Azure](#deploy-to-azure), then run `Sync`.

If you are deploying this sample to Azure App Services, then you can view app logging information in the `Log stream` if you do the following:

- Go to Development Tools, then Extensions
- Select `+ Add` and add `ASP.NET Core Logging Integration` extension
- Go to `Log stream` and set `Log level` drop down filter to `verbose`

The Log stream console will now contain traces from the deployed app. Do not forget to disable the extension when troubleshooting is done.

