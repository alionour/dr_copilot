const https = require('https');

const API_KEY = process.env.PADDLE_API_KEY;
// Get the currently ACTIVE price IDs (so we don't delete them)
const ACTIVE_PRO_PRICE_ID = process.env.PADDLE_PRICE_ID_PRO;
const ACTIVE_ELITE_PRICE_ID = process.env.PADDLE_PRICE_ID_ELITE;

// Auto-detect environment
const isLive = API_KEY && (API_KEY.startsWith('pdl_live') || API_KEY.startsWith('pdl_liv'));
const BASE_URL = process.env.PADDLE_API_URL || (isLive ? 'https://api.paddle.com' : 'https://sandbox-api.paddle.com');

console.log(`Environment: ${isLive ? 'LIVE' : 'SANDBOX'} (${BASE_URL})`);
console.log(`Active PRO Price: ${ACTIVE_PRO_PRICE_ID}`);
console.log(`Active ELITE Price: ${ACTIVE_ELITE_PRICE_ID}`);

if (!API_KEY) {
    console.error('PADDLE_API_KEY environment variable is required.');
    process.exit(1);
}

function request(method, path, body = null) {
    return new Promise((resolve, reject) => {
        const options = {
            method: method,
            family: 4,
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

async function archiveProduct(productId) {
    console.log(`Archiving Product: ${productId}...`);
    try {
        await request('PATCH', `/products/${productId}`, { status: 'archived' });
        console.log(`✅ Archived ${productId}`);
    } catch (e) {
        console.error(`❌ Failed to archive ${productId}:`, e);
    }
}

async function cleanup() {
    try {
        // Fetch all products with prices (limit 100 to catch more)
        const response = await request('GET', '/products?include=prices&status=active&per_page=100');
        const products = response.data;

        console.log(`Found ${products.length} active products.`);

        let keptCount = 0;
        let archivedCount = 0;

        for (const product of products) {
            // Broader check: Any product related to "Copilot"
            if (!product.name.toLowerCase().includes('copilot')) {
                console.log(`Skipping unrelated product: ${product.name}`);
                continue;
            }

            const prices = product.prices || [];
            if (prices.length === 0) {
                // No prices? probably stale. Archive.
                console.log(`Product ${product.name} (${product.id}) has no prices. Archiving.`);
                await archiveProduct(product.id);
                archivedCount++;
                continue;
            }

            // Check if any price in this product matches our ACTIVE set
            const hasActivePrice = prices.some(p =>
                p.id === ACTIVE_PRO_PRICE_ID ||
                p.id === ACTIVE_ELITE_PRICE_ID
            );

            if (hasActivePrice) {
                console.log(`Keeping ACTIVE Product: ${product.name} (${product.id})`);
                keptCount++;
            } else {
                console.log(`Found DUPLICATE/STALE Product: ${product.name} (${product.id}) - Archiving...`);
                await archiveProduct(product.id);
                archivedCount++;
            }
        }

        console.log(`\nCleanup Summary: Kept ${keptCount}, Archived ${archivedCount}`);

    } catch (e) {
        console.error('Error during cleanup:', e);
    }
}

cleanup();
