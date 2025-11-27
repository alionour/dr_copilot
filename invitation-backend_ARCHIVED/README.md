# Dr. Copilot - Invitation Email Backend

This backend service is a serverless AWS Lambda function designed to send invitation emails to new users using Amazon Simple Email Service (SES).

It is intended to be triggered via an HTTP POST request from an AWS API Gateway endpoint.

## Prerequisites

1.  **AWS Account**: You need an active AWS account.
2.  **Node.js**: Make sure you have Node.js and `npm` installed to install dependencies.
3.  **Amazon SES Setup**:
    *   You must have a **verified identity** (email address or domain) in Amazon SES. This is the email address that will be used to send invitations.
    *   For development, your SES account might be in the "sandbox" environment, which means you can only send emails *to* other verified email addresses. You will need to verify the recipient's email address in the SES console for testing.
    *   To send emails to anyone, you must [request to be moved out of the SES sandbox](https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html).

## 1. Local Setup

From within the `invitation-backend` directory, install the required dependencies:

```bash
npm install
```

## 2. Deployment to AWS Lambda

This guide assumes you are using the AWS Management Console.

### Step 2.1: Create the IAM Role

1.  Navigate to **IAM > Roles** in the AWS Console and click **Create role**.
2.  Select **AWS service** as the trusted entity type.
3.  Choose **Lambda** as the use case.
4.  On the "Add permissions" page, search for and add the `AmazonSESFullAccess` policy. Also add the `AWSLambdaBasicExecutionRole` policy for logging.
5.  Give the role a name (e.g., `DrCopilotInvitationLambdaRole`) and create it.

### Step 2.2: Create the Lambda Function

1.  Navigate to **Lambda** in the AWS Console and click **Create function**.
2.  Choose **Author from scratch**.
3.  **Function name**: `dr-copilot-send-invitation-email`
4.  **Runtime**: `Node.js 18.x` or a later version.
5.  **Architecture**: `x86_64`
6.  **Permissions**: Choose "Use an existing role" and select the IAM role you created in the previous step (`DrCopilotInvitationLambdaRole`).
7.  Click **Create function**.

### Step 2.3: Package and Upload the Code

1.  From your local `invitation-backend` directory, create a `.zip` file containing `index.js`, `package.json`, and the `node_modules` directory.
    *   **On macOS/Linux:** `zip -r function.zip .`
    *   **On Windows (PowerShell):** `Compress-Archive -Path * -DestinationPath function.zip -Force`
2.  In the Lambda function console, under the **Code source** tab, click **Upload from**.
3.  Select **.zip file** and upload your `function.zip` file.

### Step 2.4: Configure the Lambda Function

1.  Go to the **Configuration > Environment variables** tab.
2.  Click **Edit** and add the following environment variables:
    *   `SES_FROM_EMAIL`: The verified email address you configured in Amazon SES (e.g., `no-reply@yourdomain.com`).
    *   `APP_URL`: The URL where users will sign up. This link will be included in the email (e.g., `https://your-app-url.com/signup`).

### Step 2.5: Create the API Gateway Trigger

1.  In the Lambda function console, go to the **Function overview** and click **Add trigger**.
2.  Select **API Gateway** from the list.
3.  Choose **Create an API**.
4.  Select **HTTP API** for the API type.
5.  **Security**: For simplicity, you can choose **Open**. For a production app, you should configure authorization (e.g., IAM or JWT).
6.  Click **Add**.
7.  After the trigger is created, it will show an **API endpoint URL**. This is the URL you will need to call from the Flutter app.

## 3. Usage

Make an HTTP `POST` request to the API endpoint URL you just created.

**Endpoint:** `[Your API Gateway Endpoint URL]`
**Method:** `POST`
**Headers:**
```json
{
  "Content-Type": "application/json"
}
```

**Body Payload:**
The body must be a JSON object with the following fields:

```json
{
  "recipientEmail": "invited.user@example.com",
  "recipientName": "Jane Doe",
  "clinicName": "Sunshine Pediatrics",
  "role": "Doctor"
}
```

A successful request will return a `200 OK` status with a confirmation message.
