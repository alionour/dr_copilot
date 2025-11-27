# AWS SES Sandbox Mode - Important Information

## Current Status: Sandbox Mode

Your AWS SES account is currently in **sandbox mode**. This is the default for all new AWS accounts.

## What This Means

### Restrictions in Sandbox Mode:

1. **Can only send TO verified email addresses**
   - Sender: `nourrehabcenter@gmail.com` ✅ (verified)
   - Recipient: Must also be verified in SES

2. **Sending limit**: 200 emails per 24 hours

3. **Rate limit**: 1 email per second

### Example:

❌ **This will FAIL**:
```json
{
  "recipientEmail": "random-user@example.com",  // Not verified
  "recipientName": "Random User",
  "clinicName": "Test Clinic",
  "role": "Doctor"
}
```
Error: `Email address is not verified`

✅ **This will WORK**:
```json
{
  "recipientEmail": "nourrehabcenter@gmail.com",  // Verified
  "recipientName": "Ali Nour",
  "clinicName": "Test Clinic",
  "role": "Doctor"
}
```

## How to Exit Sandbox Mode (For Production)

To send emails to ANY email address (not just verified ones):

### 1. Request Production Access

1. Go to [AWS SES Console](https://console.aws.amazon.com/ses/home?region=us-east-1)
2. Click "Account dashboard" in left menu
3. Click "Request production access" button
4. Fill out the form:
   - **Mail type**: Transactional
   - **Website URL**: Your app URL
   - **Use case description**: 
     ```
     Dr. Copilot is a medical clinic management application. 
     We send invitation emails to doctors and staff members 
     when they are added to a clinic. Emails are sent only 
     when explicitly requested by clinic administrators.
     ```
   - **Compliance**: Confirm you have processes to handle bounces/complaints
5. Submit request

### 2. Approval Timeline

- Usually approved within **24 hours**
- Sometimes takes up to **2 business days**
- AWS may ask follow-up questions

### 3. After Approval

Once approved:
- ✅ Send to ANY email address
- ✅ Higher sending limits (50,000 emails/day to start)
- ✅ Higher rate limit (14 emails/second)

## Testing in Sandbox Mode

### Option 1: Verify Test Email Addresses

For each person you want to test with:

```bash
# Verify their email
aws ses verify-email-identity --email-address their-email@example.com --region us-east-1

# They'll receive a verification email
# After they click the link, you can send invitations to them
```

### Option 2: Use Your Own Email

For quick testing, just send invitations to `nourrehabcenter@gmail.com`:

```bash
curl -k -X POST https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/invitations \
  -H "Content-Type: application/json" \
  -d @test-invitation.json
```

## Current Test Results

✅ **Invitation sent successfully!**

Check your Gmail inbox (`nourrehabcenter@gmail.com`) for the invitation email.

**Message ID**: `0100019aa56c456b-13167dcc-7e8c-4478-9729-93c42f7d7473-000000`

## Recommendation

**For Development/Testing**: 
- Stay in sandbox mode
- Verify a few test email addresses
- Test all functionality

**Before Production Launch**:
- Request production access
- Wait for approval
- Then deploy to production

## Summary

| Feature | Sandbox Mode | Production Mode |
|---------|--------------|-----------------|
| Send to verified emails | ✅ Yes | ✅ Yes |
| Send to any email | ❌ No | ✅ Yes |
| Daily limit | 200 emails | 50,000+ emails |
| Rate limit | 1/second | 14/second |
| Cost | Free (within limits) | Free (within limits) |

Your backend is **fully functional** in sandbox mode for testing!
