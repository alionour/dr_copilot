import json
import sys

# Define the missing keys
missing_keys = {
    "about": "About",
    "aboutDescription": "Dr. Copilot is a comprehensive clinic management application designed to streamline your clinic operations.",
    "amountCannotExceedOneMillion": "Amount cannot exceed one million",
    "anErrorOccurred": "An error occurred",
    "apiKeySettings": "API Key Settings",
    "calendarViewSelectView": "Select View",
    "cases": "Cases",
    "chatGptProject": "ChatGPT Project",
    "clinicalReportAddedSuccessfully": "Clinical report added successfully",
    "clinicalReports": "Clinical Reports",
    "clinicalReportUpdatedSuccessfully": "Clinical report updated successfully",
    "connect": "Connect",
    "createClinicalReport": "Create Clinical Report",
    "createdAt": "Created at",
    "createReport": "Create Report",
    "currencyProfileDeleted": "Currency profile deleted successfully",
    "currencyProfileUpdated": "Currency profile updated successfully",
    "daysAgo": "{} days ago",
    "deleteAll": "Delete All",
    "deleteReport": "Delete Report",
    "deleteReportConfirmation": "Are you sure you want to delete this report?",
    "editClinicalReport": "Edit Clinical Report",
    "editPatient": "Edit Patient",
    "endTimeAfterStartTime": "End time must be after start time",
    "enterValidInteger": "Enter a valid integer",
    "enterValidNumber": "Enter a valid number",
    "enterYourOpenAIApiKey": "Enter your OpenAI API key",
    "errorPageMessage": "The page you are looking for was not found or an error occurred",
    "errorPageTitle": "Error",
    "exportSuccess": "Export successful",
    "exportToGoogleDocs": "Export to Google Docs",
    "failedToFetchSessions": "Failed to fetch sessions",
    "failedToProcessSessions": "Failed to process sessions",
    "failedToAddInvoice": "Failed to add invoice",
    "failedToAddTransaction": "Failed to add transaction",
    "googleDriveNotConnected": "Google Drive not connected",
    "goToHome": "Go to Home",
    "hoursAgo": "{} hours ago",
    "invoiceAddedSuccessfully": "Invoice added successfully",
    "invoiceAndTransactionDeleted": "Invoice and transaction deleted successfully",
    "invoiceDeleted": "Invoice deleted successfully",
    "justNow": "Just now",
    "markAsRead": "Mark as read",
    "minutesAgo": "{} minutes ago",
    "mustBeGreaterThanZero": "Must be greater than zero",
    "noChatGptProjectsFound": "No ChatGPT projects found",
    "noClinicalReportsFound": "No clinical reports found",
    "noDoctors": "No doctors found",
    "noEvaluationsFound": "No evaluations found",
    "noPatientsFound": "No patients found",
    "noPatientsMatchsMatch": "No patients match the search",
    "noPhoneNumber": "No phone number",
    "noReports": "No reports",
    "noResultsFound": "No results found",
    "noSessions": "No sessions found",
    "noStaff": "No staff found",
    "noTransactionsMatch": "No transactions match the filters",
    "patient": "Patient",
    "pleaseSelectSpecialty": "Please select a specialty",
    "pleaseSignIn": "Please sign in to continue",
    "processedAllSessionsSuccessfully": "Processed all sessions successfully",
    "referenceIdCannotBeNull": "Reference ID cannot be null",
    "retry": "Retry",
    "saveApiKey": "Save API Key",
    "saveChanges": "Save Changes",
    "selectClinic": "Select Clinic",
    "selectPatient": "Select Patient",
    "selectPatientError": "Please select a patient",
    "startTyping": "Start typing...",
    "success": "Success",
    "transactionAddedSuccessfully": "Transaction added successfully",
    "transactionsFound": "Transactions Found",
    "transactionSource": "Transaction Source",
    "transactionUpdated": "Transaction updated successfully",
    "valueTooLarge": "Value is too large"
}

en_path = r"f:\Ali\Projects\alionour33\dr_copilot\assets\translations\en.json"
ar_path = r"f:\Ali\Projects\alionour33\dr_copilot\assets\translations\ar.json"

# Arabic translations
arabic_translations = {
    "about": "حول",
    "aboutDescription": "د. كوبايلوت هو تطبيق شامل لإدارة العيادات مصمم لتبسيط عمليات عيادتك.",
    "amountCannotExceedOneMillion": "لا يمكن أن يتجاوز المبلغ مليون",
    "anErrorOccurred": "حدث خطأ",
    "apiKeySettings": "إعدادات مفتاح API",
    "calendarViewSelectView": "اختر العرض",
    "cases": "الحالات",
    "chatGptProject": "مشروع ChatGPT",
    "clinicalReportAddedSuccessfully": "تمت إضافة التقرير السريري بنجاح",
    "clinicalReports": "التقارير السريرية",
    "clinicalReportUpdatedSuccessfully": "تم تحديث التقرير السريري بنجاح",
    "connect": "ربط",
    "createClinicalReport": "إنشاء تقرير سريري",
    "createdAt": "تم الإنشاء في",
    "createReport": "إنشاء تقرير",
   "currencyProfileDeleted": "تم حذف ملف تعريف العملة بنجاح",
    "currencyProfileUpdated": "تم تحديث ملف تعريف العملة بنجاح",
    "daysAgo": "منذ {} أيام",
    "deleteAll": "حذف الكل",
    "deleteReport": "حذف التقرير",
    "deleteReportConfirmation": "هل أنت متأكد من حذف هذا التقرير؟",
    "editClinicalReport": "تعديل التقرير السريري",
    "editPatient": "تعديل المريض",
    "endTimeAfterStartTime": "يجب أن يكون وقت الانتهاء بعد وقت البدء",
    "enterValidInteger": "أدخل عددًا صحيحًا صالحًا",
    "enterValidNumber": "أدخل رقمًا صالحًا",
    "enterYourOpenAIApiKey": "أدخل مفتاح OpenAI API الخاص بك",
    "errorPageMessage": "الصفحة التي تبحث عنها غير موجودة أو حدث خطأ",
    "errorPageTitle": "خطأ",
    "exportSuccess": "تم التصدير بنجاح",
    "exportToGoogleDocs": "تصدير إلى Google Docs",
    "failedToFetchSessions": "فشل في جلب الجلسات",
    "failedToProcessSessions": "فشل في معالجة الجلسات",
    "failedToAddInvoice": "فشل في إضافة الفاتورة",
    "failedToAddTransaction": "فشل في إضافة المعاملة",
    "googleDriveNotConnected": "Google Drive غير متصل",
    "goToHome": "العودة إلى الصفحة الرئيسية",
    "hoursAgo": "منذ {} ساعات",
    "invoiceAddedSuccessfully": "تمت إضافة الفاتورة بنجاح",
    "invoiceAndTransactionDeleted": "تم حذف الفاتورة والمعاملة بنجاح",
    "invoiceDeleted": "تم حذف الفاتورة بنجاح",
    "justNow": "الآن",
    "markAsRead": "تحديد كمقروء",
    "minutesAgo": "منذ {} دقائق",
    "mustBeGreaterThanZero": "يجب أن يكون أكبر من صفر",
    "noChatGptProjectsFound": "لم يتم العثور على مشاريع ChatGPT",
    "noClinicalReportsFound": "لم يتم العثور على تقارير سريرية",
    "noDoctors": "لم يتم العثور على أطباء",
    "noEvaluationsFound": "لم يتم العثور على تقييمات",
    "noPatientsFound": "لم يتم العثور على مرضى",
    "noPatientsMatchsMatch": "لا يوجد مرضى يطابقون البحث",
    "noPhoneNumber": "لا يوجد رقم هاتف",
    "noReports": "لا توجد تقارير",
    "noResultsFound": "لم يتم العثور على نتائج",
    "noSessions": "لم يتم العثور على جلسات",
    "noStaff": "لم يتم العثور على موظفين",
    "noTransactionsMatch": "لا توجد معاملات تطابق الفلاتر",
    "patient": "المريض",
    "pleaseSelectSpecialty": "الرجاء اختيار التخصص",
    "pleaseSignIn": "الرجاء تسجيل الدخول للمتابعة",
    "processedAllSessionsSuccessfully": "تمت معالجة جميع الجلسات بنجاح",
    "referenceIdCannotBeNull": "لا يمكن أن يكون معرف المرجع فارغًا",
    "retry": "إعادة المحاولة",
    "saveApiKey": "حفظ مفتاح API",
    "saveChanges": "حفظ التغييرات",
    "selectClinic": "اختر العيادة",
    "selectPatient": "اختر المريض",
    "selectPatientError": "الرجاء اختيار مريض",
    "startTyping": "ابدأ الكتابة...",
    "success": "نجح",
    "transactionAddedSuccessfully": "تمت إضافة المعاملة بنجاح",
    "transactionsFound": "تم العثور على معاملات",
    "transactionSource": "مصدر المعاملة",
    "transactionUpdated": "تم تحديث المعاملة بنجاح",
    "valueTooLarge": "القيمة كبيرة جدًا"
}

# Load EN json
with open(en_path, 'r', encoding='utf-8') as f:
    en_data = json.load(f)

# Load AR json
with open(ar_path, 'r', encoding='utf-8') as f:
    ar_data = json.load(f)

added_count = 0
# Add missing keys
for key, value in missing_keys.items():
    if key not in en_data:
        en_data[key] = value
        added_count += 1
        print(f"Added EN key: {key}")

# Save EN json
with open(en_path, 'w', encoding='utf-8') as f:
    json.dump(en_data, f, ensure_ascii=False, indent=2)

print(f"\nAdded {added_count} keys to en.json")

# Add Arabic translations
ar_added = 0
for key, value in arabic_translations.items():
    if key not in ar_data:
        ar_data[key] = value
        ar_added += 1
        print(f"Added AR key: {key}")

# Save AR json
with open(ar_path, 'w', encoding='utf-8') as f:
    json.dump(ar_data, f, ensure_ascii=False, indent=2)

print(f"\nAdded {ar_added} keys to ar.json")
print("\nDone!")
