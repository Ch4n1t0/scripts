# Connect to Azure
Connect-AzAccount -Identity

$SubscriptionList = Get-AzSubscription

$currentTime = Get-Date
$currentTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date -Date $currentTime), 'Central European Standard Time')

foreach ($Id in $SubscriptionList) {

 Set-AzContext -SubscriptionId $Id 

    # Get all Virtual Machines with the tag "ShutdownTime"
    $vmsShutdown = Get-AzVM -status | Where-Object { ($_.Tags.Keys -contains "ShutdownTime") -and ($_.PowerState -eq 'VM running') }
    Write-Output $vmsShutdown
    $vmsStartup = Get-AzVM -status  | Where-Object { ($_.Tags.Keys -contains "StartTime") -and ($_.PowerState -eq 'VM deallocated') }
    

    # Loop through each VM
    foreach ($vm in $vmsShutdown) {
        # Get the value of the ShutdownTime tagVM deallocated
        $shutdownTime = [DateTime]::ParseExact($vm.Tags["ShutdownTime"], "HH:mm", $null)
        #$shutdownTime = $vm.Tags["ShutdownTime"]
    
        # Get the current time and format it to HH:mm
        $timeDiff = ($currentTime - $shutdownTime).TotalMinutes
        Write-Output $timeDiff
    
        # Compare the value of the tag with the current time
        if ($timeDiff -le 80 -and $timeDiff -ge 0) {
            # Shut down the VM
            Write-Output "Shutting down VM $($vm.Name) in $($vm.ResourceGroupName) because ShutdownTime tag value is $($shutdownTime)."
            Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force

        }

    }  

    foreach ($vm in $vmsStartup) {
        # Get the value of the ShutdownTime tag
        $startupTime = [DateTime]::ParseExact($vm.Tags["StartTime"], "HH:mm", $null)
        #$shutdownTime = $vm.Tags["ShutdownTime"]
    
        $timeDiff = ($currentTime - $startupTime).TotalMinutes
    
        # Compare the value of the tag with the current time
        if ($timeDiff -le 60 -and $timeDiff -ge 0) {
            # Shut down the VM
            Write-Output "Starting VM $($vm.Name) in $($vm.ResourceGroupName) because StartupTime tag value is $($startupTime)."
            Start-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name

        }
    }
}
