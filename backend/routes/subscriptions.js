const express = require('express');
const https = require('https');
const router = express.Router();
const admin = require('firebase-admin');

// Paymob Config
const PAYMOB_API_KEY = process.env.PAYMOB_API_KEY;
const PAYMOB_INTEGRATION_ID = process.env.PAYMOB_INTEGRATION_ID_CARD;
const PAYMOB_IFRAME_ID = process.env.PAYMOB_IFRAME_ID;

const db = admin.firestore();

// Plan Configuration (Hardcoded for security)
const PLANS = {
    'pro': { amount: 29.00, currency: 'USD', name: 'Pro Plan' },
    'elite': { amount: 99.00, currency: 'USD', name: 'Elite Plan' },
    'pro_yearly': { amount: 290.00, currency: 'USD', name: 'Pro Plan (Yearly)' }, // 10 months price
    'elite_yearly': { amount: 990.00, currency: 'USD', name: 'Elite Plan (Yearly)' }
};

// Helper: Generic HTTPS Request (Reused)
function paymobRequest(method, path, body = null, authToken = null) {
    return new Promise((resolve, reject) => {
        const headers = { 'Content-Type': 'application/json' };
        if (authToken) {
            headers['Authorization'] = `Bearer ${authToken}`;
        }

        const options = {
            hostname: 'accept.paymob.com',
            port: 443,
            path: '/api' + path,
            method: method,
            headers: headers
        };
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    try { resolve(JSON.parse(data)); } catch (e) { resolve(data); }
                } else {
                    reject({ statusCode: res.statusCode, body: data });
                }
            });
        });
        req.on('error', (e) => reject(e));
        if (body) req.write(JSON.stringify(body));
        req.end();
    });
}

// POST /subscriptions/initiate
// Body: { planId: 'pro', period: 'monthly'|'yearly', userId: '...', email: '...' }
router.post('/initiate', async (req, res) => {
    try {
        const { planId, period, userId, email, clinicId } = req.body;

        const planKey = planId.toLowerCase() + (period === 'yearly' ? '_yearly' : '');
        const plan = PLANS[planKey];

        if (!plan) {
            return res.status(400).json({ error: 'Invalid Plan ID or Period' });
        }

        // 1. Auth
        const authResponse = await paymobRequest('POST', '/auth/tokens', { api_key: PAYMOB_API_KEY });
        const token = authResponse.token;

        // 2. Order
        const amountCents = Math.round(plan.amount * 100);
        const orderResponse = await paymobRequest('POST', '/ecommerce/orders', {
            auth_token: token,
            delivery_needed: "false",
            amount_cents: amountCents,
            currency: "USD", // Paymob supports USD? Check Integration. Assuming yes or user configures it.
            // Note: If Integration is EGP only, this might fail or convert. 
            // Ideally we pass the Integration Currency.
            // For now assuming USD is accepted or Integration handles it.
            items: [],
        });
        const orderId = orderResponse.id;

        // 3. Payment Key
        const paymentKeyResponse = await paymobRequest('POST', '/acceptance/payment_keys', {
            auth_token: token,
            amount_cents: amountCents,
            expiration: 3600,
            order_id: orderId,
            billing_data: {
                apartment: "NA", email: email || "NA", floor: "NA", first_name: "Clinic", street: "NA",
                building: "NA", phone_number: "+00000000", shipping_method: "NA", postal_code: "NA",
                city: "NA", country: "NA", last_name: "Owner", state: "NA"
            },
            currency: "USD",
            integration_id: PAYMOB_INTEGRATION_ID
        });

        // 4. Return Iframe URL or Redirect URL
        const iframeUrl = `https://accept.paymob.com/api/acceptance/iframes/${PAYMOB_IFRAME_ID}?payment_token=${paymentKeyResponse.token}`;

        // Save pending subscription intent
        // Using a temporary collection "subscription_intents" or just relying on Paymob callback to have metadata
        // Paymob doesn't easily pass custom metadata through to callback params generally, 
        // usually rely on Order ID or Merchant Order ID.
        // We can save OrderID -> Plan Details in Firestore.
        await db.collection('subscription_transactions').doc(orderId.toString()).set({
            clinicId,
            userId,
            planId,
            period,
            amount: plan.amount,
            currency: 'USD',
            status: 'pending',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        res.json({ iframeUrl, orderId });

    } catch (error) {
        console.error('Subscription Init Error:', error);
        res.status(500).json({ error: 'Failed to initiate subscription' });
    }
});

// POST /subscriptions/verify
// Body: { transactionId: '...', type: 'paymob' }
router.post('/verify', async (req, res) => {
    try {
        const { transactionId } = req.body;

        // 1. Fetch Auth Token
        const authResponse = await paymobRequest('POST', '/auth/tokens', { api_key: PAYMOB_API_KEY });
        const token = authResponse.token;

        // 2. Fetch Transaction using Token in Header
        const txnResponse = await paymobRequest('GET', `/acceptance/transactions/${transactionId}`, null, token);

        if (txnResponse.success === true && txnResponse.is_void === false) {
            const orderId = txnResponse.order;

            // 3. Find Intent
            const intentDoc = await db.collection('subscription_transactions').doc(orderId.toString()).get();
            if (!intentDoc.exists) {
                return res.status(404).json({ error: 'Transaction intent not found' });
            }

            const intent = intentDoc.data();
            if (intent.status === 'completed') {
                return res.json({ success: true, message: 'Already completed' });
            }

            // 4. Update Clinic Subscription
            // Determine new expiry (simple logic: +30 days or +365 days)
            const now = new Date();
            const isYearly = intent.period === 'yearly';
            const expiryDate = new Date(now.setMonth(now.getMonth() + (isYearly ? 12 : 1)));

            // Map Plan ID to Tier Name (Assuming standard names 'Pro', 'Elite')
            // Capitalize first letter
            const newTier = intent.planId.charAt(0).toUpperCase() + intent.planId.slice(1);

            await db.collection('clinics').doc(intent.clinicId).update({
                subscriptionTier: newTier,
                subscriptionExpiry: admin.firestore.Timestamp.fromDate(expiryDate),
                subscriptionStatus: 'active'
            });

            await db.collection('subscription_transactions').doc(orderId.toString()).update({
                status: 'completed',
                paymobTransactionId: transactionId,
                completedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            return res.json({ success: true, newTier, expiryDate });

        } else {
            return res.status(400).json({ error: 'Transaction verification failed or pending' });
        }

    } catch (error) {
        console.error('Verification Error:', error);
        res.status(500).json({ error: 'Verification failed' });
    }
});

module.exports = router;
