# PowerShell script to count lines of code in Solidity files
# Usage: Save as count_sol_lines.ps1 and run in the project directory

# Define the contracts directory path
$contractsPath = "contracts"

# Check if contracts directory exists
if (-not (Test-Path $contractsPath)) {
    Write-Host "Error: 'contracts' directory not found in current location." -ForegroundColor Red
    Write-Host "Current location: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

# Initialize results array
$results = @()

# Get all .sol files in the contracts directory (including subdirectories)
$solFiles = Get-ChildItem -Path $contractsPath -Filter "*.sol" -Recurse

if ($solFiles.Count -eq 0) {
    Write-Host "No .sol files found in the contracts directory." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($solFiles.Count) Solidity files. Processing..." -ForegroundColor Green

# Process each .sol file
foreach ($file in $solFiles) {
    try {
        # Read all lines from the file
        $lines = Get-Content -Path $file.FullName -ErrorAction Stop
        
        # Count non-empty lines (excluding blank lines)
        $lineCount = ($lines | Where-Object { $_.Trim() -ne "" }).Count
        
        # Get parent and grandparent folder names
        $parentFolder = Split-Path -Leaf (Split-Path -Parent $file.FullName)
        $grandparentFolder = Split-Path -Leaf (Split-Path -Parent (Split-Path -Parent $file.FullName))
        
        # Construct the filename format: <grandparent>_<parent>_<solfile>_slither_report_1.txt
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $constructedFilename = "${grandparentFolder}_${parentFolder}_${baseName}_slither_report_1.txt"
        
        # Create result object
        $result = [PSCustomObject]@{
            filename = $constructedFilename
            line_of_code = $lineCount
        }
        
        $results += $result
        Write-Host "Processed: $($file.Name) -> $constructedFilename - $lineCount lines" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Error processing $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Sort results by filename
$results = $results | Sort-Object filename

# Export to CSV
$outputFile = "solidity_lines_count.csv"
$results | Export-Csv -Path $outputFile -NoTypeInformation

Write-Host "`nResults exported to: $outputFile" -ForegroundColor Green
Write-Host "Total files processed: $($results.Count)" -ForegroundColor Green

# Show first few results as preview
Write-Host "`nPreview of results:" -ForegroundColor Yellow
$results | Select-Object -First 5 | Format-Table -AutoSize