# Billing System Summary

## 1. Income Bills (Invoices)
- **Standard Name:** Invoice
- **Purpose:** Money owed to you (from clients/patients for sessions, evaluations, etc.)
- **Collection/Table Name:** `invoices`
- **Direction:** In

## 2. Expense Bills (Payables)
- **Standard Name:** Bill
- **Purpose:** Money you owe to others (utilities, rent, suppliers, etc.)
- **Collection/Table Name:** `bills`
- **Direction:** Out

## 3. Transactions
- **Standard Name:** Transaction
- **Purpose:** Any money movement, both incoming and outgoing (payments received, payments made, refunds, etc.)
- **Collection/Table Name:** `transactions`
- **Direction:** In/Out (should have a `type` or `direction` field)

---

## Standard Workflow

| Event                | Record Created | Type/Direction | Status/Effect         |
|----------------------|---------------|----------------|-----------------------|
| Service provided     | Invoice       | In             | Invoice is "unpaid"   |
| Payment received     | Transaction   | In             | Invoice is "paid" or "partially paid" |
| Receive utility bill | Bill          | Out            | Bill is "unpaid"      |
| Pay the bill         | Transaction   | Out            | Bill is "paid" or "partially paid" |

---

## Detailed Workflow Explanation

### 1. When a Service is Provided (Session/Evaluation)
- The system creates an **invoice** (income bill) for the client/patient, representing the amount they owe for the service.
- The invoice is marked as **unpaid** until payment is received.
- This allows you to track all expected income, even if it hasn't been paid yet.

### 2. When a Payment is Received
- The system creates a **transaction** (type: "in") for the amount received.
- The transaction references the related invoice.
- The invoice status is updated:
  - If the payment covers the full amount, the invoice is marked as **paid**.
  - If the payment is partial, the invoice is marked as **partially paid** and the remaining balance is tracked.
- If no payment is made, the invoice remains **unpaid** and no transaction is created.

### 3. When an Expense Bill is Received (e.g., Utilities)
- The system creates a **bill** (expense bill) for the amount you owe to a vendor or service provider.
- The bill is marked as **unpaid** until you make a payment.
- This allows you to track all expected expenses, even if you haven't paid them yet.

### 4. When an Expense is Paid
- The system creates a **transaction** (type: "out") for the amount paid.
- The transaction references the related bill.
- The bill status is updated:
  - If the payment covers the full amount, the bill is marked as **paid**.
  - If the payment is partial, the bill is marked as **partially paid** and the remaining balance is tracked.
- If no payment is made, the bill remains **unpaid** and no transaction is created.

---

## Example Scenarios

### Example 1: Patient Session
1. Dr. Smith completes a session for John Doe.
2. The system creates an invoice for $100, status: "unpaid".
3. John Doe pays $100.
4. The system creates a transaction (type: "in") for $100, linked to the invoice.
5. The invoice status is updated to "paid".

### Example 2: Utility Bill
1. The clinic receives an electricity bill for $200.
2. The system creates a bill for $200, status: "unpaid".
3. The clinic pays $200.
4. The system creates a transaction (type: "out") for $200, linked to the bill.
5. The bill status is updated to "paid".

### Example 3: Partial Payment
1. An invoice is created for $300.
2. The client pays $100.
3. A transaction (type: "in") for $100 is created and linked to the invoice.
4. The invoice status is updated to "partially paid" with $200 remaining.

### Example 4: Advance Payment
1. A client pays $500 in advance.
2. The system creates a transaction (type: "in", status: "advance") for $500.
3. When a service is provided, the advance is applied to the invoice.
4. The invoice status is updated based on how much of the advance is used.

---

## Key Points
- **Invoices** track what is owed to you (expected income).
- **Bills** track what you owe (expected expenses).
- **Transactions** track actual money movement (income and expenses).
- Always distinguish between "in" and "out" using a field or separate models/collections.
- Advance payments can be handled as "in" transactions with a special status, and applied to invoices as needed.
- This separation allows you to track outstanding balances, overdue payments, and reconcile your accounts.

---

## Why Use This Structure?
- **Clarity:** Easily see what is owed to you and what you owe.
- **Reporting:** Generate income/expense reports, track cash flow, and calculate profit/loss.
- **Auditability:** Maintain a clear record of all financial activity for compliance and review.
- **Scalability:** This structure supports complex workflows like partial payments, refunds, and advance payments.

---

This structure is standard in accounting and business software, and will make your system robust, auditable, and easy to maintain.
