const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

async function addAuthorizedDomain() {
    const domain = 'hg4orotvf0.execute-api.us-east-1.amazonaws.com';
    const projectId = 'drcopilot-bfc9e';

    console.log(`Adding authorized domain: ${domain}`);
    console.log(`Project ID: ${projectId}`);

    try {
        // Get access token
        const accessToken = await admin.credential.applicationDefault().getAccessToken();

        // Fetch current config
        const fetchResponse = await fetch(
            `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config`,
            {
                headers: {
                    'Authorization': `Bearer ${accessToken.access_token}`,
                    'Content-Type': 'application/json'
                }
            }
        );

        const config = await fetchResponse.json();
        console.log('\nCurrent authorized domains:', config.authorizedDomains || []);

        // Add new domain if not already present
        const authorizedDomains = config.authorizedDomains || [];
        if (!authorizedDomains.includes(domain)) {
            authorizedDomains.push(domain);

            // Update config
            const updateResponse = await fetch(
                `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config?updateMask=authorizedDomains`,
                {
                    method: 'PATCH',
                    headers: {
                        'Authorization': `Bearer ${accessToken.access_token}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        authorizedDomains: authorizedDomains
                    })
                }
            );

            const result = await updateResponse.json();

            if (updateResponse.ok) {
                console.log('\n✅ Successfully added authorized domain!');
                console.log('Updated authorized domains:', result.authorizedDomains);
            } else {
                console.error('\n❌ Failed to add domain:', result);
            }
        } else {
            console.log('\n✅ Domain already authorized!');
        }

    } catch (error) {
        console.error('\n❌ Error:', error.message);
        console.error('\nPlease add the domain manually in Firebase Console:');
        console.error('1. Go to https://console.firebase.google.com');
        console.error('2. Select project: drcopilot-bfc9e');
        console.error('3. Authentication → Settings → Authorized domains');
        console.error(`4. Add: ${domain}`);
    }

    process.exit(0);
}

addAuthorizedDomain();
