param (
    [string]$ProjectId = "drcopilot-bfc9e",
    [string]$BillingAccountId = "011AC4-919087-7B1120",
    [string]$TopicName = "billing-alerts",
    [string]$BudgetName = "1-dollar-cap",
    [string]$BudgetAmount = "1.00USD",
    [string]$FunctionName = "disable-billing",
    [string]$Region = "us-central1"
)

$ErrorActionPreference = "Stop"

Write-Host "Starting GCP Billing Cap Automation..." -ForegroundColor Cyan

# 1. Enable APIs
Write-Host "Enabling required APIs..." -ForegroundColor Yellow
gcloud services enable pubsub.googleapis.com cloudfunctions.googleapis.com cloudbuild.googleapis.com billingbudgets.googleapis.com --project=$ProjectId

# 2. Create Pub/Sub Topic
Write-Host "Creating Pub/Sub topic '$TopicName'..." -ForegroundColor Yellow
$TopicExists = gcloud pubsub topics list --project=$ProjectId --format="value(name)" | Select-String -Pattern $TopicName
if (-not $TopicExists) {
    gcloud pubsub topics create $TopicName --project=$ProjectId
} else {
    Write-Host "Topic already exists." -ForegroundColor Gray
}

# 3. Create Budget
Write-Host "Creating Budget '$BudgetName'..." -ForegroundColor Yellow
# We need to construct the topic full name
$TopicFullName = "projects/$ProjectId/topics/$TopicName"
# Note: Creating a budget might fail if it already exists with the same name, but gcloud handles it or throws a catchable error. 
# We'll just run it. If it fails, the script will stop (due to ErrorActionPreference).
try {
    gcloud billing budgets create --billing-account=$BillingAccountId --display-name=$BudgetName --budget-amount=$BudgetAmount --notifications-rule-pubsub-topic=$TopicFullName
} catch {
    Write-Host "Budget creation returned an error. It might already exist." -ForegroundColor Yellow
}

# 4. Prepare Cloud Function Code
Write-Host "Preparing Cloud Function code..." -ForegroundColor Yellow
$TempDir = "$env:TEMP\billing_cap_function"
if (Test-Path $TempDir) {
    Remove-Item -Recurse -Force $TempDir
}
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

$IndexJs = '@
const {CloudBillingClient} = require(''@google-cloud/billing'');

exports.stopBilling = async (pubSubEvent, context) => {
  const pubSubData = JSON.parse(Buffer.from(pubSubEvent.data, ''base64'').toString());
  
  // Only trigger when cost goes over the budget (costAmount >= budgetAmount)
  if (pubSubData.costAmount <= pubSubData.budgetAmount) {
    console.log(`No action necessary. Cost: $${pubSubData.costAmount}, Budget: $${pubSubData.budgetAmount}`);
    return `No action necessary`;
  }

  const projectId = process.env.GOOGLE_CLOUD_PROJECT;
  const projectName = `projects/` + projectId;
  const billingClient = new CloudBillingClient();

  try {
    const [billingInfo] = await billingClient.getProjectBillingInfo({ name: projectName });

    if (billingInfo.billingEnabled) {
      console.log(`Disabling billing for project: ` + projectId);
      await billingClient.updateProjectBillingInfo({
        name: projectName,
        projectBillingInfo: { billingAccountName: '''' }, // Empty string unlinks the billing account
      });
      console.log(`Billing successfully disabled.`);
    } else {
      console.log(`Billing is already disabled.`);
    }
  } catch (error) {
    console.error(''Error disabling billing:'', error);
  }
};
'@

$PackageJson = '@
{
  "name": "billing-cap",
  "version": "1.0.0",
  "dependencies": {
    "@google-cloud/billing": "^3.0.0"
  }
}
'@

Set-Content -Path "$TempDir\index.js" -Value $IndexJs
Set-Content -Path "$TempDir\package.json" -Value $PackageJson

# 5. Deploy Cloud Function
Write-Host "Deploying Cloud Function '$FunctionName'..." -ForegroundColor Yellow
# Using --gen2 is recommended for newer functions, but requires Artifact Registry which might require more setup.
# Falling back to Gen 1 (--no-gen2 or just standard deploy) to minimize complexity.
Set-Location $TempDir
# Node.js 20 is standard. We must allow unauthenticated access for pubsub triggers in some setups, but here it's an internal trigger.
# Actually, for Gen 1, trigger-topic doesn't need allow-unauthenticated.
gcloud functions deploy $FunctionName --runtime nodejs20 --trigger-topic $TopicName --entry-point stopBilling --region $Region --project $ProjectId

# 6. Grant IAM Permissions
Write-Host "Granting IAM Permissions to the Cloud Function's Service Account..." -ForegroundColor Yellow
# For Gen 1, the default service account is $ProjectId@appspot.gserviceaccount.com
$ServiceAccountEmail = "$ProjectId@appspot.gserviceaccount.com"

# gcloud beta billing accounts add-iam-policy-binding is currently the way to add IAM to a billing account
gcloud beta billing accounts add-iam-policy-binding $BillingAccountId --member="serviceAccount:$ServiceAccountEmail" --role="roles/billing.admin"

Write-Host "GCP Billing Cap Automation Complete!" -ForegroundColor Green
