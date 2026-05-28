import os
import re
import json
import urllib.request
import urllib.parse
import time

project_dir = r"f:\Projects\My_Clinic_Manager\dr_copilot"
translations_dir = os.path.join(project_dir, "assets", "translations")

languages = ["en", "ar", "de", "es", "fr"]

# Load files
filepaths = {lang: os.path.join(translations_dir, f"{lang}.json") for lang in languages}
translations = {}
for lang, path in filepaths.items():
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            translations[lang] = json.load(f)
    else:
        translations[lang] = {}

# 1. 51 Newly discovered missing keys from Code to add to en.json
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

# Update en.json with the new keys
en_data = translations["en"]
en_updated = 0
for k, v in new_keys_en_defaults.items():
    if k not in en_data:
        en_data[k] = v
        en_updated += 1

print(f"Added {en_updated} new keys to en.json.")

# Recursive dictionary helpers
def get_flat_keys(d, current_path=[]):
    flat = []
    for k, v in d.items():
        path = current_path + [k]
        if isinstance(v, dict):
            flat.extend(get_flat_keys(v, path))
        else:
            flat.append((path, v))
    return flat

def get_val_at_path(d, path):
    curr = d
    for p in path:
        if isinstance(curr, dict) and p in curr:
            curr = curr[p]
        else:
            return None
    return curr

def set_val_at_path(d, path, value):
    curr = d
    for p in path[:-1]:
        if p not in curr or not isinstance(curr[p], dict):
            curr[p] = {}
        curr = curr[p]
    curr[path[-1]] = value

# Helper function to perform single translation
def translate_single(text, target_lang):
    if not isinstance(text, str) or not text.strip():
        return text
    # Avoid translating placeholder-only or empty/special strings
    if text == "{}" or text == "%s":
        return text
    try:
        url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=" + target_lang + "&dt=t&q=" + urllib.parse.quote(text)
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
            translated = "".join([sentence[0] for sentence in data[0]])
            # Clean up potential spacing around placeholders like { } -> {}
            translated = re.sub(r'\{\s*\}', '{}', translated)
            return translated
    except Exception as e:
        print(f"  Warning: failed to translate '{text}': {e}")
        return text

# Helper function to perform batched translation
def translate_batch(texts, target_lang):
    if not texts:
        return []
    delimiter = " [||] "
    combined_text = delimiter.join(texts)
    try:
        translated_combined = translate_single(combined_text, target_lang)
        # Split back using regex to allow slight spacing differences from translator
        split_pattern = re.compile(r'\s*\[\|\|\]\s*|\s*\[\s*\|\|\s*\]\s*')
        parts = split_pattern.split(translated_combined)
        parts = [p.strip() for p in parts if p.strip()]
        if len(parts) == len(texts):
            return parts
        else:
            print(f"  Batch size mismatch ({len(parts)} vs {len(texts)}). Falling back to single translations...")
    except Exception as e:
        print(f"  Batch translation failed: {e}. Falling back to single...")
    
    # Fallback to single translation
    results = []
    for text in texts:
        results.append(translate_single(text, target_lang))
        time.sleep(0.1)
    return results

# Flatten all en_data keys
flat_en = get_flat_keys(en_data)

# 2. Synchronize all target languages
for lang in languages:
    if lang == "en":
        continue
    
    lang_data = translations[lang]
    
    # Find all paths missing in the target language
    missing_items = []
    for path, val in flat_en:
        target_val = get_val_at_path(lang_data, path)
        if target_val is None:
            missing_items.append((path, val))
    
    if not missing_items:
        print(f"{lang}.json is already fully synchronized!")
        continue
        
    print(f"Synchronizing {lang}.json. Missing {len(missing_items)} keys...")
    
    # Batch translate missing keys
    batch_size = 30 # Slightly smaller batch size to avoid long string timeouts
    new_translations = []
    
    for i in range(0, len(missing_items), batch_size):
        batch = missing_items[i:i+batch_size]
        batch_paths = [item[0] for item in batch]
        batch_values = [item[1] for item in batch]
        
        print(f"  Translating batch {i//batch_size + 1} of {(len(missing_items)-1)//batch_size + 1} ({len(batch)} keys)...")
        translated_values = translate_batch(batch_values, lang)
        
        for path, tv in zip(batch_paths, translated_values):
            new_translations.append((path, tv))
            
        time.sleep(0.5) # Sleep between batches to respect rate limits
        
    # Merge translations
    for path, tv in new_translations:
        set_val_at_path(lang_data, path, tv)
        
    # Save the updated language file
    with open(filepaths[lang], "w", encoding="utf-8") as f:
        json.dump(lang_data, f, ensure_ascii=False, indent=2)
    print(f"Successfully saved {filepaths[lang]} with {len(new_translations)} new translations.")

# Save final updated en.json as well
with open(filepaths["en"], "w", encoding="utf-8") as f:
    json.dump(en_data, f, ensure_ascii=False, indent=2)
print("Successfully saved en.json.")
