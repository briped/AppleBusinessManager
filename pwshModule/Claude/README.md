# Claude Sparring
Unchecked code from Claude.  
&mdash; and latest [Claude Code Review](#claude-code-review) below.

### What is this?
I want to implement dynamic rate limiting and caching, and needed some examples and inspiration to get started.

---

## Claude Code Review
> Reviewed: 10 March 2026 @ 00:31

### `AppleBusinessManager.psm1`

Looks solid overall. One thing to note: the dot-sourcing approach using `[System.Management.Automation.ScriptBlock]::Create()` with all files concatenated is clever for avoiding scope issues, but it means a syntax error in any single file will prevent the entire module from loading, and the error message won't point to the offending file by name. Not necessarily a bug, but worth being aware of when troubleshooting.

---

### Private Functions

**`ConvertFrom-Base64Url.ps1`**
The padding logic has an edge case: when `$Value.Length % 4 -eq 0`, `$Padding` will be `4`, and the `if ($Padding -ne 4)` guard correctly skips adding padding — that's fine. However, if the input is already standard Base64 (with `=` padding), the replace of `-` and `_` is harmless but the function would still work. Minor: no `end {}` block, which is inconsistent with `ConvertTo-Base64Url`.

**`ConvertTo-Base64Url.ps1`**
The commented-out line `#$Bytes = if ($Value -is [byte[]]) ...` is dead code and should be cleaned up. The `$String` parameter in the help block says `.PARAMETER Value` but the actual parameter is named `$String` — the help is mismatched. Also no `end {}` block.

**`New-JwsCompactSerialization.ps1`**
Good security hygiene with the `end {}` block zeroing out sensitive variables. One issue: `Remove-Variable` is called on `$JwsPayload` and `$SignedJwsPayload`, but these are already reassigned to `$null` just before — the `Remove-Variable` is redundant but harmless. The `$JwsCompactSerialization` variable is not cleared in `end {}`, though it's not sensitive as it's the public output.

**`New-Jwt.ps1`**
The help block says `.OUTPUTS System.String — An unsigned JWT` but the function actually returns a fully *signed* JWS compact serialization. The description and example output in the help are misleading — they say "unsigned JWT" and reference `New-JsonWebSignature` as a separate step, when the signing already happens inside this function via `New-JwsCompactSerialization`. This should be corrected.

The `$Now` variable uses `[System.DateTimeOffset]::Now` which is correct for Unix timestamps, but there's no `nbf` (not before) claim — Apple doesn't require it, so that's fine.

**`Request-AccessToken.ps1`**
The query parameters are being sent as a query string on a POST request. For `application/x-www-form-urlencoded`, they should be in the request body, not the URL. While Apple may accept it either way, it's technically incorrect per the OAuth 2.0 spec (RFC 6749) and could break with stricter servers. The `Content-Type: application/x-www-form-urlencoded` header is set but no body is actually being sent.

The `try/catch` that just rethrows with `throw $_` adds no value and can be removed.

The TODO note in `.NOTES` about using `$Script:Config` directly is valid — passing all config values as parameters when the module already holds them in `$Script:Config` is redundant.

---

### Public Functions

**`Invoke-ApiRequest.ps1`**
This is the original version (pre our edits from earlier in this conversation), with all the bugs we already identified: inverted token expiry check, `$Body` not passed, `$Global:DebugApi` left in, empty help block.

**`New-ApiConfig.ps1`**
Well structured with good validation. One issue: `$TeamId` is optional, but `Request-AccessToken` passes `$ClientId` as both `Issuer` and `Subject` — so if a `$TeamId` is provided, it's stored in `$Script:Config.TeamId` but never actually used anywhere in the token request flow. It's a dead config value unless `Request-AccessToken` is updated to prefer it.

**`Get-Device.ps1`**
Good use of `[System.Web.HttpUtility]::ParseQueryString()` for query string building. However, `$QueryString` is built in `begin {}` but `$UriBuilder` is rebuilt on every pipeline iteration in `process {}` — if the function is ever called with pipeline input (it currently doesn't accept it), the `$QueryString` state could cause issues. The `$Fields` query key `fields[orgDevices]` will be URL-encoded by `ParseQueryString`, which is correct.

The pagination loop in the `All` parameter set uses `$Response.links.next` directly as the `$Uri` for the next call — this is correct assuming Apple returns absolute URLs in `links.next`, which they do per JSON:API spec.

**`Get-DeviceActivity.ps1`**, **`Get-DeviceAssignedServerDetails.ps1`**, **`Get-DeviceAssignedServerId.ps1`**, **`Get-Server.ps1`**
These all ignore the `$Fields` parameter when building the URI — it's defined but never added to the query string. Compare with `Get-Device.ps1` which correctly does this.

`Get-DeviceAssignedServerDetails.ps1` has `DefaultParameterSetName = 'Limit'` declared but no `Limit` parameter set defined — leftover from a copy-paste.

**`Get-DeviceAppleCare.ps1`**
The `All` parameter set throws `not implemented yet` — fine as a placeholder, but the `$Limit` parameter is accepted and never passed to the API request either.

**`Get-ServerAssignedDevice.ps1`**
`$Limit` is defined with `[ValidateRange(1, 1000)]` but never used in the request. The `$All` parameter set will always throw since it's not implemented, but there's no `[CmdletBinding(DefaultParameterSetName = ...)]` so PowerShell has no default set — both `$Limit` and `$All` belong to named sets, meaning neither is the default.

**`Set-DeviceServer.ps1`**
Function is named `Set-DeviceMDMServer` inside the file but the file is named `Set-DeviceServer.ps1` — this is a mismatch that will cause `Export-ModuleMember` in the `.psm1` to export `Set-DeviceServer` (the filename without extension) but the actual function is `Set-DeviceMDMServer`. The function will load but won't be exported under the expected name. The function immediately throws "not implemented yet" regardless, so it's moot for now, but needs fixing before it's actually implemented.

---

### Summary of Most Critical Issues

| Issue | File | Severity |
|---|---|---|
| Token expiry check inverted | `Invoke-ApiRequest.ps1` | 🔴 Bug |
| `$Body` never sent | `Invoke-ApiRequest.ps1` | 🔴 Bug |
| OAuth params in URL not body on POST | `Request-AccessToken.ps1` | 🟠 Spec violation |
| Function name ≠ filename | `Set-DeviceServer.ps1` | 🟠 Export broken |
| `$TeamId` stored but never used | `New-ApiConfig.ps1` | 🟠 Silent data loss |
| `$Fields` ignored in several functions | `Get-DeviceActivity`, `Get-DeviceAssignedServerDetails`, `Get-Server`, `Get-ServerAssignedDevice` | 🟠 Silent data loss |
| `$Limit` accepted but never sent | `Get-DeviceAppleCare`, `Get-ServerAssignedDevice` | 🟠 Silent data loss |
| Misleading help — "unsigned JWT" | `New-Jwt.ps1` | 🟡 Docs |
| Dead code / stale comment | `ConvertTo-Base64Url.ps1` | 🟡 Cleanup |
| `DefaultParameterSetName` with no matching set | `Get-DeviceAssignedServerDetails.ps1` | 🟡 Leftover |