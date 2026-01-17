const https = require('https');

const API_KEY = process.argv[2] || process.env.PADDLE_API_KEY;

if (!API_KEY) {
    console.error('Usage: node setup-paddle.js <PADDLE_API_KEY>');
    process.exit(1);
}

// Auto-detect environment
const isLive = API_KEY.startsWith('pdl_live') || API_KEY.startsWith('pdl_liv');
const BASE_URL = process.env.PADDLE_API_URL || (isLive ? 'https://api.paddle.com' : 'https://sandbox-api.paddle.com');

console.log(`Environment detected: ${isLive ? 'LIVE' : 'SANDBOX'} (${BASE_URL})`);

// Helper to make requests
function request(method, path, body = null) {
    return new Promise((resolve, reject) => {
        const options = {
            method: method,
            family: 4, // Force IPv4
            headers: {
                'Authorization': `Bearer ${API_KEY}`,
                'Content-Type': 'application/json'
            }
        };

        const req = https.request(`${BASE_URL}${path}`, options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    try {
                        resolve(JSON.parse(data));
                    } catch (e) {
                        resolve(data);
                    }
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

// Helper Functions
async function createProductIfNotExists(name) {
    console.log(`Creating product: ${name}...`);
    try {
        const productBody = {
            name: name,
            tax_category: 'standard', // 'standard' is usually safe default
            description: `${name} Subscription for Dr. Copilot`
        };

        const result = await request('POST', '/products', productBody);
        const product = result.data;
        console.log(`✅ Created Product: ${product.name} (ID: ${product.id})`);
        return product.id;
    } catch (error) {
        // If product already exists/name conflict, usually Paddle creates duplicate.
        // We will just return, but logging error is good.
        console.error(`Failed to create product ${name}:`, JSON.stringify(error, null, 2));
        throw error;
    }
}

async function createPrice(productId, priceAmount) {
    console.log(`Creating price for product ${productId}...`);
    try {
        const priceBody = {
            description: 'Monthly Subscription',
            product_id: productId,
            unit_price: {
                amount: priceAmount.toString(),
                currency_code: 'USD'
            },
            billing_cycle: {
                interval: 'month',
                frequency: 1
            }
        };

        const result = await request('POST', '/prices', priceBody);
        const price = result.data;
        console.log(`✅ Created Price: ${price.id}`);
        return price.id;
    } catch (error) {
        console.error(`Failed to create price for ${productId}:`, JSON.stringify(error, null, 2));
        throw error;
    }
}

async function getOrCreatePlan(name, amount) {
    const productId = await createProductIfNotExists(name);
    const priceId = await createPrice(productId, amount);
    return priceId;
}

async function main() {
    console.log(`\n🚀 Setting up Paddle Products on ${BASE_URL}...\n`);

    try {
        // Check API Key validity
        await request('GET', '/products?per_page=1');
        console.log('✅ API Key is valid.');

        // Create Pro Plan ($29)
        const proPriceId = await getOrCreatePlan('Dr. Copilot Pro', 29);

        // Create Elite Plan ($59)
        const elitePriceId = await getOrCreatePlan('Dr. Copilot Elite', 59);

        console.log('\n🎉 Setup Complete! Here are your keys for Doppler:\n');
        console.log(`PADDLE_API_KEY=${API_KEY}`);
        console.log(`PADDLE_API_URL=${BASE_URL}`);
        console.log(`PADDLE_PRICE_ID_PRO=${proPriceId}`);
        console.log(`PADDLE_PRICE_ID_ELITE=${elitePriceId}`);
        console.log('\nCopy the lines above and use them to configure your backend.');

    } catch (error) {
        if (error.statusCode === 401 || error.statusCode === 403) {
            console.error('❌ Authentication failed. Please check your API Key.');
        } else {
            console.error('❌ An error occurred:', error);
        }
    }
}

main();
