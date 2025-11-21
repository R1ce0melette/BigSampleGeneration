param(
    [string]$RootPath = "${PWD}",
    [switch]$WhatIf
)

# Models to organize
$models = @("GPT4", "Gemini2.5", "Claude4.5")

Write-Host "Organizing files under: $RootPath"

# Ensure root path exists
if (-not (Test-Path -Path $RootPath)) {
    Write-Error "Root path '$RootPath' does not exist."
    exit 1
}

$summary = @{}
foreach ($m in $models) { $summary[$m] = 0 }

# Find files recursively
Get-ChildItem -Path $RootPath -Recurse -File | ForEach-Object {
    $file = $_
    $name = $file.Name
    foreach ($model in $models) {
        if ($name -match [regex]::Escape($model)) {
            $destDir = Join-Path -Path $RootPath -ChildPath $model
            if (-not (Test-Path -Path $destDir)) {
                if ($WhatIf) { Write-Host "[WhatIf] Would create directory: $destDir" } else { New-Item -Path $destDir -ItemType Directory | Out-Null }
            }

            # Destination path
            $destPath = Join-Path -Path $destDir -ChildPath $name

            # Handle collisions
            $counter = 1
            $baseName = [IO.Path]::GetFileNameWithoutExtension($name)
            $ext = [IO.Path]::GetExtension($name)
            while (Test-Path -Path $destPath) {
                $destPath = Join-Path -Path $destDir -ChildPath ("{0}_{1}{2}" -f $baseName, $counter, $ext)
                $counter++
            }

            if ($WhatIf) {
                Write-Host "[WhatIf] Would move: $($file.FullName) -> $destPath"
            } else {
                Move-Item -Path $file.FullName -Destination $destPath
                Write-Host "Moved: $($file.FullName) -> $destPath"
                $summary[$model]++
            }

            # Stop checking other models for this file (avoid double moving)
            break
        }
    }
}

Write-Host "\nSummary:" 
foreach ($m in $models) {
    Write-Host "- $m : $($summary[$m]) files moved"
}

Write-Host "Done."