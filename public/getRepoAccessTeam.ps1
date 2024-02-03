
Set-MyInvokeCommandAlias -Alias "GetUser" -Command "gh api users/{login}"

<#
.SYNOPSIS
    Get the list of users with access in descriptive format
#>

function Get-RepoAccessTeam{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()] [string]$Owner,
        [Parameter()] [string]$Repo,
        [Parameter()] [switch]$NoHeaders
    )

    # Resolve repo name from parameters or environment
    $owner,$repo = Get-Environment $owner $repo
    
    # Error if parameters not set. No need to check repo too.
    if([string]::IsNullOrEmpty($Owner)){
        "Owner and Repo parameters are required" | Write-Error
        return $null
    }
    $ret = @()

    $headerLine =  "| Photo                      | Name   | Access   | Email   | Handle | Company    |"
    $headerLines = "|----------------------------|--------|----------|---------|--------|------------|" 
    # $templateLine ="| ![@{login}]({avatar}?s=40) | {name} | {access} | {email} | {login}| {company}  |"
    $templateLine ="| ![@{login}]({avatar}) | {name} | {access} | {email} | {login}| {company}  |"
    
    
    # HEADER
    if($NoHeaders){
        $ret += $headerLine
        $ret += $headerLines
    }
    
    # Get access Control
    $accessList = Get-RepoAccess -Owner $owner -Repo $repo 
    
    Foreach($login in $accessList.Keys){
        
        $user = Get-RepoUser -Login $login
        $avatar = 'https://avatars.githubusercontent.com/{login}?s=40' -replace '{login}',$login

        $userline = $templateLine
        $userline = $userline -replace '{login}',   $user.login
        $userline = $userline -replace '{avatar}',  $avatar
        $userline = $userline -replace '{name}',    $user.name
        $userline = $userline -replace '{access}',  $accessList.$login
        $userline = $userline -replace '{email}',   $user.email
        $userline = $userline -replace '{company}', $user.company

        $ret+= $userline
    }

    return $ret
} Export-ModuleMember -Function Get-RepoAccessTeam

function Get-RepoUser{
    [CmdletBinding()]
    param (
        [Parameter(Position=0,ValueFromPipeline)][string]$Login
    )

    process{
        
        $parameters = @{
            login = $Login
        }

        $result = Invoke-MyCommandJson -Command GetUser -Parameters $parameters

        $ret = [PSCustomObject]@{
            login = $result.login
            name = $result.name
            avatar_url = $result.avatar_url
            company = $result.company
            email = $result.email
            location = $result.location
            html_url = $result.html_url
            created_at = $result.created_at
        }

        return $ret
    }
} Export-ModuleMember -Function Get-RepoUser

