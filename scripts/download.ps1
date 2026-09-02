function DownloadJetBrainsTools
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Products
    )
    $jetbrains = (Invoke-WebRequest "https://data.services.jetbrains.com/products?code=$Products").Content | ConvertFrom-Json
    for ($i = 0; $i -lt ($jetbrains.length); $i++) {
        $Product = $jetbrains[$i].name
        Write-Output "========== [$Product] =========="
        Write-Output "Fetching and Downloading the product and checksum link..."
        $url = $jetbrains[$i].releases[0].downloads.windows64.link
        $checksumLink = $jetbrains[$i].releases[0].downloads.windows64.checksumLink

        $saveAs = Split-Path $url -Leaf
        Write-Output "Downlading from $url"
        Write-Output "Saving as '$saveAs' ..."
        Invoke-WebRequest -Uri "$url" -OutFile $saveAs
        $downloadedSHA = (Get-FileHash -Path $saveAs -Algorithm SHA256).Hash

        $saveAs = Split-Path $checksumLink -Leaf
        Invoke-WebRequest -Uri "$checksumLink" -OutFile $saveAs
        $remoteSHA = (Get-Content -Path $saveAs).Split(" ")[0].ToUpper()

        if ($downloadedSHA -eq $remoteSHA)
        {
            Write-Output "Downloaded package is valid."
        }
        else
        {
            Write-Warning "Checksum failed."
        }
        Remove-Item -Path $saveAs
    }
    Write-Output "============================"
    Write-Output ""
}
function DownloadVSCode
{
    param(
        [string]$Product = "VS Code"
    )
    Write-Output "========== [$Product] =========="
    Write-Output "Fetching the latest stable version..."
    $vsCodeVersion = ((Invoke-WebRequest -Uri 'https://update.code.visualstudio.com/api/releases/stable' -Method GET).Content | ConvertFrom-Json)[0]
    $url = "https://update.code.visualstudio.com/$vsCodeVersion/win32-x64-user/stable"
    $saveAs = "vscode-$vsCodeVersion.exe"
    Write-Output "Download the latest stable version from $url"
    Write-Output "Saving as '$saveAs' ..."
    Invoke-WebRequest -Uri $url -OutFile $saveAs
    Write-Output "Downlaoded"
    Write-Output "============================"
    Write-Output ""
}
function DownloadWireShark
{
    param(
        [string]$Product = "WireShark"
    )
    Write-Output "========== [$Product] =========="
    $wiresharkEnclosure = ([xml](Invoke-WebRequest -Uri 'https://www.wireshark.org/update/0/Wireshark/0.0.0/Windows/x86-64/en-US/stable.xml' -Method get).Content).rss.channel.item[0].enclosure
    $url = $wiresharkEnclosure.url
    $saveAs = (Split-Path $url -Leaf)
    Write-Output "Downloading from $url"
    Write-Output "Saving as '$saveAs' ..."
    Invoke-WebRequest -Uri $url -OutFile $saveAs
    Write-Output "Downlaoded"
    Write-Output "============================"
    Write-Output ""
}
function DownloadPython
{
    param(
        [string]$Product = "Python",
        [string]$pythonVersion
    )
    if ( [string]::IsNullOrEmpty($pythonVersion))
    {
        $headers = @{ }
        $headers.Add("accept", "application/json")
        $pythonVersion = ((Invoke-WebRequest -Uri 'https://endoflife.date/api/python.json' -Method GET -Header $headers).Content | ConvertFrom-Json)[0].latest
    }
    $Url = "https://www.python.org/ftp/python/$pythonVersion/python-$pythonVersion-amd64.exe"
    $SaveAs = Split-Path $Url -Leaf
    Write-Output "========== [$Product] =========="
    Write-Output "Downloading from $Url ..."
    Write-Output "Saving as '$SaveAs' ..."
    Invoke-WebRequest -Uri $Url -OutFile $SaveAs
    Write-Output "Downlaoded"
    Write-Output "============================"
    Write-Output ""


}
function DownloadWithDirectLink
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Product,

        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [string]$SaveAs
    )
    Write-Output "========== [$Product] =========="
    Write-Output "Downloading from $Url ..."
    if ( [string]::IsNullOrEmpty($SaveAs))
    {
        $SaveAs = Split-Path $Url -Leaf
    }
    Write-Output "Saving as '$SaveAs' ..."
    Invoke-WebRequest -Uri $Url -OutFile $SaveAs
    #Write-Output "Invoke-WebRequest -Uri $Url -OutFile $SaveAs"
    Write-Output "Downlaoded"
    Write-Output "============================"
    Write-Output ""
}
function DownloadToolFromGitHub
{
    param(

        [Parameter(Mandatory = $true)]
        [string]$Product,

        [Parameter(Mandatory = $true)]
        [string]$Org,

        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $true)]
        [string]$FileEndsWith
    )
    Write-Output "========== [$Product] =========="
    $headers = @{ }
    $headers.Add("accept", "application/vnd.github+json")
    $headers.Add("x-github-api-version", "2026-03-10")
    Write-Output "Fetching latest release from GitHub..."
    $latestReleaseAssets = ((Invoke-WebRequest -Uri "https://api.github.com/repos/$Org/$Repo/releases/latest" -Method GET -Headers $headers).Content | ConvertFrom-Json).assets
    $url =
    $checksum =
    Write-Output "Found " + $latestReleaseAssets.length + " assets"
    for ($i = 0; $i -lt ($latestReleaseAssets.length); $i++) {
        $saveAs = $latestReleaseAssets[$i].name
        if ( $saveAs.EndsWith($FileEndsWith))
        {
            $url = $latestReleaseAssets[$i].browser_download_url
            Write-Output "Downloading from $url ..."
            Write-Output "Saving as '$saveAs' ..."
            Invoke-WebRequest -Uri $url -Method GET -OutFile $saveAs
            $fileChecksum = (Get-FileHash -Path $saveAs -Algorithm SHA256).Hash.toLower()
            $downloadedSHA = "sha256:$fileChecksum"

            if ($null -ne $latestReleaseAssets[$i].digest)
            {
                $checksum = $latestReleaseAssets[$i].digest
                if ($downloadedSHA -eq $checksum)
                {
                    Write-Output "Downloaded package is valid."
                }
                else
                {
                    Write-Warning "Checksum failed."
                }
            }
            break
        }
    }
    Write-Output "Downlaoded"
    Write-Output "============================"
    Write-Output ""

}

### Not in use
function DownloadWinADK
{
    $Url = "https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install"
    $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing

    $Regex = "Download the ADK (10\.\d+\.\d+(\.\d+)?)"
    if ($Response.Content -match $Regex)
    {
        $LatestVersion = $Matches[1]
        Write-Output "Latest Stable Windows ADK Version: $LatestVersion"

    }

}
function DownloadEgnyte
{
    param(
        [string]$Product = "Egnyte"
    )
    Write-Output "========== [$Product] =========="
    $html = (Invoke-WebRequest -Uri "https://helpdesk.egnyte.com/hc/en-us/articles/205237150-Desktop-App-Installers").Content
    $Url = [regex]::Matches($html, 'href="([^"]*\.msi)"')[0].Value.Split("=")[1].Trim('"')
    $SaveAs = Split-Path $Url -Leaf
    Write-Output "Downloading from $Url ..."
    Write-Output "Saving as '$SaveAs' ..."
    Invoke-WebRequest -Uri $Url -OutFile $SaveAs
    Write-Output "Downlaoded"
    Write-Output "============================"
    Write-Output ""
}
###

#Remove-Item -Path "C:\Tools" -Recurse -Force
#mkdir "C:\Tools"
#cd C:\Tools

DownloadJetBrainsTools -Products "DPK,DM"
DownloadVSCode
DownloadPython
DownloadToolFromGitHub -Product "7-Zip" -Org "ip7z" -Repo "7zip" -FileEndsWith "-x64.exe"
DownloadToolFromGitHub -Product "Sqlite" -Org "sqlitebrowser" -Repo "sqlitebrowser" -FileEndsWith "-win64.msi"
DownloadToolFromGitHub -Product "GrepWin" -Org "stefankueng" -Repo "grepWin" -FileEndsWith "-x64.msi"
DownloadToolFromGitHub -Product "Notepad++" -Org "notepad-plus-plus" -Repo "notepad-plus-plus" -FileEndsWith ".x64.msi"
DownloadToolFromGitHub -Product "PerfView" -Org "microsoft" -Repo "perfview" -FileEndsWith ".exe"
DownloadWireShark

# Creating a list for saving direct links
$directLinks = [System.Collections.Generic.List[PSCustomObject]]::new()

# The following APIs downloads the latest version directly.
# Hence, DO NOT CHANGE. Change only iff latest endpoints are updated.
$directLinks.Add([PSCustomObject]@{ Product = "Fiddler Everywhere"; Url = "https://api.getfiddler.com/win/latest"; SaveAs = "fiddler-everywhere.exe" })
$directLinks.Add([PSCustomObject]@{ Product = "Sysinternal Suite"; Url = "https://download.sysinternals.com/files/SysinternalsSuite.zip"; SaveAs = "SysinternalsSuite.zip" })
$directLinks.Add([PSCustomObject]@{ Product = "Postman"; Url = "https://dl.pstmn.io/download/latest/win64"; SaveAs = "Postman (x64).exe" })
$directLinks.Add([PSCustomObject]@{ Product = "Visual Studio"; URL = "https://aka.ms/vs/stable/vs_professional.exe"; SaveAs = "vs_professional.exe" })
$directLinks.Add([PSCustomObject]@{ Product = "Windows Debug"; URL = "https://aka.ms/windbg/download"; SaveAs = "windbg.appinstaller" })

# Following endpoints needs to be check monthly or before running automation to have latest version api
$directLinks.Add([PSCustomObject]@{ Product = "Egnyte"; URL = "https://egnyte-cdn.egnyte.com/egnytedrive/win/en-us/4.6.1/EgnyteDesktopApp_4.6.1_204.msi"; SaveAs = "EgnyteDesktopApp_4.6.1_204.msi" })
$directLinks.Add([PSCustomObject]@{ Product = "Windows ADK"; URL = "https://go.microsoft.com/fwlink/?linkid=2289980"; SaveAs = "adksetup.exe" })
$directLinks.Add([PSCustomObject]@{ Product = "Windows SDK"; URL = "https://go.microsoft.com/fwlink/?linkid=2376217"; SaveAs = "winsdksetup.exe" })

$directLinks | ForEach-Object {
    DownloadWithDirectLink -Product $( $_.Product ) -Url $( $_.URL ) -SaveAs $( $_.SaveAs )
}
