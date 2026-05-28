import os
import json

project_dir = r"f:\Projects\My_Clinic_Manager\dr_copilot"
en_path = os.path.join(project_dir, "assets", "translations", "en.json")
ar_path = os.path.join(project_dir, "assets", "translations", "ar.json")
de_path = os.path.join(project_dir, "assets", "translations", "de.json")
es_path = os.path.join(project_dir, "assets", "translations", "es.json")
fr_path = os.path.join(project_dir, "assets", "translations", "fr.json")

# 1. New keys that we found are used in code but missing from en.json:
new_keys_en_defaults = {
    "access_denied_admins_only": "Access Denied. Admins Only.",
    "approve": "Approve",
    "bookingApproved": "Booking Approved",
    "bookingRejected": "Booking Rejected",
    "bookingRequests": "Booking Requests",
    "clinicName": "Clinic Name",
    "close": "Close",
    "couldNotLaunchPaymentUrl": "Could not launch payment URL",
    "createClinic": "Create Clinic",
    "dataExportRestricted": "Data export restricted to admins",
    "date": "Date",
    "deleteTransaction": "Delete Transaction",
    "deleteTransactionConfirmation": "Are you sure you want to delete this transaction?",
    "editMedicalRecord": "Edit Medical Record",
    "enterClinicNameMessage": "Please enter your clinic name to set up your clinic.",
    "evaluationLimitReached": "Evaluation limit reached. Please upgrade your subscription.",
    "eventDetails": "Event Details",
    "filters": "Filters",
    "howWouldYouLikeToOpenThisFile": "How would you like to open this file?",
    "kioskQrCode": "Kiosk QR Code",
    "managedByAdmin": "Managed by admin",
    "maxActiveLinksReached": "Maximum active links reached",
    "newPatient": "New Patient",
    "noClinicSelected": "No clinic selected",
    "noFilesFound": "No files found",
    "noNotificationPermissions": "No notification permissions",
    "noPendingBookings": "No pending bookings found",
    "none": "None",
    "openFileOptions": "Open File Options",
    "openInApp": "Open in App",
    "pastEvent": "Past Event",
    "patientLimitReached": "Patient limit reached. Please upgrade your subscription.",
    "pending": "Pending",
    "permissions": "Permissions",
    "pleaseEnterClinicName": "Please enter clinic name",
    "pleaseSignInFirst": "Please sign in first",
    "referenceIdNotFound": "Reference ID not found",
    "reject": "Reject",
    "reset": "Reset",
    "selectTeamMember": "Select Team Member",
    "send": "Send",
    "sessionLimitReached": "Session limit reached. Please upgrade your subscription.",
    "setDueDate": "Set Due Date",
    "setUpYourClinic": "Set Up Your Clinic",
    "task": "Task",
    "time": "Time",
    "unassigned": "Unassigned",
    "upgrade": "Upgrade",
    "upgradeRequired": "Upgrade Required",
    "upgradeToExportData": "Upgrade to export data",
    "you": "You",
    "failedToFetchSessions": "Failed to fetch sessions",
    "processedAllSessionsSuccessfully": "Processed all sessions successfully!",
    "failedToProcessSessions": "Failed to process sessions",
    "noMedicationsFound": "No medications found"
}

with open(en_path, "r", encoding="utf-8") as f:
    en_data = json.load(f)

# Add the new keys to en_data temporarily for extraction
for k, v in new_keys_en_defaults.items():
    if k not in en_data:
        en_data[k] = v

with open(ar_path, "r", encoding="utf-8") as f:
    ar_data = json.load(f)
with open(de_path, "r", encoding="utf-8") as f:
    de_data = json.load(f)
with open(es_path, "r", encoding="utf-8") as f:
    es_data = json.load(f)
with open(fr_path, "r", encoding="utf-8") as f:
    fr_data = json.load(f)

missing_ar = {k: en_data[k] for k in en_data if k not in ar_data}
missing_de = {k: en_data[k] for k in en_data if k not in de_data}
missing_es = {k: en_data[k] for k in en_data if k not in es_data}
missing_fr = {k: en_data[k] for k in en_data if k not in fr_data}

result = {
    "missing_ar": missing_ar,
    "missing_de": missing_de,
    "missing_es": missing_es,
    "missing_fr": missing_fr
}

output_path = os.path.join(project_dir, "scratch", "missing_details.json")
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(result, f, indent=2, ensure_ascii=False)

print(f"Extracted details:")
print(f"  Missing in Arabic: {len(missing_ar)} keys")
print(f"  Missing in German: {len(missing_de)} keys")
print(f"  Missing in Spanish: {len(missing_es)} keys")
print(f"  Missing in French: {len(missing_fr)} keys")
print(f"Saved to {output_path}")
