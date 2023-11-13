

$servers = @('Server1','Server2','Server3')
$maxthreads = 4 # => Limit num of concurrent jobs

# Sample Function to test
function SampleFunction ([string]$Name) {
    Start-Sleep 30
    Return "Hello $Name from function .."
}
$funcDef = "function SampleFunction {$function:SampleFunction}"

Get-Job Thread* | Remove-Job | Out-Null

$jobs = foreach ($server in $servers) {
    
    $running = Get-Job -State Running
    #write-host("Running:"+$running.Count.ToString()) ;Get-Job Thread*
    if ($running.Count -ge $maxthreads) {
        $null = $running | Wait-Job
    }
    #Start-Sleep 1
    #Write-Host "Starting job for $server"
    $ThreadName = "Thread-$server"
    
    Start-Job -Name $ThreadName {
        . ([scriptblock]::Create($using:funcdef)) # => Load the function in this scope
        return SampleFunction -Name $using:server
    } # => Better to capture the Job instances /// | Out-Null
}

$result = $jobs | Receive-Job -Wait -AutoRemoveJob

Write-Host "== result: $result"
