# Managing dependencies
$MODULE_INVOKATION_TAG = "RepoHelperModule_Mock"

function Set-InvokeCommandMock{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)][string]$Alias,
        [Parameter(Mandatory,Position=1)][string]$Command
    )

    InvokeHelper\Set-InvokeCommandAlias -Alias $Alias -Command $Command -Tag $MODULE_INVOKATION_TAG
}

function Reset-InvokeCommandMock{
    [CmdletBinding()]
    param()

    InvokeHelper\Reset-InvokeCommandAlias -Tag $MODULE_INVOKATION_TAG
}

function Set-InvokeCommandMockFile{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)][string]$Command,
        [Parameter(Mandatory,Position=1)][string]$MockFileName
    )

    $LOCAL = $PSScriptRoot
    $root = $LOCAL | Split-Path -Parent
    $testData = $root | Join-Path -ChildPath 'public' -AdditionalChildPath 'testData'
    
    $mockFile = $testData | Join-Path -ChildPath $MockFileName
    
    Set-InvokeCommandMock -Alias $Command -Command "Get-Content -Path $(($mockFile | Get-Item).FullName)"
}

function Set-InvokeCommandMockJsonNull{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)][string]$Command
    )

    Set-InvokeCommandMock -Alias $Command -Command "echo null"
}

function Set-InvokeCommandMockJsonEmpty{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)][string]$Command
    )

    Set-InvokeCommandMock -Alias $Command -Command "echo []"
}