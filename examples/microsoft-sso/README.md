# Microsoft Entra-ID Example

Nebuly supports several authentication methods. This example shows how to use [Microsoft Entra-ID](https://developers.google.com/identity/protocols/oauth2) to authenticate users.

## Prerequisites

Before you begin, ensure you have:
- A Microsoft Entra ID tenant
-	Access to the Azure Portal
-	Permission to create App registrations

---

## Step 1: Create a Microsoft Entra ID Application

1. **Log in to the Azure Portal**:  
   https://portal.azure.com

2. Navigate to **Microsoft Entra ID** → **App registrations**.

3. Click **New registration**.

4. Configure the application:
   - **Name**: e.g. `Nebuly Platform`
   - **Supported account types**:
     - Choose **Accounts in this organizational directory only** (recommended)
   - **Redirect URI**:
     - Platform: **Web**
     - URI:
       ```
       https://<platform_domain>/backend/auth/oauth/microsoft/callback
       ```

   Where `<platform_domain>` is the same value provided to the Terraform variable `platform_domain`.

5. Click **Register**.

6. Take note of:
   - **Application (client) ID**
   - **Directory (tenant) ID**

---

## Step 2: Create a Client Secret

1. In the App registration, navigate to **Certificates & secrets**.

2. Under **Client secrets**, click **New client secret**.

3. Provide:
   - Description (e.g. `Nebuly OAuth Secret`)
   - Expiration (according to your security policy)

4. Click **Add** and **copy the secret value immediately**.

> ⚠️ You will not be able to retrieve the secret again.

---

## Step 3: Configure API Permissions

1. Go to **API permissions**.

2. Click **Add a permission** → **Microsoft Graph** → **Delegated permissions**.

3. Add the following permissions:
   - `openid`
   - `profile`
   - `email`
   - `GroupMember.Read.All`

4. Click **Grant admin consent** for your organization.

> This permission is required for Nebuly to read group memberships.

---

## Step 4: Create Entra ID Groups for Nebuly roles

Nebuly uses **Microsoft Entra ID groups** to determine user roles.

1. In **Microsoft Entra ID**, go to **Groups**.

2. Create or identify groups corresponding to Nebuly roles:
   - Administrators (e.g. `nebuly-admins`)
   - Members (e.g. `nebuly-members`)
   - Viewers (e.g. `nebuly-viewers`)

3. Add users to the appropriate groups.

---

## Step 5: Map Entra ID Groups to Nebuly roles

Nebuly maps Entra ID groups to roles using **group object IDs**.

To find a group’s object ID:
1. Open the group in the Azure Portal
2. Copy the **Object ID**

---

## Terraform configuration

To enable Microsoft Entra ID authentication in Nebuly, provide the following Terraform variables:

```hcl
microsoft_sso = {
  client_id     = "<application-client-id>"
  client_secret = "<client-secret>"
  tenant_id     = "<directory-tenant-id>"
  role_mapping  = {
    viewer = "<entra-group-object-id>"
    member = "<entra-group-object-id>"
    admin  = "<entra-group-object-id>"
  }
}