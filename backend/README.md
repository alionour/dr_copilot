# Dr. Copilot - Unified Backend

This backend service is a serverless Express.js application that handles various features for the Dr. Copilot app, including:
-   **/invitations**: Sending invitation emails via Amazon SES.
-   **/notifications**: Sending push notifications via Firebase Cloud Messaging (FCM).

The application is designed to be deployed as a single AWS Lambda function fronted by an API Gateway.

## Prerequisites

1.  **AWS Account**: You need an active AWS account.
2.  **Node.js**: Ensure `v18.x` or later is installed.
3.  **Serverless Framework**: You need the Serverless Framework CLI installed globally. This simplifies deployment significantly.
    ```bash
    npm install -g serverless
    ```
4.  **AWS Credentials**: Configure your local environment with AWS credentials. The easiest way is to use the AWS CLI:
    ```bash
    aws configure
    ```
5.  **Firebase Service Account**: You need a Firebase service account JSON file to allow the backend to interact with Firebase services (like Firestore and FCM).
6.  **Amazon SES Verified Identity**: You must have a verified email address or domain in Amazon SES to send emails from.

## 1. Configuration

The backend requires several environment variables to run. The `serverless.yml` file is configured to read these from your environment.

### Create a `.env` file

Create a file named `.env` in the `backend` directory. **This file should not be committed to source control.**

```
# .env

# --- Firebase ---
# Paste the entire content of your Firebase service account JSON file here,
# then process it to be a single-line string.
# macOS/Linux: FIREBASE_SERVICE_ACCOUNT=$(cat /path/to/your/service-account.json | jq -c .)
# Windows: You will need to manually convert the JSON to a single line.
FIREBASE_SERVICE_ACCOUNT='{"type":"service_account", "project_id":"...", ...}'

# --- Amazon SES ---
# The email address you have verified in Amazon SES
SES_FROM_EMAIL="no-reply@your-domain.com"

# --- Application ---
# The public URL of your application, used for links in emails
APP_URL="https://app.drcopilot.ai"
```

**Important**: Make sure your `FIREBASE_SERVICE_ACCOUNT` JSON is a single line. You can use an online tool to minify the JSON if you are on Windows.

## 2. Local Development

1.  **Install Dependencies**:
    ```bash
    npm install
    ```
2.  **Run Locally**: To test the server on your local machine, you can create a small `local.js` file (this is not included in the deployment).

    *Create `local.js`:*
    ```javascript
    // This file is for local testing only and should not be deployed.
    require('dotenv').config(); // Use dotenv to load .env file
    const app = require('./index').app; // Assuming index.js exports 'app'
    
    const port = 3000;
    app.listen(port, () => {
        console.log(`Server listening at http://localhost:${port}`);
    });
    ```
    *You will need to install `dotenv`: `npm install dotenv`*
    *You also need to modify `index.js` to export the `app` for local testing.*
    *Change `module.exports.handler = serverless(app);` to:*
    ```javascript
    module.exports.handler = serverless(app);
    module.exports.app = app; // Export for local testing
    ```

    *Then run:*
    ```bash
    node local.js
    ```

## 3. Deployment

Deploying with the Serverless Framework is a single command. From the `backend` directory:

```bash
serverless deploy
```

This command will:
1.  Package your application code and dependencies.
2.  Create a CloudFormation stack in your AWS account.
3.  Create the Lambda function, API Gateway, and all necessary IAM roles.
4.  Configure the environment variables.
5.  Output the final API endpoint URL.

After deployment is complete, you will see an `endpoints` section in the output. This is the base URL for your backend API.

## API Endpoints

### Send Invitation

-   **Endpoint**: `POST /invitations`
-   **Description**: Sends an invitation email to a user.
-   **Body**:
    ```json
    {
      "recipientEmail": "invited.user@example.com",
      "recipientName": "Jane Doe",
      "clinicName": "Sunshine Pediatrics",
      "role": "Doctor"
    }
    ```

### Send Notification

-   **Endpoint**: `POST /notifications`
-   **Description**: Sends a push notification to a user via FCM.
-   **Body**:
    ```json
    {
      "userId": "some-user-id-from-firestore",
      "title": "New Appointment",
      "message": "You have a new appointment at 2:00 PM."
    }
    ```
