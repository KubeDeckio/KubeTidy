function Invoke-KubeTidyBinary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $binary = Get-KubeTidyBinaryPath

    try {
        & $binary @Arguments
    }
    catch {
        $message = if ($_.Exception -and $_.Exception.Message) { $_.Exception.Message } else { $_ | Out-String }
        throw "Failed to execute kubetidy binary at '$binary': $message"
    }

    if ($LASTEXITCODE -ne 0) {
        throw "kubetidy $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }
}
