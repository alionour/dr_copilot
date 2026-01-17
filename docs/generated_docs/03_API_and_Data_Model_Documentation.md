# API and Data Model Documentation

This document describes the Firestore data models used in the Dr. Copilot application.

**Note:** This is an inferred data model based on the source code. The actual data model in Firestore might have slight variations.

## Data Models

### EvaluationModel

| Field | Type | Description |
| --- | --- | --- |
| id | String | The unique identifier for the evaluation. |
| patientId | String | The ID of the patient being evaluated. |
| patientName | String | The name of the patient. |
| price | double | The price of the evaluation. |
| startDateTime | Timestamp | The start date and time of the evaluation. |
| endDateTime | Timestamp | The end date and time of the evaluation. |
| ownerId | String | The ID of the owner of the record. |
| clinicId | String | The ID of the clinic where the evaluation took place. |
| createdBy | String | The ID of the user who created the evaluation. |
| updatedBy | String? | The ID of the user who last updated the evaluation. |
| deletedBy | String? | The ID of the user who deleted the evaluation. |
| createdAt | Timestamp | The timestamp when the evaluation was created. |
| updatedAt | Timestamp? | The timestamp when the evaluation was last updated. |
| deletedAt | Timestamp? | The timestamp when the evaluation was deleted. |
| doctorId | String? | The ID of the doctor who performed the evaluation. |

---

### SessionModel

| Field | Type | Description |
| --- | --- | --- |
| id | String | The unique identifier for the session. |
| patientId | String | The ID of the patient for the session. |
| price | double | The price of the session. |
| startDateTime | Timestamp | The start date and time of the session. |
| endDateTime | Timestamp | The end date and time of the session. |
| sessionType | SessionType? | The type of the session (e.g., Pediatric Intensive, Adult Intensive). |
| ownerId | String | The ID of the owner of the record. |
| clinicId | String | The ID of the clinic where the session took place. |
| createdBy | String | The ID of the user who created the session. |
| patientName | String? | The name of the patient. |
| updatedBy | String? | The ID of the user who last updated the session. |
| deletedBy | String? | The ID of the user who deleted the session. |
| deletedAt | Timestamp? | The timestamp when the session was deleted. |
| createdAt | Timestamp | The timestamp when the session was created. |
| updatedAt | Timestamp? | The timestamp when the session was last updated. |
| doctorId | String? | The ID of the doctor for the session. |

---

### ClinicModel

| Field | Type | Description |
| --- | --- | --- |
| id | String | The unique identifier for the clinic. |
| name | String | The name of the clinic. |
| location | String? | The location of the clinic. |
| ownerId | String | The ID of the owner of the clinic. |
| adminEmail | String | The email of the clinic's administrator. |
| createdAt | Timestamp? | The timestamp when the clinic was created. |

---

### UserModel

| Field | Type | Description |
| --- | --- | --- |
| uid | String | The user's unique ID from Firebase Authentication. |
| displayName | String? | The user's display name. |
| email | String? | The user's email address. |
| emailVerified | bool? | Whether the user's email address has been verified. |
| isAnonymous | bool? | Whether the user is an anonymous user. |
| metadata | dynamic | Additional metadata about the user. |
| phoneNumber | String? | The user's phone number. |
| photoURL | String? | The URL of the user's profile picture. |
| providerData | List<dynamic>? | A list of provider-specific data for the user. |
| refreshToken | String? | The user's refresh token. |
| tenantId | String? | The user's tenant ID. |
| ownerId | String? | The ID of the owner of the user record. |
| permissions | List<AppPermission> | The list of permissions assigned to the user. |
| roles | List<AppRole> | The list of roles assigned to the user. |
| clinicIds | List<String>? | The IDs of the clinics the user has access to. |
| primaryClinicId | String? | The ID of the user's primary clinic. |

---

### CopilotModel

| Field | Type | Description |
| --- | --- | --- |
| id | String | The unique identifier for the copilot. |
| name | String | The name of the copilot. |
| role | String | The role of the copilot. |

---

### DoctorModel

| Field | Type | Description |
| --- | --- | --- |
| id | String | The unique identifier for the doctor. |
| name | String | The name of the doctor. |
| specialty | String | The specialty of the doctor. |
| clinicId | String | The ID of the clinic the doctor belongs to. |
| email | String | The email address of the doctor. |
| phoneNumber | String | The phone number of the doctor. |
| createdAt | Timestamp | The timestamp when the doctor was added. |
| updatedAt | Timestamp | The timestamp when the doctor's information was last updated. |

---

### BillModel

| Field | Type | Description |
| --- | --- | --- |
| id | String | The unique identifier for the bill. |
| ownerId | String | The ID of the owner of the record. |
| clinicId | String | The ID of the clinic this bill belongs to. |
| scheduledBillId | String? | The ID of the scheduled bill this bill was generated from. |
| title | String | The title of the bill. |
| description | String | The description of the bill. |
| amount | double | The amount of the bill. |
| currencyProfileId | String | The ID of the currency profile used for this bill. |
| dueDate | Timestamp | The due date of the bill. |
| status | BillStatus | The status of the bill (e.g., unpaid, paid, partiallyPaid). |
| paymentMethod | PaymentMethod? | The payment method used for this bill. |
| payedAt | Timestamp? | The timestamp when the bill was paid. |
| createdAt | Timestamp | The timestamp when the bill was created. |
| updatedAt | Timestamp? | The timestamp when the bill was last updated. |
| deletedAt | Timestamp? | The timestamp when the bill was deleted. |
| createdBy | String | The ID of the user who created the bill. |
| updatedBy | String? | The ID of the user who last updated the bill. |
| deletedBy | String? | The ID of the user who deleted the bill. |

---

### CurrencyProfileModel

| Field | Type | Description |
| --- | --- | --- |
| id | String | The unique identifier for the currency profile. |
| currency | String | The currency code (e.g., USD, EUR). |
| name | String | The name of the currency profile. |
| description | String? | The description of the currency profile. |
| createdAt | Timestamp | The timestamp when the currency profile was created. |
| updatedAt | Timestamp? | The timestamp when the currency profile was last updated. |
| deletedAt | Timestamp? | The timestamp when the currency profile was deleted. |
| createdBy | String | The ID of the user who created the currency profile. |
| updatedBy | String? | The ID of the user who last updated the currency profile. |
| deletedBy | String? | The ID of the user who deleted the currency profile. |

---

### GoalModel

This feature has three types of goal models: `CountGoalModel`, `AmountGoalModel`, and `CustomGoalModel`, all inheriting from `GoalModelBase`.

#### GoalModelBase (Abstract)

| Field | Type | Description |
| --- | --- | --- |
| id | String | The unique identifier for the goal. |
| title | String | The title of the goal. |
| description | String? | The description of the goal. |
| goalType | GoalType | The type of the goal. |
| color | int | The color associated with the goal. |
| createdAt | Timestamp | The timestamp when the goal was created. |
| updatedAt | Timestamp? | The timestamp when the goal was last updated. |
| deletedAt | Timestamp? | The timestamp when the goal was deleted. |
| createdBy | String | The ID of the user who created the goal. |
| updatedBy | String? | The ID of the user who last updated the goal. |
| deletedBy | String? | The ID of the user who deleted the goal. |
| year | int? | The year for which the goal is set. |
| month | int? | The month for which the goal is set. |

#### CountGoalModel

| Field | Type | Description |
| --- | --- | --- |
| targetCount | int | The target count for the goal. |

#### AmountGoalModel

| Field | Type | Description |
| --- | --- | --- |
| targetAmount | double | The target amount for the goal. |

#### CustomGoalModel

| Field | Type | Description |
| --- | --- | --- |
| metricName | String | The name of the custom metric. |
| targetValue | double | The target value for the custom metric. |
| isMonthBased | bool | Whether the custom goal is month-based. |
| isYearBased | bool | Whether the custom goal is year-based. |

---

### InvoiceModel

| Field | Type | Description |
| --- | --- | --- |
| id | String | The unique identifier for the invoice. |
| ownerId | String | The ID of the owner of the record. |
| clinicId | String | The ID of the clinic this invoice belongs to. |
| title | String | The title of the invoice. |
| description | String | The description of the invoice. |
| amount | double | The amount of the invoice. |
| currencyProfileId | String | The ID of the currency profile used for this invoice. |
| issuedAt | Timestamp | The timestamp when the invoice was issued. |
| createdAt | Timestamp | The timestamp when the invoice was created. |
| updatedAt | Timestamp? | The timestamp when the invoice was last updated. |
| deletedAt | Timestamp? | The timestamp when the invoice was deleted. |
| createdBy | String | The ID of the user who created the invoice. |
| updatedBy | String? | The ID of the user who last updated the invoice. |
| deletedBy | String? | The ID of the user who deleted the invoice. |
| dueDate | Timestamp | The due date of the invoice. |
| customerId | String? | The ID of the customer. |
| customerType | CustomerType? | The type of the customer (e.g., patient, organization). |
| source | InvoiceSource? | The source of the invoice (e.g., sessions, evaluations). |
| status | InvoiceStatus? | The status of the invoice (e.g., unpaid, paid). |
| referenceId | String | The ID of the session or evaluation this invoice is for. |

---

### ScheduledBillModel

| Field | Type | Description |
| --- | --- | --- |
| id | String | The unique identifier for the scheduled bill. |
| title | String | The title of the scheduled bill. |
| description | String | The description of the scheduled bill. |
| amount | double | The amount of the scheduled bill. |
| currencyProfileId | String | The ID of the currency profile used for this bill. |
| type | ScheduledBillType | The type of the scheduled bill (income or expense). |
| scheduledAt | Timestamp | The timestamp when the bill is scheduled to be generated. |
| createdAt | Timestamp | The timestamp when the scheduled bill was created. |
| updatedAt | Timestamp? | The timestamp when the scheduled bill was last updated. |
| deletedAt | Timestamp? | The timestamp when the scheduled bill was deleted. |
| createdBy | String | The ID of the user who created the scheduled bill. |
| updatedBy | String? | The ID of the user who last updated the scheduled bill. |
| deletedBy | String? | The ID of the user who deleted the scheduled bill. |
| recurrence | ScheduledBillRecurrence | The recurrence frequency of the scheduled bill. |

---

### TransactionModel

| Field | Type | Description |
| --- | --- | --- |
| id | String | The unique identifier for the transaction. |
| amount | double | The monetary value of the transaction. |
| description | String | A brief description or note about the transaction. |
| transactionDate | Timestamp | The date and time when the transaction occurred. |
| transactionSource | TransactionSource | The source of the transaction (e.g., invoice, bill). |
| direction | TransactionDirection | The direction of the transaction (inwards or outwards). |
| createdAt | Timestamp | The timestamp when the transaction was created. |
| deletedAt | Timestamp? | The timestamp when the transaction was deleted. |
| updatedAt | Timestamp? | The timestamp when the transaction was last updated. |
| ownerId | String | The ID of the user associated with the transaction. |
| clinicId | String | The ID of the clinic associated with the transaction. |
| createdBy | String? | The ID of the user who created the transaction. |
| deletedBy | String? | The ID of the user who deleted the transaction. |
| updatedBy | String? | The ID of the user who last updated the transaction. |
| currencyProfileId | String? | The ID of the currency profile used for this transaction. |
| notes | String? | Additional notes or comments about the transaction. |
| status | TransactionStatus? | The status of the transaction (e.g., pending, completed, failed). |
| referenceId | String | A reference to an external system or invoice. |

---

### AssistantActionModel

| Field | Type | Description |
| --- | --- | --- |
| id | String | The unique identifier for the assistant action. |
| sessionId | String | The ID of the voice session this action belongs to. |
| actionType | AssistantActionType | The type of action the assistant can perform. |
| status | ActionExecutionStatus | The execution status of the action. |
| description | String | A description of the action. |
| parameters | Map<String, dynamic> | The parameters required for the action. |
| result | Map<String, dynamic>? | The result of the action execution. |
| errorMessage | String? | An error message if the action failed. |
| createdAt | DateTime | The timestamp when the action was created. |
| executedAt | DateTime? | The timestamp when the action was executed. |
| completedAt | DateTime? | The timestamp when the action was completed. |
| requiresConfirmation | bool | Whether the action requires user confirmation before execution. |
| isConfirmed | bool | Whether the user has confirmed the action. |

---

### VoiceMessageModel

| Field | Type | Description |
| --- | --- | --- |
| id | String | The unique identifier for the voice message. |
| sessionId | String | The ID of the voice session this message belongs to. |
| content | String | The text content of the message. |
| audioPath | String? | The path to the audio file of the message. |
| audioDuration | double? | The duration of the audio in seconds. |
| type | MessageType | The type of the message (e.g., userVoice, assistantText). |
| status | VoiceMessageStatus | The status of the voice message. |
| timestamp | Timestamp | The timestamp when the message was created. |
| actionType | String? | The type of action associated with the message. |
| actionData | Map<String, dynamic>? | The data for the action associated with the message. |
| errorMessage | String? | An error message if the message processing failed. |
| isProcessing | bool | Whether the message is currently being processed. |

---

### VoiceSessionModel

| Field | Type | Description |
| --- | --- | --- |
| id | String | The unique identifier for the voice session. |
| userId | String | The ID of the user who started the session. |
| title | String? | The title of the voice session. |
| status | VoiceSessionStatus | The status of the voice session. |
| startTime | Timestamp | The timestamp when the session started. |
| endTime | Timestamp? | The timestamp when the session ended. |
| messages | List<VoiceMessageModel> | The list of messages in the session. |
| context | Map<String, dynamic> | The context of the conversation. |
| selectedAiModel | String? | The selected AI model for the session. |
| isActive | bool | Whether the session is currently active. |
| messageCount | int | The number of messages in the session. |
| totalDuration | double? | The total duration of the session in minutes. |

---

### PatientModel

| Field | Type | Description |
| --- | --- | --- |
| id | String | The unique identifier for the patient. |
| name | String | The name of the patient. |
| age | int? | The age of the patient. |
| gender | String? | The gender of the patient. |
| address | String? | The address of the patient. |
| ownerId | String | The ID of the owner of the record. |
| clinicId | String | The ID of the clinic the patient belongs to. |
| phoneNumber | String? | The phone number of the patient. |
| alternativePhoneNumber | String? | An alternative phone number for the patient. |
| treatingDoctor | String? | The name of the treating doctor. |
| occupation | String? | The occupation of the patient. |
| createdAt | Timestamp? | The timestamp when the patient was added. |
| updatedAt | Timestamp? | The timestamp when the patient's information was last updated. |
| createdBy | String? | The ID of the user who created the patient record. |
| updatedBy | String? | The ID of the user who last updated the patient record. |
| deletedBy | String? | The ID of the user who deleted the patient record. |
| deletedAt | Timestamp? | The timestamp when the patient record was deleted. |

---

### StaffModel

| Field | Type | Description |
| --- | --- | --- |
| id | String | The unique identifier for the staff member. |
| name | String | The name of the staff member. |
| email | String? | The email address of the staff member. |
| phoneNumber | String? | The phone number of the staff member. |
| role | String | The role of the staff member. |
| clinicId | String | The ID of the clinic the staff member belongs to. |
| createdAt | DateTime? | The timestamp when the staff member was added. |
| updatedAt | DateTime? | The timestamp when the staff member's information was last updated. |



