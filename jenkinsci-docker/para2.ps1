# https://stackoverflow.com/q/70354367/4074148

$servers = @('Server1','Server2','Server3')
$maxthreads = 4 # => Limit num of concurrent jobs

# Sample Function to test
function SampleFunction ([string]$Name) {
    Write-Output("=== name: $name")
    Start-Sleep 10
    
    Return "Hello $Name from function .."
}
$funcDef = "function SampleFunction {$function:SampleFunction}"

Get-Job Thread* | Remove-Job | Out-Null

$colors = "Blue", "Red", "Cyan", "Green", "Magenta"
$colorCount = $colors.Length

$jobs = foreach ($server in $servers) {
    
    $running = Get-Job -State Running
    Write-Host("Running:"+$running.Count.ToString())
    if ($running.Count -ge $maxthreads) {
        $null = $running | Wait-Job
    }
    #Start-Sleep 1
    Write-Host "Starting job for $server"
    $ThreadName = "Thread-$server"
    
    Start-Job -Name $ThreadName {
        . ([scriptblock]::Create($using:funcdef)) # => Load the function in this scope
        return SampleFunction -Name $using:server
    } # => Better to capture the Job instances /// | Out-Null
}

try {
    while (($jobs | Where-Object { $_.State -ieq "running" } | Measure-Object).Count -gt 0) {
        # $jobs | ForEach-Object { $i = 1 } {
        $jobs | ForEach-Object { # $i = 1 } {
            $id = $_.Id
            #Write-Host "id-$id"
            $fgColor = $colors[($id - 1) % $colorCount]
            # ConvertTo-Json $_
            $out = $_ | Receive-Job
            $out = $out -split [System.Environment]::NewLine
            $out | ForEach-Object {
                Write-Host "$id> "-NoNewline -ForegroundColor $fgColor
                Write-Host $_
            }
            
            $i++
        }
    }
} finally {
    Write-Host "Stopping Parallel Jobs ..." -NoNewline
    $jobs | Stop-Job
    $jobs | Remove-Job -Force
    Write-Host " done."
}

# Write-Host "== result..."
# $result = $jobs | Receive-Job -Wait -AutoRemoveJob

# Write-Host "== result: $result"
