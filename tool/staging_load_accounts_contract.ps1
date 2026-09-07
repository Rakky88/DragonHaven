Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$tokens = $null
$parseErrors = $null
$sourcePath = Join-Path $PSScriptRoot 'staging_load_accounts.ps1'
$ast = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'The account wrapper does not parse.' }
# Load only the two pure transport/cleanup helpers. Never execute setup or use
# real credentials. The stub below intercepts every possible HTTP request.
$definitions = $ast.FindAll({ param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -in @('Invoke-AdminRequest', 'Remove-RunAccounts')
}, $true)
foreach ($definition in $definitions) { Invoke-Expression $definition.Extent.Text }
$baseUrl = 'https://synthetic.invalid'
$adminHeaders = @{ apikey = 'fake-test-key' }
$runId = '11111111111111111111111111111111'
$script:requests = [System.Collections.Generic.List[object]]::new()
$script:malformed = $false
function Invoke-RestMethod {
    param($Method, $Uri, $Headers, $ContentType, $TimeoutSec, $Body)
    if (-not $Uri -or -not $Headers -or $TimeoutSec -ne 30) { throw 'Missing transport arguments.' }
    $script:requests.Add(@{ Method = $Method; Uri = $Uri; Body = $Body })
    if ($Method -eq 'Get') {
        $address = if ($script:malformed) { 'unrelated@synthetic.invalid' } else { "load-$runId-1@dragonhaven-load.invalid" }
        return @{ users = @(
            [pscustomobject]@{ id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'; email = $address;
                app_metadata = [pscustomobject]@{ dragonhaven_load_run = $runId } },
            [pscustomobject]@{ id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'; email = 'keeper@synthetic.invalid';
                app_metadata = [pscustomobject]@{} }
        ) }
    }
    return @{}
}
$null = Invoke-AdminRequest Post 'users' @{ email_confirm = $true }
$created = $script:requests[0]
if ($created.Uri -ne "$baseUrl/auth/v1/admin/users" -or
    -not ($created.Body | ConvertFrom-Json).email_confirm) { throw 'Create transport changed.' }
$script:requests.Clear()
if ((Remove-RunAccounts) -ne 1) { throw 'Expected exactly one synthetic deletion.' }
$deleted = @($script:requests | Where-Object Method -eq 'Delete')
if ($deleted.Count -ne 1 -or $deleted[0].Uri -ne "$baseUrl/auth/v1/admin/users/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa") {
    throw 'Cleanup touched an unrelated account.'
}
$script:malformed = $true
$script:requests.Clear()
$refused = $false
try { Remove-RunAccounts | Out-Null } catch { $refused = $true }
if (-not $refused -or @($script:requests | Where-Object Method -eq 'Delete').Count -ne 0) {
    throw 'A mismatched synthetic identity must stop cleanup before deletion.'
}
'Synthetic setup/cleanup transport contract passed; no network or real credentials used.'
