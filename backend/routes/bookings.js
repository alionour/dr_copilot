const express = require('express');
const https = require('https');
const admin = require('firebase-admin');
const router = express.Router();

const db = admin.firestore();

// Helper: Generic HTTPS Request
function paymobRequest(method, path, body = null, apiKey = null) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'accept.paymob.com',
            port: 443,
            path: '/api' + path,
            method: method,
            headers: {
                'Content-Type': 'application/json'
            }
        };

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    try {
                        resolve(JSON.parse(data));
                    } catch (e) {
                        resolve(data);
                    }
                } else {
                    reject({
                        statusCode: res.statusCode,
                        body: data
                    });
                }
            });
        });

        req.on('error', (e) => reject(e));

        if (body) {
            req.write(JSON.stringify(body));
        }
        req.end();
    });
}

// GET /bookings/payment-status?clinicId=...
router.get('/payment-status', async (req, res) => {
    try {
        const { clinicId } = req.query;
        if (!clinicId) {
            return res.status(400).json({ error: 'Missing clinicId' });
        }

        const configDoc = await db.collection('clinic_payment_configs').doc(clinicId).get();
        if (!configDoc.exists) {
            return res.json({ configured: false });
        }

        const data = configDoc.data();
        const configured = !!(data.apiKey && data.integrationId && data.iframeId);

        res.json({ configured });
    } catch (error) {
        console.error('Error checking payment status:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// POST /bookings/initiate-transaction
// Body: { amount, currencyCode, customerEmail, customerName, customerPhone, doctorId, clinicId }
router.post('/initiate-transaction', async (req, res) => {
    try {
        const { amount, currencyCode, customerEmail, customerName, customerPhone, doctorId, clinicId } = req.body;

        if (!clinicId) {
            return res.status(400).json({ error: 'Missing clinicId for payment processing.' });
        }

        // Fetch Clinic Configuration
        let apiKey, integrationId, iframeId;
        const configDoc = await db.collection('clinic_payment_configs').doc(clinicId).get();

        if (configDoc.exists) {
            const data = configDoc.data();
            apiKey = data.apiKey;
            integrationId = data.integrationId;
            iframeId = data.iframeId;
        }

        if (!apiKey || !integrationId || !iframeId) {
            console.error(`Missing Paymob Config for clinic: ${clinicId}`);
            return res.status(400).json({
                error: 'Online payments are not configured for this clinic.',
                code: 'PAYMENT_CONFIG_MISSING'
            });
        }

        // 1. Authentication Request
        const authResponse = await paymobRequest('POST', '/auth/tokens', {
            api_key: apiKey
        });
        const token = authResponse.token;

        // 2. Order Registration API
        const amountCents = Math.round(amount * 100);

        const orderResponse = await paymobRequest('POST', '/ecommerce/orders', {
            auth_token: token,
            delivery_needed: "false",
            amount_cents: amountCents,
            currency: currencyCode || "EGP",
            items: [],
        });
        const orderId = orderResponse.id;

        // 3. Payment Key Request
        const names = (customerName || 'Guest User').split(' ');
        const firstName = names[0];
        const lastName = names.length > 1 ? names.slice(1).join(' ') : 'NA';

        const paymentKeyResponse = await paymobRequest('POST', '/acceptance/payment_keys', {
            auth_token: token,
            amount_cents: amountCents,
            expiration: 3600, // 1 hour
            order_id: orderId,
            billing_data: {
                apartment: "NA",
                email: customerEmail || "NA",
                floor: "NA",
                first_name: firstName,
                street: "NA",
                building: "NA",
                phone_number: customerPhone || "+201234567890",
                shipping_method: "NA",
                postal_code: "NA",
                city: "NA",
                country: "NA",
                last_name: lastName,
                state: "NA"
            },
            currency: currencyCode || "EGP",
            integration_id: integrationId,
            lock_order_when_paid: "false"
        });

        const paymentToken = paymentKeyResponse.token;

        // 4. Return Iframe URL
        const iframeUrl = `https://accept.paymob.com/api/acceptance/iframes/${iframeId}?payment_token=${paymentToken}`;

        res.json({
            paymentToken: paymentToken,
            iframeUrl: iframeUrl,
            orderId: orderId
        });

    } catch (error) {
        console.error('Paymob Error:', error);
        res.status(500).json({
            error: 'Failed to initiate Paymob transaction',
            details: error.body ? JSON.parse(error.body) : error.message
        });
    }
});

module.exports = router;
