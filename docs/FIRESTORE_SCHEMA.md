# Firestore Database Schema

> Auto-generated documentation of the Firestore database schema.
> Last updated: 2025-12-29

## Overview

This database contains **7 collections** with the following structure:

### Collections

- [bills](#bills) (2 documents)
- [evaluations](#evaluations) (46 documents)
- [invoices](#invoices) (886 documents)
- [patients](#patients) (100 documents)
- [sessions](#sessions) (840 documents)
- [transactions](#transactions) (887 documents)
- [users](#users) (1 documents)

---

## bills

**Document Count:** 2

### Fields

| Field Name | Type | Required | Frequency | Sample Values |
|------------|------|----------|-----------|---------------|
| `amount` | number | ✓ | 100.0% | 6000, 2750 |
| `createdAt` | string | ✓ | 100.0% | "2025-05-09T23:55:54.930540", "2025-05-09T23:55:55.426845" |
| `createdBy` | string | ✓ | 100.0% | "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1", "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1" |
| `currencyProfileId` | string | ✓ | 100.0% | "HZaqCFCKlfJTfucR9DN4", "HZaqCFCKlfJTfucR9DN4" |
| `deletedAt` | null | ✓ | 100.0% |  |
| `deletedBy` | null | ✓ | 100.0% |  |
| `description` | string | ✓ | 100.0% | "هذه الفاتورة تمثل القسط الشهري لجاز ال ITO", "" |
| `dueDate` | string | ✓ | 100.0% | "2025-05-01T00:00:00.000", "2025-05-01T00:00:00.000" |
| `id` | string | ✓ | 100.0% | "CX18F14KxhaN3yPQVZbS", "uiWcalayOSTfRLoAhTik" |
| `payedAt` | null | string | ✓ | 100.0% | "2025-05-15T14:52:34.673461" |
| `paymentMethod` | null | ✓ | 100.0% |  |
| `scheduledBillId` | string | ✓ | 100.0% | "BftxNfACNQhlqJqBGGiP", "pjVubXMaWzald8kP2TNn" |
| `status` | string | ✓ | 100.0% | "unpaid", "paid" |
| `title` | string | ✓ | 100.0% | "قسط شهري", "إيجار العيادة" |
| `updatedAt` | null | string | ✓ | 100.0% | "2025-05-15T14:52:34.674755" |
| `updatedBy` | null | string | ✓ | 100.0% | "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1" |
| `userId` | string | ✓ | 100.0% | "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1", "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1" |

### Sample Document Structure

```json
{
  "amount": "6000",
  "createdAt": "\"2025-05-09T23:55:54.930540\"",
  "createdBy": "\"ktmgVQ0iJdN2WzhnPCWS4MC4rRz1\"",
  "currencyProfileId": "\"HZaqCFCKlfJTfucR9DN4\"",
  "deletedAt": "null",
  "deletedBy": "null",
  "description": "\"هذه الفاتورة تمثل القسط الشهري لجاز ال ITO\"",
  "dueDate": "\"2025-05-01T00:00:00.000\"",
  "id": "\"CX18F14KxhaN3yPQVZbS\"",
  "payedAt": "\"2025-05-15T14:52:34.673461\""
}
```

---

## evaluations

**Document Count:** 46

### Fields

| Field Name | Type | Required | Frequency | Sample Values |
|------------|------|----------|-----------|---------------|
| `createdAt` | string | ✓ | 100.0% | "2025-04-25T16:40:01.000", "2025-04-25T16:40:01.000" |
| `createdBy` | string | ✓ | 100.0% | "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1", "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1" |
| `deletedAt` | null | ✓ | 100.0% |  |
| `deletedBy` | null | ✓ | 100.0% |  |
| `endDateTime` | string | ✓ | 100.0% | "2024-10-11T02:00:00.000", "2024-11-18T18:00:00.000" |
| `id` | string | ✓ | 100.0% | "3ceJkdl1QT0yyu8Hq9gV", "6YAeApeq4rhN62yWoFo5" |
| `patientId` | string | ✓ | 100.0% | "rIQXZFrAymobATSxJqtI", "i40OJnEebwCAa4fDA98t" |
| `price` | number | ✓ | 100.0% | 120, 120 |
| `startDateTime` | string | ✓ | 100.0% | "2024-10-11T01:00:00.000", "2024-11-18T17:00:00.000" |
| `updatedAt` | null | ✓ | 100.0% |  |
| `updatedBy` | null | ✓ | 100.0% |  |
| `userId` | string | ✓ | 100.0% | "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1", "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1" |

### Sample Document Structure

```json
{
  "createdAt": "\"2025-04-25T16:40:01.000\"",
  "createdBy": "\"ktmgVQ0iJdN2WzhnPCWS4MC4rRz1\"",
  "deletedAt": "null",
  "deletedBy": "null",
  "endDateTime": "\"2024-10-11T02:00:00.000\"",
  "id": "\"3ceJkdl1QT0yyu8Hq9gV\"",
  "patientId": "\"rIQXZFrAymobATSxJqtI\"",
  "price": "120",
  "startDateTime": "\"2024-10-11T01:00:00.000\"",
  "updatedAt": "null"
}
```

---

## invoices

**Document Count:** 886

### Fields

| Field Name | Type | Required | Frequency | Sample Values |
|------------|------|----------|-----------|---------------|
| `amount` | number | ✓ | 100.0% | 200, 100 |
| `createdAt` | string | ✓ | 100.0% | "2024-09-25T23:00:00.000", "2024-08-20T15:00:00.000" |
| `createdBy` | string | ✓ | 100.0% | "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1", "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1" |
| `currencyProfileId` | string | ✓ | 100.0% | "38Ft2Q4TM0PwuUdZq8Q9", "38Ft2Q4TM0PwuUdZq8Q9" |
| `customerId` | string | ✓ | 100.0% | "yTZ1eeLfNmPdwY4hfe37", "V3nyBEKvwIb5AOSafalW" |
| `customerType` | string | ✓ | 100.0% | "patient", "patient" |
| `deletedAt` | null | ✓ | 100.0% |  |
| `deletedBy` | null | ✓ | 100.0% |  |
| `description` | string | ✓ | 100.0% | "Invoice for session with yTZ1eeLfNmPdwY4hfe37 a...", "Invoice for session with V3nyBEKvwIb5AOSafalW a..." |
| `dueDate` | string | ✓ | 100.0% | "2024-09-27T23:00:00.000", "2024-08-22T15:00:00.000" |
| `id` | string | ✓ | 100.0% | "0AYRuoqse1nJjBAAjyCL", "0BGvTgbAKFV6NDG1jCyi" |
| `issuedAt` | string | ✓ | 100.0% | "2024-09-25T23:00:00.000", "2024-08-20T15:00:00.000" |
| `referenceId` | string | ✓ | 100.0% | "sTvtQhXz8VdDVYnW03Rl", "g5oP2ACd482tJKW5kdRC" |
| `source` | string | ✓ | 100.0% | "sessions", "sessions" |
| `status` | string | ✓ | 100.0% | "paid", "paid" |
| `title` | string | ✓ | 100.0% | "Session Invoice", "Session Invoice" |
| `updatedAt` | null | ✓ | 100.0% |  |
| `updatedBy` | null | ✓ | 100.0% |  |
| `userId` | string | ✓ | 100.0% | "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1", "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1" |

### Sample Document Structure

```json
{
  "amount": "200",
  "createdAt": "\"2024-09-25T23:00:00.000\"",
  "createdBy": "\"ktmgVQ0iJdN2WzhnPCWS4MC4rRz1\"",
  "currencyProfileId": "\"38Ft2Q4TM0PwuUdZq8Q9\"",
  "customerId": "\"yTZ1eeLfNmPdwY4hfe37\"",
  "customerType": "\"patient\"",
  "deletedAt": "null",
  "deletedBy": "null",
  "description": "\"Invoice for session with yTZ1eeLfNmPdwY4hfe37 a...\"",
  "dueDate": "\"2024-09-27T23:00:00.000\""
}
```

---

## patients

**Document Count:** 100

### Fields

| Field Name | Type | Required | Frequency | Sample Values |
|------------|------|----------|-----------|---------------|
| `address` | string | null | ✓ | 100.0% | "جرجا - بني عيشي", "جرجا - الغباشي" |
| `age` | number | ✓ | 100.0% | 50, 47 |
| `alternativePhoneNumber` | null | string | ✓ | 96.0% | "01151410254", "01116559890" |
| `createdAt` | string | ✓ | 100.0% | "2025-04-16T23:30:28.986530", "2025-04-22T12:00:00Z" |
| `createdBy` | string | ✓ | 100.0% | "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1", "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1" |
| `gender` | string | ✓ | 100.0% | "Male", "Female" |
| `id` | string | ✓ | 100.0% | "05V94p9hSBtRQ628EWqK", "1XasqvOd57sENfaFCURL" |
| `name` | string | ✓ | 100.0% | "أحمد إمام", "ام البدرى اشرف نورالدين" |
| `occupation` | null | string | ✓ | 96.0% | "محاسب", "مدرسة لغة عربية" |
| `phoneNumber` | string | null | ✓ | 96.0% | "01", "01151410254" |
| `treatingDoctor` | null | string | ✓ | 96.0% | "ماجد عبدالناصر", "محمد رشاد" |
| `updatedAt` | string | null | ✓ | 98.0% | "2025-04-16T23:49:20.852835", "2025-04-13T00:01:19.694095" |
| `userId` | string | ✓ | 100.0% | "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1", "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1" |
| `deletedAt` | null |  | 94.0% |  |
| `deletedBy` | null |  | 94.0% |  |
| `updatedBy` | null |  | 94.0% |  |

### Sample Document Structure

```json
{
  "address": "\"جرجا - بني عيشي\"",
  "age": "50",
  "alternativePhoneNumber": "\"01151410254\"",
  "createdAt": "\"2025-04-16T23:30:28.986530\"",
  "createdBy": "\"ktmgVQ0iJdN2WzhnPCWS4MC4rRz1\"",
  "gender": "\"Male\"",
  "id": "\"05V94p9hSBtRQ628EWqK\"",
  "name": "\"أحمد إمام\"",
  "occupation": "\"محاسب\"",
  "phoneNumber": "\"01\""
}
```

---

## sessions

**Document Count:** 840

### Fields

| Field Name | Type | Required | Frequency | Sample Values |
|------------|------|----------|-----------|---------------|
| `createdAt` | string | ✓ | 100.0% | "2025-04-23T12:54:12.586Z", "2025-04-23T13:02:05.177Z" |
| `createdBy` | string | ✓ | 100.0% | "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1", "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1" |
| `endDateTime` | string | ✓ | 100.0% | "2024-10-04T00:00:00.000", "2024-09-16T01:00:00.000" |
| `id` | string | ✓ | 100.0% | "017NdDZaAKSmuFULpyCV", "04vL8unWJJMwmQY1lj18" |
| `patientId` | string | ✓ | 100.0% | "XNVpdKKscXjojFdFbRvP", "cvB0cNO3ksEHEUt54a9d" |
| `price` | number | ✓ | 100.0% | 100, 100 |
| `startDateTime` | string | ✓ | 100.0% | "2024-10-03T23:00:00.000", "2024-09-16T00:00:00.000" |
| `userId` | string | ✓ | 100.0% | "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1", "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1" |
| `deletedAt` | null |  | 20.8% |  |
| `deletedBy` | null |  | 20.8% |  |
| `sessionType` | string |  | 37.1% | "adultIntensive", "standard" |
| `updatedAt` | null | string |  | 20.8% | "2025-05-01T16:25:29.960857", "2025-05-01T16:25:45.950607" |
| `updatedBy` | null |  | 20.8% |  |

### Sample Document Structure

```json
{
  "createdAt": "\"2025-04-23T12:54:12.586Z\"",
  "createdBy": "\"ktmgVQ0iJdN2WzhnPCWS4MC4rRz1\"",
  "endDateTime": "\"2024-10-04T00:00:00.000\"",
  "id": "\"017NdDZaAKSmuFULpyCV\"",
  "patientId": "\"XNVpdKKscXjojFdFbRvP\"",
  "price": "100",
  "startDateTime": "\"2024-10-03T23:00:00.000\"",
  "userId": "\"ktmgVQ0iJdN2WzhnPCWS4MC4rRz1\"",
  "deletedAt": "null",
  "deletedBy": "null"
}
```

---

## transactions

**Document Count:** 887

### Fields

| Field Name | Type | Required | Frequency | Sample Values |
|------------|------|----------|-----------|---------------|
| `amount` | number | ✓ | 100.0% | 100, 100 |
| `createdAt` | string | ✓ | 100.0% | "2025-05-14T23:43:18.017885", "2025-05-14T23:44:32.501265" |
| `createdBy` | string | ✓ | 100.0% | "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1", "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1" |
| `currencyProfileId` | string | ✓ | 100.0% | "38Ft2Q4TM0PwuUdZq8Q9", "38Ft2Q4TM0PwuUdZq8Q9" |
| `deletedAt` | null | ✓ | 100.0% |  |
| `deletedBy` | null | ✓ | 100.0% |  |
| `description` | string | ✓ | 100.0% | "Full payment for invoice QmGZSVge2VUTOOlwAOIj", "Full payment for invoice 6w9NXJtSRBNYMZs6bAwS" |
| `direction` | string | ✓ | 100.0% | "in", "in" |
| `id` | string | ✓ | 100.0% | "005bf208-c067-4aa9-97fe-3b999642791f", "005c143a-0e5f-4dd1-872f-7f01aefe15a4" |
| `notes` | null | ✓ | 100.0% |  |
| `referenceId` | string | ✓ | 100.0% | "QmGZSVge2VUTOOlwAOIj", "6w9NXJtSRBNYMZs6bAwS" |
| `status` | string | ✓ | 100.0% | "Completed", "Completed" |
| `transactionDate` | string | ✓ | 100.0% | "2025-04-08T13:00:00.000", "2024-11-10T00:00:00.000" |
| `transactionSource` | string | ✓ | 100.0% | "invoice", "invoice" |
| `updatedAt` | null | ✓ | 100.0% |  |
| `updatedBy` | null | ✓ | 100.0% |  |
| `userId` | string | ✓ | 100.0% | "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1", "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1" |

### Sample Document Structure

```json
{
  "amount": "100",
  "createdAt": "\"2025-05-14T23:43:18.017885\"",
  "createdBy": "\"ktmgVQ0iJdN2WzhnPCWS4MC4rRz1\"",
  "currencyProfileId": "\"38Ft2Q4TM0PwuUdZq8Q9\"",
  "deletedAt": "null",
  "deletedBy": "null",
  "description": "\"Full payment for invoice QmGZSVge2VUTOOlwAOIj\"",
  "direction": "\"in\"",
  "id": "\"005bf208-c067-4aa9-97fe-3b999642791f\"",
  "notes": "null"
}
```

---

## users

**Document Count:** 1

### Fields

| Field Name | Type | Required | Frequency | Sample Values |
|------------|------|----------|-----------|---------------|
| `accessToken` | string | ✓ | 100.0% | "ya29.a0AZYkNZhO-l8xbmQTz3obolReRRYmIZ9YVn3OVL6M..." |
| `displayName` | string | ✓ | 100.0% | "Nour Center" |
| `email` | string | ✓ | 100.0% | "nourrehabcenter@gmail.com" |
| `emailVerified` | boolean | ✓ | 100.0% | true |
| `id` | string | ✓ | 100.0% | "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1" |
| `idToken` | string | ✓ | 100.0% | "eyJhbGciOiJSUzI1NiIsImtpZCI6IjIzZjdhMzU4Mzc5NmY..." |
| `metadata` | object | ✓ | 100.0% | {2 fields} |
| `phoneNumber` | string | ✓ | 100.0% | "" |
| `photoURL` | string | ✓ | 100.0% | "https://lh3.googleusercontent.com/a/ACg8ocKZqLE..." |
| `providerData` | array | ✓ | 100.0% | [0 items] |
| `uid` | string | ✓ | 100.0% | "ktmgVQ0iJdN2WzhnPCWS4MC4rRz1" |

### Sample Document Structure

```json
{
  "accessToken": "\"ya29.a0AZYkNZhO-l8xbmQTz3obolReRRYmIZ9YVn3OVL6M...\"",
  "displayName": "\"Nour Center\"",
  "email": "\"nourrehabcenter@gmail.com\"",
  "emailVerified": "true",
  "id": "\"ktmgVQ0iJdN2WzhnPCWS4MC4rRz1\"",
  "idToken": "\"eyJhbGciOiJSUzI1NiIsImtpZCI6IjIzZjdhMzU4Mzc5NmY...\"",
  "metadata": "{2 fields}",
  "phoneNumber": "\"\"",
  "photoURL": "\"https://lh3.googleusercontent.com/a/ACg8ocKZqLE...\"",
  "providerData": "[0 items]"
}
```

---

## Notes

- **Required**: Fields present in 95% or more of documents
- **Frequency**: Percentage of documents containing this field
- **Type**: Inferred from document data (may include union types)
