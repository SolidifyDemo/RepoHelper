function RepoHelperTest_GetRepoAccessTeam_Success{

    $owner = "solidifycustomers"; $repo = "bit21"

    Enable-InvokeCommandAlias -Tag *
    Reset-InvokeCommandAlias -Tag RepoHelperModule_Mock

    # $mockFile = $PSScriptRoot | Join-Path -ChildPath 'testData' -AdditionalChildPath 'getAccessAllSuccess.json'
    # Set-InvokeCommandMock -Alias "gh api repos/$owner/$repo/collaborators --paginate" -Command "Get-Content -Path $(($mockFile | Get-Item).FullName)"

    Set-InvokeCommandMockFile -MockFileName "getAccessAllSuccess.json" -Command "gh api repos/$owner/$repo/collaborators --paginate"
    Set-InvokeCommandMockFile -MockFileName "getuserSuccess_raulgeukk.json" -Command "gh api users/raulgeukk"
    Set-InvokeCommandMockFile -MockFileName "getuserSuccess_rulasg.json" -Command "gh api users/rulasg"
    Set-InvokeCommandMockFile -MockFileName "getuserSuccess_magnustim.json" -Command "gh api users/MagnusTim"

# Name                           Value
# ----                           -----
# MagnusTim                      admin
# raulgeukk                      write
# rulasg                         admin

    $result = Get-RepoAccessTeam -Owner $owner -Repo $repo -NoHeaders

    Assert-Contains -Presented $result -Expected '| Photo                      | Name   | Access   | Email   | Handle | Company    |'
    Assert-Contains -Presented $result -Expected '|----------------------------|--------|----------|---------|--------|------------|'
    Assert-Contains -Presented $result -Expected '| ![@MagnusTim](https://avatars.githubusercontent.com/MagnusTim?s=40) | Joe Smith | admin | MagnusTim@github.com | MagnusTim| Contoso  |'
    Assert-Contains -Presented $result -Expected '| ![@raulgeukk](https://avatars.githubusercontent.com/raulgeukk?s=40) | Joe Smith | write | raulgeukk@github.com | raulgeukk| Contoso  |'
    Assert-Contains -Presented $result -Expected '| ![@rulasg](https://avatars.githubusercontent.com/rulasg?s=40) | Joe Smith | admin | rulasg@github.com | rulasg| Contoso  |'
}