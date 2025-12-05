# Google Drive Shared Folder Setup Instructions

## Problem
Service accounts in consumer Google Cloud projects don't have their own Google Drive storage, so they can't create documents directly.

## Solution: Shared Folder Approach
Create a shared Google Drive folder and give the service account access to it.

## Setup Steps

### 1. Create a Google Drive Folder

1. Go to [Google Drive](https://drive.google.com) (sign in with your personal Google account)
2. Click **"New"** → **"Folder"**
3. Name it: **"Dr Copilot Clinical Reports"**
4. Click **"Create"**

### 2. Share the Folder with Service Account

1. **Right-click** the folder you just created
2. Click **"Share"**
3. In the "Add people and groups" field, paste this email:
   ```
   dr-copilot-sa@drcopilot-bfc9e.iam.gserviceaccount.com
   ```
4. Set permission to **"Editor"**
5. **Uncheck** "Notify people" (service accounts don't get emails)
6. Click **"Share"**

### 3. Get the Folder ID

1. **Open** the folder you created
2. Look at the URL in your browser, it will look like:
   ```
   https://drive.google.com/drive/folders/1a2B3c4D5e6F7g8H9i0J
                                            ^^^^^^^^^^^^^^^^^^^^
   ```
3. **Copy** the folder ID (the part after `/folders/`)
4. Example: `1a2B3c4D5e6F7g8H9i0J`

### 4. Update the Code

1. Open this file:
   ```
   lib/src/features/clinical_reports/domain/services/google_docs_service.dart
   ```

2. Find this line (around line 14):
   ```dart
   static const String _sharedFolderId = 'REPLACE_WITH_FOLDER_ID';
   ```

3. Replace `REPLACE_WITH_FOLDER_ID` with your actual folder ID:
   ```dart
   static const String _sharedFolderId = '1a2B3c4D5e6F7g8H9i0J';
   ```

4. Save the file

### 5. Test

1. **Restart** your app
2. Try creating a new clinical report
3. Check your Google Drive folder - you should see the new document!

## Troubleshooting

### Still getting 403 error?
- Double-check the service account email is correct
- Make sure you gave "Editor" permission, not just "Viewer"
- Verify the folder ID is correct (no extra characters)

### Document not appearing in folder?
- Wait a few seconds and refresh Google Drive
- Check the console logs for the document ID
- Search for the document ID in Google Drive

### Service account email not found?
- The email might not show up in autocomplete
- Just paste it fully and press Enter
- Google will show a warning that it's a service account - that's normal

## Security Note

All clinical reports will be created in this shared folder. Make sure:
- Only you have access to this folder
- Don't share this folder with unauthorized users
- Documents are still protected by the "anyone with link" permission we set in code

## Next Steps

After setup is complete, all new clinical reports will be created in this Google Drive folder automatically!
