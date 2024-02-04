<#
.SYNOPSIS
    Run tests
.DESCRIPTION
    Run the unit test of the actual module
.NOTES
    Using TestingHelper this script will search for a Test module and run the tests
    This script will be referenced from launch.json to run the tests on VSCode
.LINK
    https://raw.githubusercontent.com/rulasg/StagingModule/main/test.ps1
.EXAMPLE
    > ./test.ps1
#>

[CmdletBinding()]
param (
    [Parameter()][switch]$ShowTestErrors
)

function Set-TestName{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Scope='Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function')]
    [Alias("st")]
    param (
        [Parameter(Position=0,ValueFromPipeline)][string]$TestName
    )

    process{
        $global:TestName = $TestName
    }
}

function Get-TestName{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function')]
    [Alias("gt")]
    param (
    )

    process{
        $global:TestName
    }
}

function Clear-TestName{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Scope='Function')]
    [Alias("ct")]
    param (
    )

    $global:TestName = $null
}

function Get-RequiredVersionToLoad {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Name,
        [Parameter()][string]$Version
    )
    
    # 1. No Version
    # 2. Partial Version. Two numbers
    # 3. Full Version . 3 or 4 numbers

    $modulelist = Get-Module -Name $Name -ListAvailable

    # module not found - return null
    if($null -eq $modulelist){return $null}

    # No version - returnfirst
    if([string]::IsNullOrWhiteSpace($Version)){
        return $modulelist[0]
    }

    # Asking for a particular version
    $vv = New-Object -TypeName Version -ArgumentList $Version

    # Found the particular version
    $available = $modulelist | Where-Object {$_.Version -eq $vv}
    if($available){
        return $available
    }

    # Find compatible version
    $available = $modulelist | Where-Object {$_.Version.CompareTo($vv) -eq 1}

    return $available[0]
}

function Import-RequiredModule{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Scope='Function')]
    param (
        [Parameter(ParameterSetName = "HT", ValueFromPipeline)][hashtable]$RequiredModule,
        [Parameter(ParameterSetName = "RM",Position = 0)][string]$ModuleName,
        [Parameter(ParameterSetName = "RM")][string]$ModuleVersion,
        [Parameter(ParameterSetName = "HT")]
        [Parameter(ParameterSetName = "RM")]
        [switch]$AllowPrerelease,
        [Parameter(ParameterSetName = "HT")]
        [Parameter(ParameterSetName = "RM")]
        [switch]$PassThru
    )

    process{
        # Powershell module manifest does not allow versions with prerelease tags on them. 
        # Powershell modle manifest does not allow to add a arbitrary field to specify prerelease versions.
        # Valid value (ModuleName, ModuleVersion, RequiredVersion, GUID)
        # There is no way to specify a prerelease required module.

        if($RequiredModule){
            $ModuleName = $RequiredModule.ModuleName
            $ModuleVersion = [string]::IsNullOrWhiteSpace($RequiredModule.RequiredVersion) ? $RequiredModule.ModuleVersion : $RequiredModule.RequiredVersion
        }

        "Importing module Name[{0}] Version[{1}] AllowPrerelease[{2}]" -f $ModuleName, $ModuleVersion, $AllowPrerelease | Write-Host -ForegroundColor DarkGray

        # Following semVer we can manually specidy a taged version to specify that is prerelease
        # Extract the semVer from it and set AllowPrerelease to true
        if ($ModuleVersion) {
            $V = $ModuleVersion.Split('-')
            $semVer = $V[0]
            $AllowPrerelease = ($AllowPrerelease -or ($null -ne $V[1]))
        }
        $module = Get-RequiredVersionToLoad -Name $ModuleName -Version $ModuleVersion
        
        if ($null -eq $module) {
            "Installing module Name[{0}] Version[{1}] AllowPrerelease[{2}]" -f $ModuleName, $ModuleVersion, $AllowPrerelease | Write-Host -ForegroundColor DarkGray
            $installed = Install-Module -Name $ModuleName -Force -AllowPrerelease:$AllowPrerelease -passThru -RequiredVersion:$ModuleVersion
            $module = Import-Module -Name $installed.Name -RequiredVersion ($installed.Version.Split('-')[0]) -Force -PassThru
        } else {
            $module = Import-Module -Name $module.Name -RequiredVersion $module.Version -PassThru -ErrorAction SilentlyContinue 
        }

        "Imported module Name[{0}] Version[{1}] PreRelease[{2}]" -f $module.Name, $module.Version, $module.privatedata.psdata.prerelease | Write-Host -ForegroundColor DarkGray

        if ($PassThru) {
            $module
        }
    }
}

<#
. SYNOPSIS
    Extracts the required modules from the module manifest
#>
function Get-RequiredModule{
    [CmdletBinding()]
    [OutputType([hashtable[]])]
    param()

    # Required Modules
    $localPath = $PSScriptRoot
    $manifest = $localPath | Join-Path -child "*.psd1" |  Get-Item | Import-PowerShellDataFile
    $requiredModule = $null -eq $manifest.RequiredModules ? @() : $manifest.RequiredModules

    # Convert to hashtable
    $ret = @()
    $requiredModule | ForEach-Object{
        $ret += $_ -is [string] ? @{ ModuleName = $_ } : $_
    }

    return $ret
}

# Install and load TestingHelper
# Import-RequiredModule -Name TestingHelper -AllowPrerelease
Import-RequiredModule "TestingHelper" -AllowPrerelease

# Install and Load Module dependencies
Get-RequiredModule | Import-RequiredModule -AllowPrerelease 

if($TestName){
    Invoke-TestingHelper -TestName $TestName -ShowTestErrors:$ShowTestErrors
} else {
    Invoke-TestingHelper -ShowTestErrors:$ShowTestErrors
}