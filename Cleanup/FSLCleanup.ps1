<#
    This is to cleaup the FSlogix container store.

    These will be considered for cleaup:

        Non-existing users in the AD.
        Disabled users.
        Last logon is over 90 days.

#>

# Tune this variables to your needs

$FSLogixPath = "\\atmedfs11\CloudDigital\FSLogix\Profiles"                              # FSLogix user containers share path.
[string[]]$ExcludeFolders = @('FSLRedirections', 'FSLRules')                            # Excluded directories. We dont want Redirection and rules folder touched.
$DaysInactive = 90                                                                      # Allowed number of innactive days for a user/user container.
$DeleteDisabled = 1                                                                     # If set to 1 the containers of disabled users will be deleted.
$DeleteNotExisting = 1                                                                  # If set to 1 the containers of non existing users will be delated.
$DeleteInactive = 1                                                                     # If set to 1 the containers of Users with a last logon longer the the $DaysInactive will be deleted.
$OnlyDeleteODFC = 1                                                                     # When this is 1 only the office cache container will be deleted and not the profile container.
$FlipFlopEnabled = 1                                                                    # If flipflop naming is enabled in FSLogix GPO set this to 1. Its 2024, enable name flip flops.
$ShowTable = 1                                                                          # Show table at the end of the script.
$ReadOnlyRun = 1                                                                        # Read only, nothing will be deleted, script will also output user names and what will be deleted.

# Script Start
$PotentialSpaceReclamation = 0
$SpaceReclaimed = 0
$SpaceDisabled = 0
$SpaceNotExisting = 0
$SpaceInactive = 0
$Counter = 0
$UsersTable = @()

Write-Host ""
#check if a readonly mode
If ($ReadOnlyRun -eq 1)
    {
        Write-Host "!! Read only run mode Active, nothing will be deleted !!" -ForegroundColor Black -BackgroundColor DarkGreen
    }
Else
    {
        Write-Host "!! Warning This is not Read only Mode, containers will be deleted !!" -ForegroundColor Yellow -BackgroundColor DarkRed
        Write-Host "You can switch to read only mode by toggling ReadOnlyRun to 1 in the scripy"
        Write-Host ""
        Write-Host -nonewline "Continue? (Y/N) "
        $Response = Read-Host
        If ($Response -ne "Y")
            {
                EXIT                                                                                                                                    #Check response Explicitly for a Y. Else will discontinue for safety.
            }
    }

Write-Host ""

$PathItems = Get-ChildItem -Path "$($FSLogixPath)" -Directory -Recurse -Exclude $ExcludeFolders                                                         #Get items in the share, exclude folders.

Foreach ($PathItem in $PathItems)
    {
        If ($FlipFlopEnabled -eq 1)
            {
                $UserName = $PathItem.Name.Substring(0, $PathItem.Name.IndexOf('_S-1-5'))                                                               #If flipflop enabled get only the user name and exlude %sid%
            }

        If ($FlipFlopEnabled -eq 0)
            {
                $UserName = $PathItem.Name.Substring($PathItem.Name.IndexOf('_') + 1)                                                                   #if flipflop not enabled find the '_' and get the username.
            }

        $Counter ++
                                                                                                                                                        #increment the counter to get the containers count.
        Try
            {
                $Information = Get-ADUser -Identity $UserName -Properties sAMAccountName, Enabled, lastLogon, lastLogonDate                             #We try to get the user details from AD

                If ($False -eq $Information.Enabled)
                    {
                        #check if a AD disabled user
                        $UserSpace = (Get-ChildItem -Path "$PathItem" | Measure-Object Length -Sum).Sum / 1Gb                                           #Get size
                        $UsersTable += (
                            @{
                                UserName  = "$UserName"; #store the disabled users details into the Array table
                                State     = "Disabled";
                                SpaceinGB = "$UserSpace"
                            })

                        If ($ReadOnlyRun -eq 1)
                            {
                                Write-host "User $UserName is disabled. This is a read only run, nothing will be deleted." -ForegroundColor Gray
                            }

                        $PotentialSpaceReclamation = $PotentialSpaceReclamation + $UserSpace                                                            #Cumulative space to be reclaimed
                        $SpaceDisabled = $SpaceDisabled + $UserSpace

                        If ($DeleteDisabled -eq 1)                                                                                                      #deleting disabled users.
                            {

                                If ($ReadOnlyRun -eq 0)
                                    {
                                        If ($OnlyDeleteODFC -eq 1)
                                            {
                                                #only delete the ODFC container if set to 1.
                                                Write-Host "Deleting only ODFC container from $UserName" -ForegroundColor DarkYellow
                                                $SpaceReclaimed = $SpaceReclaimed + $UserSpace
                                                $DeleteFile = $PathItem.FullName + "\ODFC*.*"
                                                Remove-Item -Path $DeleteFile -Force
                                            }
                                        Else
                                            {
                                                #else deletes all containers if set to 0.
                                                Write-Host "Deleting all containers from $UserName" -ForegroundColor Yellow -BackgroundColor DarkRed
                                                $SpaceReclaimed = $SpaceReclaimed + $UserSpace
                                                Remove-Item -Path $PathItem -Recurse -Force
                                            }
                                    }
                            }

                        ElseIf ($Information.lastLogonDate -lt ((Get-Date).Adddays( - ($DaysInactive))))                                                   #check inactive users to delete.
                            {


                                $UserSpace = (Get-ChildItem -Path "$PathItem" | Measure-Object Length -Sum).Sum / 1Gb
                                $UsersTable += (
                                    @{
                                        UserName  = "$UserName";
                                        State     = "Inactive";
                                        SpaceinGB = "$UserSpace"
                                    })
                                If ($ReadOnlyRun -eq 1)
                                    {
                                        #no action for read only mode.
                                        Write-Host "User $UserName is more than $DaysInactive days inactive. This is a read only run, nothing will be deleted." -ForegroundColor Gray
                                    }

                                $PotentialSpaceReclamation = $PotentialSpaceReclamation + $UserSpace
                                $SpaceInactive = $SpaceInactive + $UserSpace

                                If ($DeleteInactive -eq 1)
                                    {
                                        If ($ReadOnlyRun -eq 0)
                                            {
                                                If ($OnlyDeleteODFC -eq 1)
                                                    {
                                                        #delete ODFC Containers only mode
                                                        Write-Host "Deleting only ODFC container from $UserName" -ForegroundColor DarkYellow
                                                        $SpaceReclaimed = $SpaceReclaimed + $UserSpace
                                                        $DeleteFile = $PathItem.FullName + "\ODFC*.*"
                                                        Remove-Item -Path $DeleteFile -Force
                                                    }
                                                Else
                                                    {
                                                        #delete all containers
                                                        Write-Host "Deleting containers from $UserName" -ForegroundColor Yellow -BackgroundColor DarkRed
                                                        $SpaceReclaimed = $SpaceReclaimed + $UserSpace
                                                        Remove-Item -Path $PathItem -Recurse -Force
                                                    }
                                            }
                                    }
                            }
                    }
            }

        #so our try failed
        Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]                        #we catch the exception of AD identity not found
        {
            $UserSpace = (Get-ChildItem -Path "$PathItem" | Measure-Object Length -Sum).Sum / 1Gb

            $UsersTable += (
                @{
                    UserName  = "$UserName";
                    State     = "DoesntExist";
                    SpaceinGB = "$UserSpace"
                })

            If ($ReadOnlyRun -eq 1)
                {
                    Write-Host "User $UserName doesn't exist. This is a read only run, nothing will be deleted." -ForegroundColor Gray
                }

            $PotentialSpaceReclamation = $PotentialSpaceReclamation + $UserSpace
            $SpaceNotExisting = $SpaceNotExisting + $UserSpace

            If ($DeleteNotExisting -eq 1)
                {
                    #we check if flag is set to delete non existing user containers
                    If ($ReadOnlyRun -eq 0)
                        {
                            #we check if this is a read only run
                            If ($OnlyDeleteODFC -eq 1)
                                {
                                    #we check if we only want to delete ODFC
                                    Write-Host "Deleting only ODFC container from $UserName" -ForegroundColor DarkYellow
                                    $SpaceReclaimed = $SpaceReclaimed + $UserSpace
                                    $DeleteFile = $PathItem.FullName + "\ODFC*.*"
                                    Remove-Item -Path $DeleteFile -Force
                                }
                            Else
                                {
                                    #else we delete all containers
                                    Write-Host "Deleting containers from $UserName" -ForegroundColor Yellow -BackgroundColor DarkYellow
                                    $SpaceReclaimed = $SpaceReclaimed + $UserSpace
                                    Remove-Item -Path $PathItem -Recurse -Force
                                }
                        }
                }
        }
    }

#now we do the calculation.

$PotentialSpaceReclamation = "{0:N2} GB" -f $PotentialSpaceReclamation                                                                                                      #how much space we can reclaim
$SpaceReclaimed = "{0:N2} GB" -f $SpaceReclaimed                                                                                                                            #if delete operations were enabled, how much we reclaimed after deleting.
$SpaceDisabled = "{0:N2} GB" -f $SpaceDisabled                                                                                                                              #space from disabled accounts
$SpaceNotExisting = "{0:N2} GB" -f $SpaceNotExisting                                                                                                                        #space from non-existing user containers.
$SpaceInactive = "{0:N2} GB" -f $SpaceInactive                                                                                                                              #space from inactive accounts.

Write-Host ""
If ($ShowTable -eq 1)
    {
        #i suggest you always show the table
        Write-Host "========================================="
        $UsersTable | ForEach-Object { [PSCustomObject]$_ } | Format-Table UserName, State, SpaceinGB
    }

Write-Host "========================================="
Write-Host ""
Write-Host "Processed Container Folders:"$Counter

If ($ReadOnlyRun -eq 1)
    {
        Write-Host "Potential $PotentialSpaceReclamation can be reclaimed."
    }

Write-Host "Disabled users are claiming $SpaceDisabled"
Write-Host "Not Existing users are claiming $SpaceNotExisting"
Write-Host "Inactive users are claiming $SpaceInactive"
Write-Host "$SpaceReclaimed total reclaimed."
Write-Host "End process" -ForegroundColor Green
Write-Host ""
