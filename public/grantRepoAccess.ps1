
Set-InvokeCommandAlias -Alias 'GrantUserAccess'  -Command 'gh api repos/{owner}/{repo}/collaborators/{user} -X PUT -f permission="{role}"'
Set-InvokeCommandAlias -Alias 'RemoveUserAccess'  -Command 'gh api repos/{owner}/{repo}/collaborators/{user} -X DELETE'

<#
.SYNOPSIS
    Grant a user access to a repository.
#>
function Grant-RepoAccess{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)] [string]$owner,
        [Parameter(Mandatory)] [string]$repo,
        [Parameter(Mandatory)] [string]$user,
        [Parameter(Mandatory)]
        [ValidateSet("read", "triage", "write", "maintain", "admin")] [string]$role,
        [Parameter()][switch]$force
    )

    if(!$force){

        $permission = Get-RepoAccess -Owner $owner -Repo $repo -User $user
        
        if($permission -eq $role){
            return @{ $user = $permission }
        }
    }

    $param = @{
        owner = $owner
        repo = $repo
        user = $user
        role = $role
    }

    $result = Invoke-MyCommandJson -Command GrantUserAccess -Parameters $param

    if($result.message -eq "Not Found"){
        $ret = @{ $user = $result.message }
    } else {
        $ret = @{ $result.invitee.login = $result.permissions }
    }

    return $ret

} Export-ModuleMember -Function Grant-RepoAccess

<#
.SYNOPSIS
    Remove a user access to a repository.
#>
function Remove-RepoAccess{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string]$owner,
        [Parameter(Mandatory)] [string]$repo,
        [Parameter(Mandatory)] [string]$user
    )

    $param = @{
        owner = $owner
        repo = $repo
        user = $user
    }

    $ret = $null

    if ($PSCmdlet.ShouldProcess("User on RepoAccess List", "RemoveUserAccess")) {

        $result1 = Invoke-MyCommandJson -Command RemoveUserAccess -Parameters $param

        $result2 = Remove-RepoAccessInvitation -Owner $owner -Repo $repo -User $user
        
        $ret = $result1 + $result2
    }

    return $ret

} Export-ModuleMember -Function Remove-RepoAccess

<#
.SYNOPSIS
    Synchronize the access of a list of users to a repository.
#>
function Sync-RepoAccess{
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)] [string]$FilePath,
        [Parameter(Mandatory)] [string]$owner,
        [Parameter(Mandatory)] [string]$repo,
        [Parameter(Mandatory)]
        [ValidateSet("read", "triage", "write", "maintain", "admin")] [string]$role
    )

    $ret = @{}

    $users = Get-Content -Path $FilePath

    $permissions = Get-RepoAccessAll -Owner $owner -Repo $repo
    $invitations = Get-RepoAccessInvitations -Owner $owner -Repo $repo

    # Update or add existing users
    foreach($user in $users){

        # Already invited to this role
        if($invitations.$user -eq $role){
            $ret.$user = "?"
            continue
        }
        
        # Already granted to this role
        if($permissions.$user -eq $role){
            $ret.$user = "="
            continue
        }

        # Check if it has granted a different role
        if($permissions.Keys.Contains($user)){
            $status = "+ ($($permissions.$user))"
        } else {
            $status = "+"
        }

        # Force to avoid the call to check if the access is already set
        if ($PSCmdlet.ShouldProcess("Target", "Operation")) {
            $result = Grant-RepoAccess -Owner $owner -Repo $repo -User $user -Role $role -Force
            
            if($result.$user -eq $role.ToLower()){
                $ret.$user = $status
            } else {
                $ret.$user = $status
            }
        } else {
            $ret.$user = $status
        }
    
    }

    # Delete non existing users

    $usersToDelete = $Permissions.Keys | Where-Object { $users -notcontains $_ }

    # Just remove the users that where set to $role
    $usersToDelete = $usersToDelete | Where-Object { $Permissions.$_ -eq $role}

    foreach($userToDelete in $usersToDelete){
        
        if ($PSCmdlet.ShouldProcess("Target", "Operation")) {
            $result = Remove-RepoAccess -Owner $owner -Repo $repo -User $userToDelete

            if($null -eq $result){
                $ret.$userToDelete += "-"
            } else {
                $ret.$userToDelete += 'X -'
            }
        } else {
            $ret.$userToDelete += "-"
        }
    }

        return $ret

} Export-ModuleMember -Function Sync-RepoAccess