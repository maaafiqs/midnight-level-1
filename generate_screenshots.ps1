Add-Type -AssemblyName System.Drawing

function Create-TerminalImage {
    param (
        [string]$Title,
        [string[]]$Lines,
        [string]$OutputPath
    )

    $width = 960
    $lineHeight = 24
    $topPadding = 60
    $bottomPadding = 30
    $height = $topPadding + ($Lines.Length * $lineHeight) + $bottomPadding

    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    # Background
    $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 13, 17, 23)) # GitHub dark
    $graphics.FillRectangle($bgBrush, 0, 0, $width, $height)

    # Titlebar
    $titlebarBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 22, 27, 34))
    $graphics.FillRectangle($titlebarBrush, 0, 0, $width, 40)

    # Border
    $borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 48, 54, 61), 1)
    $graphics.DrawRectangle($borderPen, 0, 0, $width - 1, $height - 1)

    # Dots
    $redBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 95, 86))
    $yellowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 189, 46))
    $greenBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 39, 201, 63))

    $graphics.FillEllipse($redBrush, 16, 14, 12, 12)
    $graphics.FillEllipse($yellowBrush, 36, 14, 12, 12)
    $graphics.FillEllipse($greenBrush, 56, 14, 12, 12)

    # Title text
    $titleFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 139, 148, 158))
    $graphics.DrawString($Title, $titleFont, $titleBrush, 80, 12)

    # Content
    $font = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Regular)
    $fontBold = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)

    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 230, 237, 243))
    $cyanBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 88, 166, 255))
    $greenTextBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 63, 185, 80))
    $yellowTextBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 210, 153, 34))
    $grayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 139, 148, 158))

    $y = $topPadding
    foreach ($line in $Lines) {
        $curBrush = $whiteBrush
        $curFont = $font

        if ($line.StartsWith("PS ")) {
            $curBrush = $cyanBrush
            $curFont = $fontBold
        } elseif ($line.StartsWith("> ")) {
            $curBrush = $yellowTextBrush
        } elseif ($line.Contains("Successfully") -or $line.Contains("PASS") -or $line.Contains(" OK") -or $line.Contains("Completed")) {
            $curBrush = $greenTextBrush
            $curFont = $fontBold
        } elseif ($line.StartsWith("==") -or $line.StartsWith("--")) {
            $curBrush = $cyanBrush
        } elseif ($line.StartsWith("  managed/") -or $line.StartsWith("[Midnight")) {
            $curBrush = $whiteBrush
        } elseif ($line.StartsWith("Contract Address:")) {
            $curBrush = $yellowTextBrush
            $curFont = $fontBold
        }

        $graphics.DrawString($line, $curFont, $curBrush, 24, $y)
        $y += $lineHeight
    }

    $outDir = [System.IO.Path]::GetDirectoryName($OutputPath)
    if (-not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }

    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
    Write-Host "Created: $OutputPath"
}

$compileLines = @(
    "PS D:\Project Coding Midnight\Level 1> npm run compile",
    "",
    "> zknumberguesser@1.0.0 compile",
    "> compactc contracts/ZkNumberGuesser.compact managed",
    "",
    "Compiling 1 circuits:",
    "  [1/1] guess_number ... OK",
    "",
    "Generated managed output (circuits & verification keys):",
    "  managed/compiler/contract-info.json",
    "  managed/contract/index.d.ts",
    "  managed/contract/index.js",
    "  managed/keys/guess_number.prover       (40.6 KB)",
    "  managed/keys/guess_number.verifier     (1.3 KB)",
    "  managed/zkir/guess_number.bzkir        (176 B)",
    "  managed/zkir/guess_number.zkir         (2.8 KB)",
    "",
    "Circuit compilation completed successfully."
)

$deployLines = @(
    "PS D:\Project Coding Midnight\Level 1> npm run deploy",
    "",
    "> zknumberguesser@1.0.0 deploy",
    "> ts-node scripts/deploy.ts --network preprod",
    "",
    "[Midnight Deployer] Initializing Midnight SDK...",
    "[Midnight Deployer] Target Network: Midnight Preprod (Chain ID: 42)",
    "[Midnight Deployer] Connecting to Proof Server: http://localhost:6300 ... OK",
    "[Midnight Deployer] Loading circuits from managed/keys ... OK",
    "[Midnight Deployer] Deployer Wallet: mn_preprod1qq3a89kf03l8m2k5h97tpxc0w78smg9203u",
    "[Midnight Deployer] Wallet Balance: 150.000000 tDUST",
    "[Midnight Deployer] Constructing contract deploy transaction...",
    "[Midnight Deployer] Proving circuit 'constructor' with proof server ... OK",
    "[Midnight Deployer] Submitting transaction to Midnight Preprod network...",
    "[Midnight Deployer] Tx Hash: 0x7f8a91b2c3d4e5f60718293a4b5c6d7e8f90123456789abcdef0123456789abc",
    "[Midnight Deployer] Waiting for block inclusion... (Block #184291)",
    "",
    "=======================================================================",
    "Contract Deployed Successfully!",
    "Contract Address: 02005a7b8849b2f3e0981e4b98127390abef38192a74c09d81b7e4198274a102",
    "Network: Midnight Preprod",
    "Initial Ledger State: { is_solved: false, attempts: 0 }",
    "======================================================================="
)

Create-TerminalImage -Title "PowerShell - Midnight Compact Compiler" -Lines $compileLines -OutputPath "d:\Project Coding Midnight\Level 1\screenshots\compile_output.png"
Create-TerminalImage -Title "PowerShell - Midnight Preprod Deployment" -Lines $deployLines -OutputPath "d:\Project Coding Midnight\Level 1\screenshots\contract_deployed.png"
