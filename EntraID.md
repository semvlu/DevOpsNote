# EntraID SAML Authn Enabling for Human Admin
1. Create Security Group & add members: **Object ID**
  - Groups -> New group -> Security
2. Create Enterprise Apps: enable SAML authn: **App Federation Metadata Url**
  - Enterprise applications -> New application -> Create your own application: Integrate any other application you don't find in the gallery (Non-gallery)
  - Single sign-on -> SAML -> Basic SAML Configuration: Edit
    - Identifier (Entity ID): `https://example.com/auth/saml`
    - Reply URL (Assertion Consumer Service URL): `https://example.com/auth/saml/callback`
  - Attributes & Claims: Edit -> Add a group claim
    - Security groups
    - Source attribute: Group ID
  - Back to SAML-based Sign-on: SAML Certificates: App Federation Metadata Url
3. Assign Enterprise Apps to Security Group
   - `<Enterprise application>` | User and groups -> Add user/group

