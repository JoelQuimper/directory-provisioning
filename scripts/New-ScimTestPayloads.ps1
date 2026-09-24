[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')]
    [string] $Domain,

    [string] $OutputDirectory = (Join-Path $PSScriptRoot '..\samples\scim')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$coreSchema = 'urn:ietf:params:scim:schemas:core:2.0:User'
$enterpriseSchema = 'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User'
$bulkRequestSchema = 'urn:ietf:params:scim:api:messages:2.0:BulkRequest'
$normalizedDomain = $Domain.ToLowerInvariant()

function New-ScimUser {
    param(
        [Parameter(Mandatory)]
        [int] $Number,

        [bool] $Active = $true,

        [string] $Title = 'Test User',

        [string] $Department = 'POC'
    )

    $externalId = 'SCIM-TEST-{0:D4}' -f $Number
    $alias = 'scim.test{0:D2}' -f $Number

    $user = [ordered]@{
        schemas            = @($coreSchema, $enterpriseSchema)
        externalId         = $externalId
        userName           = "$alias@$normalizedDomain"
        name               = [ordered]@{
            givenName  = 'Scim'
            familyName = "Test$Number"
        }
        displayName        = "Scim Test$Number"
        active             = $Active
        userType           = 'Employee'
        title              = $Title
        preferredLanguage  = 'fr-CA'
    }

    $user[$enterpriseSchema] = [ordered]@{
        employeeNumber = $externalId
        organization   = 'Provisioning POC'
        division       = 'SCIM Evaluation'
        department     = $Department
    }

    return $user
}

function New-ScimOperation {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $User
    )

    return [ordered]@{
        method = 'POST'
        bulkId = [guid]::NewGuid().ToString()
        path   = '/Users'
        data   = $User
    }
}

function Write-ScimPayload {
    param(
        [Parameter(Mandatory)]
        [string] $FileName,

        [Parameter(Mandatory)]
        [object[]] $Operations
    )

    $payload = [ordered]@{
        schemas      = @($bulkRequestSchema)
        Operations   = $Operations
        failOnErrors = $null
    }

    $path = Join-Path $resolvedOutputDirectory $FileName
    $json = $payload | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($path, $json, [System.Text.UTF8Encoding]::new($false))

    [pscustomobject]@{
        Path           = $path
        OperationCount = $Operations.Count
    }
}

$resolvedOutputDirectory =
    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDirectory)

if (-not (Test-Path -LiteralPath $resolvedOutputDirectory)) {
    New-Item -ItemType Directory -Path $resolvedOutputDirectory | Out-Null
}

$load1 = 1..10 | ForEach-Object {
    New-ScimOperation -User (New-ScimUser -Number $_)
}

$load2 = @(
    New-ScimOperation -User (New-ScimUser -Number 2 -Title 'Test User - Updated Load 2' -Department 'Operations')
    New-ScimOperation -User (New-ScimUser -Number 3 -Title 'Test User - Updated Load 2' -Department 'Technology')
    New-ScimOperation -User (New-ScimUser -Number 11)
    New-ScimOperation -User (New-ScimUser -Number 12)
    New-ScimOperation -User (New-ScimUser -Number 1 -Active $false)
)

$load3 = @(
    4..8 | ForEach-Object {
        New-ScimOperation -User (
            New-ScimUser -Number $_ -Title 'Test User - Updated Load 3' -Department 'Batch 3'
        )
    }
    13..17 | ForEach-Object {
        New-ScimOperation -User (New-ScimUser -Number $_)
    }
    9..10 | ForEach-Object {
        New-ScimOperation -User (New-ScimUser -Number $_ -Active $false)
    }
)

@(
    Write-ScimPayload -FileName '01-create-10-users.json' -Operations $load1
    Write-ScimPayload -FileName '02-update-2-create-2-disable-1.json' -Operations $load2
    Write-ScimPayload -FileName '03-update-5-create-5-disable-2.json' -Operations $load3
)
