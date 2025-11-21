# Helper script to run Slither on all .sol files in the current directory and save reports in an immediate folder.
# Get all .sol files in the current directory
$solFiles = Get-ChildItem -Path . -Filter *.sol

# Define the reports folder
$reportsDir = Join-Path (Get-Location) "reports"

# Loop through each .sol file and run slither
foreach ($file in $solFiles) {
    $reportFile = Join-Path $reportsDir ($file.BaseName + "_report.txt")
    Write-Output "Running Slither on $($file.Name)..."
    slither $file.FullName 2>&1 | Out-File -FilePath $reportFile -Encoding utf8
}
