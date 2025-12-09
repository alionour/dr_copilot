const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');

// Environment variables
const PADDLE_API_KEY = process.env.PADDLE_API_KEY;
const PADDLE_API_URL = process.env.PADDLE_API_URL || 'https://sandbox-api.paddle.com';

router.post('/create-checkout-session', async (req, res) => {
    try {
        console.log('--- Create Checkout Session Request ---');
        console.log('Body:', req.body);

        const { planId, clinicId, idToken } = req.body;
        const authHeader = req.headers.authorization;

        // 1. Authenticate User (verify Firebase ID Token)
        let paramIdToken = idToken;
        if (!paramIdToken && authHeader && authHeader.startsWith('Bearer ')) {
            paramIdToken = authHeader.split('Bearer ')[1];
        }

        if (!paramIdToken) {
            // Fallback: If no token provided, maybe allow it? 
            // Ideally we strictly require it.
            // For debugging we might be flexible, but let's log the warning.
            console.warn('No authentication token found in request.');
        } else {
            try {
                // Verify the token
                const decodedToken = await admin.auth().verifyIdToken(paramIdToken);
                console.log('User authenticated:', decodedToken.uid);
            } catch (authError) {
                console.error('Authentication failed:', authError);
                return res.status(401).json({ error: 'Unauthorized: Invalid token' });
            }
        }


        // 2. Map Plan ID to Paddle Price ID
        // You should set these in your Doppler/AWS environment variables
        const PRICE_IDS = {
            'pro': process.env.PADDLE_PRICE_ID_PRO,
            'elite': process.env.PADDLE_PRICE_ID_ELITE,
            // Fallbacks for testing if env vars are missing (REPLACE WITH REAL IDS)
            'default_pro': 'pri_01jk...',
            'default_elite': 'pri_01jk...'
        };

        const priceId = PRICE_IDS[planId] || process.env[`PADDLE_PRICE_ID_${planId.toUpperCase()}`];

        if (!priceId) {
            console.error(`Price ID not found for plan: ${planId}`);
            return res.status(400).json({ error: `Invalid plan ID: ${planId}. Configure PADDLE_PRICE_ID_${planId.toUpperCase()}` });
        }

        if (!PADDLE_API_KEY) {
            console.error('PADDLE_API_KEY is missing');
            return res.status(500).json({ error: 'Server misconfiguration: PADDLE_API_KEY missing' });
        }

        // 3. Create Paddle Transaction
        // We use the /transactions endpoint to create a draft transaction and get a checkout URL
        const paddleBody = {
            items: [
                {
                    price_id: priceId,
                    quantity: 1
                }
            ],
            custom_data: {
                clinicId: clinicId
            }
            // You can add customer_id if you have it
        };

        console.log('Calling Paddle API:', `${PADDLE_API_URL}/transactions`);

        const response = await fetch(`${PADDLE_API_URL}/transactions`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${PADDLE_API_KEY}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(paddleBody)
        });

        const data = await response.json();

        if (!response.ok) {
            console.error('Paddle API Error:', data);
            // Pass the Paddle error back to the client for debugging
            return res.status(response.status).json({
                error: 'Paddle API Error',
                details: data.error
            });
        }

        console.log('Paddle Transaction Created:', data.data.id);

        // Extract checkout URL
        // Transaction object -> details -> checkout -> url
        // Or if it's a drafted transaction, sometimes data.data.url might vary.
        // Usually data.data.details.checkout.url is the one.
        const checkoutUrl = data.data.details?.checkout?.url;

        if (!checkoutUrl) {
            console.error('No checkout URL in Paddle response:', JSON.stringify(data, null, 2));
            // Fallback or error
            return res.status(500).json({ error: 'Failed to generate checkout URL' });
        }

        return res.json({ url: checkoutUrl });

    } catch (error) {
        console.error('Internal Server Error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: error.message
        });
    }
});

module.exports = router;
