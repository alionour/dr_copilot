const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const crypto = require('crypto');

const PADDLE_WEBHOOK_SECRET_KEY = process.env.PADDLE_WEBHOOK_SECRET_KEY;

// Paddle Signature Verification
function verifyPaddleSignature(req, res, next) {
    if (!PADDLE_WEBHOOK_SECRET_KEY) {
        console.warn('PADDLE_WEBHOOK_SECRET_KEY is missing. Skipping signature verification (unsafe for production).');
        return next();
    }

    const signature = req.headers['paddle-signature'];
    if (!signature) {
        return res.status(401).json({ error: 'Missing Paddle-Signature header' });
    }

    // Extract ts and h1 from signature
    const parts = signature.split(';');
    const tsPart = parts.find(p => p.startsWith('ts='));
    const h1Part = parts.find(p => p.startsWith('h1='));

    if (!tsPart || !h1Part) {
        return res.status(401).json({ error: 'Invalid signature format' });
    }

    const ts = tsPart.split('=')[1];
    const h1 = h1Part.split('=')[1];

    // Prevent replay attacks (allow 5 mins drift)
    if (Date.now() / 1000 - parseInt(ts) > 300) {
        return res.status(401).json({ error: 'Request too old' });
    }

    // Construct the payload to verify
    const signedPayload = `${ts}:${req.rawBody}`;

    // Calculate digest
    const computedH1 = crypto
        .createHmac('sha256', PADDLE_WEBHOOK_SECRET_KEY)
        .update(signedPayload)
        .digest('hex');

    if (computedH1 !== h1) {
        console.error('Signature verification failed');
        return res.status(401).json({ error: 'Invalid signature' });
    }

    next();
}

router.post('/custom-webhook', async (req, res) => {
    try {
        const event = req.body;
        console.log(`Received Webhook Event: ${event.event_type}`);

        if (event.event_type === 'transaction.completed') {
            const transaction = event.data;
            const customData = transaction.custom_data;
            const clinicId = customData?.clinicId;

            if (!clinicId) {
                console.warn('No clinicId found in transaction custom_data');
                return res.status(200).send('OK (No clinicId)');
            }

            console.log(`Processing subscription update for Clinic: ${clinicId}`);

            // Determine plan based on price_id logic or items
            const items = transaction.items || [];
            let plan = 'free';

            // Map known Price IDs to Plans (could be env vars too)
            const PRO_PRICE_ID = process.env.PADDLE_PRICE_ID_PRO;
            const ELITE_PRICE_ID = process.env.PADDLE_PRICE_ID_ELITE;

            if (items.some(item => item.price?.id === PRO_PRICE_ID)) {
                plan = 'pro';
            } else if (items.some(item => item.price?.id === ELITE_PRICE_ID)) {
                plan = 'elite';
            }

            if (plan === 'free') {
                console.warn('Could not determine plan from price IDs. Need to update logic if new prices added.');
                // Fallback or just log
            }

            // Calculate expiration (e.g., next_billed_at or current + 30 days)
            // Paddle gives transaction.details.line_items... 
            // Usually we look at the subscription object if it exists. 
            // For one-time transaction or initial sub, likely rely on 'next_billed_at' if available in subscription expansion
            // For now, let's just set "active" and today's date + period.

            await admin.firestore().collection('clinics').doc(clinicId).update({
                subscriptionTier: plan,
                isSubscriptionActive: true,
                subscriptionUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
                subscriptionTransactionId: transaction.id,
                // store complete info if needed
            });

            console.log(`✅ Successfully updated clinic ${clinicId} to ${plan}`);
        }

        res.status(200).send('OK');

    } catch (error) {
        console.error('Webhook Error:', error);
        res.status(500).json({ error: 'Webhook processing failed' });
    }
});

module.exports = router;
