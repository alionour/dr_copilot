const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");

// Create an SES client
// The AWS SDK for JavaScript v3 automatically uses environment variables for configuration.
// Ensure AWS_REGION, AWS_ACCESS_KEY_ID, and AWS_SECRET_ACCESS_KEY are set in the Lambda environment.
const sesClient = new SESClient({});

/**
 * AWS Lambda handler for sending invitation emails via Amazon SES.
 *
 * @param {Object} event - API Gateway Lambda Proxy Input Format.
 * @returns {Object} - API Gateway Lambda Proxy Output Format.
 */
exports.handler = async (event) => {
  // CORS headers to allow requests from any origin
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json'
  };

  // Handle preflight OPTIONS request for CORS
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: ''
    };
  }
  
  // --- Environment Variable Checks ---
  const { SES_FROM_EMAIL, APP_URL } = process.env;
  if (!SES_FROM_EMAIL || !APP_URL) {
      const missingVars = [!SES_FROM_EMAIL && "SES_FROM_EMAIL", !APP_URL && "APP_URL"].filter(Boolean).join(", ");
      console.error(`Configuration error: Missing environment variables: ${missingVars}`);
      return {
          statusCode: 500,
          headers,
          body: JSON.stringify({ error: `Server is misconfigured. Missing: ${missingVars}` }),
      };
  }


  // --- Request Body Parsing and Validation ---
  let body;
  try {
    body = JSON.parse(event.body || '{}');
  } catch (parseError) {
    console.error('Invalid JSON in request body:', parseError);
    return {
      statusCode: 400,
      headers,
      body: JSON.stringify({
        error: 'Invalid JSON in request body',
        message: parseError.message
      })
    };
  }

  const { recipientEmail, recipientName, clinicName, role } = body;

  if (!recipientEmail || !clinicName || !role) {
    const missingFields = [!recipientEmail && "recipientEmail", !clinicName && "clinicName", !role && "role"].filter(Boolean).join(", ");
    return {
      statusCode: 400,
      headers,
      body: JSON.stringify({
        error: `Missing required fields: ${missingFields}`
      })
    };
  }

  // --- Email Content Creation ---
  const subject = `You're invited to join ${clinicName} on Dr. Copilot`;
  
  // A simple but clean HTML email template
  const createHtmlBody = () => `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Dr. Copilot Invitation</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 20px auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px; }
            .header { font-size: 24px; font-weight: bold; text-align: center; color: #4A90E2; }
            .content { margin-top: 20px; }
            .button { display: inline-block; padding: 12px 24px; margin: 20px 0; background-color: #4A90E2; color: #fff; text-decoration: none; border-radius: 5px; font-weight: bold; }
            .footer { margin-top: 20px; font-size: 12px; color: #777; text-align: center; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">Dr. Copilot</div>
            <div class="content">
                <h2>You're Invited!</h2>
                <p>Hello ${recipientName || ''},</p>
                <p>You have been invited to join <strong>${clinicName}</strong> on the Dr. Copilot platform with the role of <strong>${role}</strong>.</p>
                <p>Click the button below to accept the invitation and create your account. Please be sure to sign up using this email address (${recipientEmail}).</p>
                <a href="${APP_URL}" class="button">Accept Invitation & Sign Up</a>
                <p>If you have any questions, please contact your clinic administrator.</p>
                <p>Thank you,<br>The Dr. Copilot Team</p>
            </div>
            <div class="footer">
                If you did not expect this invitation, you can safely ignore this email.
            </div>
        </div>
    </body>
    </html>
  `;
  
  const htmlBody = createHtmlBody();
  
  // A plain text version for email clients that don't support HTML
  const textBody = `
    Hello ${recipientName || ''},
    
    You have been invited to join ${clinicName} on the Dr. Copilot platform with the role of ${role}.
    
    Please visit the following URL to accept the invitation and create your account. Be sure to sign up using this email address (${recipientEmail}).
    
    Sign-up Link: ${APP_URL}
    
    Thank you,
    The Dr. Copilot Team
  `;


  // --- SES SendEmailCommand Parameters ---
  const params = {
    Destination: {
      ToAddresses: [recipientEmail],
    },
    Message: {
      Body: {
        Html: {
          Charset: "UTF-8",
          Data: htmlBody,
        },
        Text: {
          Charset: "UTF-8",
          Data: textBody,
        },
      },
      Subject: {
        Charset: "UTF-8",
        Data: subject,
      },
    },
    Source: SES_FROM_EMAIL, // This must be a verified email address in your AWS SES account
  };

  // --- Send Email via SES ---
  try {
    const command = new SendEmailCommand(params);
    const data = await sesClient.send(command);
    console.log(`Email sent successfully to ${recipientEmail}. Message ID: ${data.MessageId}`);
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        success: true,
        message: 'Invitation email sent successfully.',
        messageId: data.MessageId
      }),
    };
  } catch (error) {
    console.error('Error sending email via SES:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: 'Failed to send invitation email.',
        message: error.message
      }),
    };
  }
};
