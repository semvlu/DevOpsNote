# EntraID SAML Authn Enabling for Human Admin
## Create Security Group & add members: *Object ID*
1. Groups -> New group -> Security

## Create Enterprise Apps: enable SAML authn: *App Federation Metadata Url*
1. Enterprise applications -> New application -> Create your own application: Integrate any other application you don't find in the gallery (Non-gallery)
2. Single sign-on -> SAML -> Basic SAML Configuration: Edit
  - Identifier (Entity ID): `https://example.com/auth/saml`
  - Reply URL (Assertion Consumer Service URL): `https://example.com/auth/saml/callback`
3. Attributes & Claims: Edit -> Add a group claim
  - [x] Security groups
  - Source attribute: Group ID
7. Back to SAML-based Sign-on -> SAML Certificates: App Federation Metadata Url
## Assign Enterprise Apps to Security Group
`<Enterprise application>` | User and groups -> Add user/group
