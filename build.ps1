function packer-build {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    # Equivalent to:
    # export PACKER_NO_COLOR=1
    # export PACKER_LOG=true
    $env:PACKER_NO_COLOR = "1"
    $env:PACKER_LOG = "true"

    # Create ./log directory if it doesn't exist
    $logDir = Join-Path $PWD "log"

    if (-not (Test-Path -Path $logDir -PathType Container)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    # Equivalent to:
    # TS=$(date +"%Y-%m-%d_%H:%M:%S")
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

    # Equivalent to:
    # export PACKER_LOG_PATH=${PWD}/log/packer-${TS}.log
    $packerLogPath = Join-Path $logDir "packer-$timestamp.log"
    $env:PACKER_LOG_PATH = $packerLogPath

    Write-Host "Packer log: $packerLogPath"

    # Equivalent to:
    # packer validate "${@}"
    & packer validate @Arguments

    if ($LASTEXITCODE -eq 0) {
        # Equivalent to:
        # packer build "${@}" | tee packer-${TS}.log

        $buildLogPath = Join-Path $PWD "packer-$timestamp.log"

        & packer build @Arguments 2>&1 |
                Tee-Object -FilePath $buildLogPath

        # Preserve Packer's exit code
        if ($LASTEXITCODE -ne 0) {
            return $LASTEXITCODE
        }
    }
    else {
        Write-Error "Packer validation failed with exit code $LASTEXITCODE"
        return $LASTEXITCODE
    }
}
