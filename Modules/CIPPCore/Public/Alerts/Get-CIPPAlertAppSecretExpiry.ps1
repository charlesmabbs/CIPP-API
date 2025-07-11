function Get-CIPPAlertAppSecretExpiry {
    <#
    .FUNCTIONALITY
        Entrypoint
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false)]
        [Alias('input')]
        $InputValue,
        $TenantFilter
    )

    try {
        Write-Host "Checking app expire for $($TenantFilter)"
        $appList = New-GraphGetRequest -uri "https://graph.microsoft.com/beta/applications?`$select=appId,displayName,passwordCredentials" -tenantid $TenantFilter
    } catch {
        return
    }

    $AlertData = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($App in $applist) {
        Write-Host "checking $($App.displayName)"
        if ($App.passwordCredentials) {
            foreach ($Credential in $App.passwordCredentials) {
                if ($Credential.endDateTime -lt (Get-Date).AddDays(30) -and $Credential.endDateTime -gt (Get-Date).AddDays(-7)) {
                    Write-Host ("Application '{0}' has secrets expiring on {1}" -f $App.displayName, $Credential.endDateTime)

                    $Message = [PSCustomObject]@{
                        AppName    = $App.displayName
                        AppId      = $App.appId
                        Expires    = $Credential.endDateTime
                        Tenant     = $TenantFilter
                    }
                    $AlertData.Add($Message)
                }
            }
        }
    }
    Write-AlertTrace -cmdletName $MyInvocation.MyCommand -tenantFilter $TenantFilter -data $AlertData
}
