# Read en.json
$enJsonPath = "f:\Ali\Projects\alionour33\dr_copilot\assets\translations\en.json"
$enJson = Get-Content $enJsonPath -Raw | ConvertFrom-Json

# Missing keys to add
$missingKeys = @{
    "about" = "About"
    "aboutDescription" = "Dr. Copilot is a comprehensive clinic management application designed to streamline your clinic operations."
    "amountCannotExceedOneMillion" = "Amount cannot exceed one million"
    "anErrorOccurred" = "An error occurred"
    "apiKeySettings" = "API Key Settings"
    "calendarViewSelectView" = "Select View"
    "cases" = "Cases"
    "chatGptProject" = "ChatGPT Project"
    "clinicalReportAddedSuccessfully" = "Clinical report added successfully"
    "clinicalReports" = "Clinical Reports"
    "clinicalReportUpdatedSuccessfully" = "Clinical report updated successfully"
    "connect" = "Connect"
    "createClinicalReport" = "Create Clinical Report"
    "createdAt" = "Created at"
    "createReport" = "Create Report"
    "currencyProfileDeleted" = "Currency profile deleted successfully"
    "currencyProfileUpdated" = "Currency profile updated successfully"
    "daysAgo" = "{} days ago"
    "deleteAll" = "Delete All"
    "deleteReport" = "Delete Report"
    "deleteReportConfirmation" = "Are you sure you want to delete this report?"
    "editClinicalReport" = "Edit Clinical Report"
    "editPatient" = "Edit Patient"
    "endTimeAfterStartTime" = "End time must be after start time"
    "enterValidInteger" = "Enter a valid integer"
    "enterValidNumber" = "Enter a valid number"
    "enterYourOpenAIApiKey" = "Enter your OpenAI API key"
    "errorPageMessage" = "The page you are looking for was not found or an error occurred"
    "errorPageTitle" = "Error"
    "exportSuccess" = "Export successful"
    "exportToGoogleDocs" = "Export to Google Docs"
    "failedToFetchSessions" = "Failed to fetch sessions"
    "failedToProcessSessions" = "Failed to process sessions"
    "failedToAddInvoice" = "Failed to add invoice"
    "failedToAddTransaction" = "Failed to add transaction"
    "googleDriveNotConnected" = "Google Drive not connected"
    "goToHome" = "Go to Home"
    "hoursAgo" = "{} hours ago"
    "invoiceAddedSuccessfully" = "Invoice added successfully"
    "invoiceAndTransactionDeleted" = "Invoice and transaction deleted successfully"
    "invoiceDeleted" = "Invoice deleted successfully"
    "justNow" = "Just now"
    "markAsRead" = "Mark as read"
    "minutesAgo" = "{} minutes ago"
    "mustBeGreaterThanZero" = "Must be greater than zero"
    "noChatGptProjectsFound" = "No ChatGPT projects found"
    "noClinicalReportsFound" = "No clinical reports found"
    "noDoctors" = "No doctors found"
    "noEvaluationsFound" = "No evaluations found"
    "noPatientsFound" = "No patients found"
    "noPatientsMatchsMatch" = "No patients match the search"
    "noPhoneNumber" = "No phone number"
    "noReports" = "No reports"
    "noResultsFound" = "No results found"
    "noSessions" = "No sessions found"
    "noStaff" = "No staff found"
    "noTransactionsMatch" = "No transactions match the filters"
    "patient" = "Patient"
    "pleaseSelectSpecialty" = "Please select a specialty"
    "pleaseSignIn" = "Please sign in to continue"
    "processedAllSessionsSuccessfully" = "Processed all sessions successfully"
    "referenceIdCannotBeNull" = "Reference ID cannot be null"
    "retry" = "Retry"
    "saveApiKey" = "Save API Key"
    "saveChanges" = "Save Changes"
    "selectClinic" = "Select Clinic"
    "selectPatient" = "Select Patient"
    "selectPatientError" = "Please select a patient"
    "startTyping" = "Start typing..."
    "success" = "Success"
    "transactionAddedSuccessfully" = "Transaction added successfully"
    "transactionsFound" = "Transactions Found"
    "transactionSource" = "Transaction Source"
    "transactionUpdated" = "Transaction updated successfully"
    "valueTooLarge" = "Value is too large"
}

# Add missing keys
foreach ($key in $missingKeys.Keys) {
    if (-not $enJson.PSObject.Properties.Name -contains $key) {
        $enJson | Add-Member -MemberType NoteProperty -Name $key -Value $missingKeys[$key]
        Write-Host "Added key: $key" -ForegroundColor Green
    } else {
        Write-Host "Skipped existing key: $key" -ForegroundColor Yellow
    }
}

# Save back to file
$enJson | ConvertTo-Json -Depth 10 | Set-Content $enJsonPath -Encoding UTF8

Write-Host "`nSuccessfully updated en.json with missing keys!" -ForegroundColor Cyan
