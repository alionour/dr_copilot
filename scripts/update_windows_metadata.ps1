param (
    [string]$SubmissionJsonPath,
    [string]$MetadataBasePath
)

Write-Host "Reading submission JSON from $SubmissionJsonPath"
$jsonContent = Get-Content -Path $SubmissionJsonPath -Raw
$submission = $jsonContent | ConvertFrom-Json

# Mapping between Android Fastlane locales and Windows Store locales
# Adjust these mappings based on your actual Store listing languages
$localeMap = @{
    "en-US" = "en-US"
    "ar"    = "ar-SA" # Assuming Saudi Arabia for generic Arabic, or check your store settings
    "de-DE" = "de-DE"
    "es-ES" = "es-ES"
    "fr-FR" = "fr-FR"
}

foreach ($androidLocale in $localeMap.Keys) {
    $windowsLocale = $localeMap[$androidLocale]
    Write-Host "Processing locale: $androidLocale -> $windowsLocale"

    $titlePath = Join-Path $MetadataBasePath "$androidLocale\title.txt"
    $shortDescPath = Join-Path $MetadataBasePath "$androidLocale\short_description.txt"
    $fullDescPath = Join-Path $MetadataBasePath "$androidLocale\full_description.txt"

    if ((Test-Path $shortDescPath) -and (Test-Path $fullDescPath)) {
        $shortDesc = Get-Content -Path $shortDescPath -Raw
        $fullDesc = Get-Content -Path $fullDescPath -Raw
        
        # Clean up strings (trim)
        $shortDesc = $shortDesc.Trim()
        $fullDesc = $fullDesc.Trim()

        # Update the submission object
        # Note: The structure depends on the exact API response. 
        # Usually it's submission.applicationCategory, submission.listings[...], etc.
        
        # Find the listing for this locale
        $listing = $submission.listings | Where-Object { $_.language -eq $windowsLocale }
        
        if ($listing) {
            Write-Host "Updating listing for $windowsLocale"
            $listing.description = $fullDesc
            $listing.shortDescription = $shortDesc
            # $listing.title = $title # Title is often unchangeable via submission update if app name is reserved, but included if needed.
        } else {
            Write-Warning "No listing found for locale $windowsLocale in the existing submission. Skipping."
        }
    } else {
        Write-Warning "Metadata files not found for $androidLocale"
    }
}

# Output the modified JSON
$updatedJson = $submission | ConvertTo-Json -Depth 100
Set-Content -Path $SubmissionJsonPath -Value $updatedJson
Write-Host "Updated submission JSON at $SubmissionJsonPath"
