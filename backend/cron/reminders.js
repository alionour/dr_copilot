const admin = require('firebase-admin');
const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");

// Initialize Firebase Admin (if not already initialized)
if (!admin.apps.length) {
    try {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log('Firebase Admin initialized for Reminders');
    } catch (error) {
        console.error('Firebase Admin initialization failed:', error);
        throw error;
    }
}

const db = admin.firestore();
const sesClient = new SESClient({ region: process.env.AWS_REGION || "us-east-1" });

module.exports.handler = async (event) => {
    console.log('Starting Daily Patient Reminders Job...');

    try {
        // 1. Calculate "Tomorrow" date range
        const now = new Date();
        const tomorrowStart = new Date(now);
        tomorrowStart.setDate(tomorrowStart.getDate() + 1);
        tomorrowStart.setHours(0, 0, 0, 0);

        const tomorrowEnd = new Date(tomorrowStart);
        tomorrowEnd.setHours(23, 59, 59, 999);

        console.log(`Querying appointments between ${tomorrowStart.toISOString()} and ${tomorrowEnd.toISOString()}`);

        // 2. Query Appointments
        // Assuming 'date' is stored as an ISO string or Timestamp. 
        // Adjust field name based on actual Firestore schema.
        // We'll try to support both 'date' (string) and Timestamp ranges if possible, 
        // but for now assuming standard ISO string or Timestamp field named 'date'.

        const appointmentsSnapshot = await db.collection('appointments')
            .where('date', '>=', tomorrowStart.toISOString())
            .where('date', '<=', tomorrowEnd.toISOString())
            .get();

        if (appointmentsSnapshot.empty) {
            console.log('No appointments found for tomorrow.');
            return { statusCode: 200, body: 'No appointments found.' };
        }

        console.log(`Found ${appointmentsSnapshot.size} appointments.`);

        let sentCount = 0;
        let errorCount = 0;

        // 3. Process each appointment
        for (const doc of appointmentsSnapshot.docs) {
            const appointment = doc.data();

            // Check if patientId exists
            if (!appointment.patientId) {
                console.warn(`Appointment ${doc.id} missing patientId.`);
                continue;
            }

            // Check if clinic has reminders enabled (Optional - optimization)
            // Ideally we check clinic settings first, but for now we check per appointment/patient
            // or we can fetch clinic settings if we have clinicId.

            try {
                // Fetch Patient Details
                const patientDoc = await db.collection('patients').doc(appointment.patientId).get();
                if (!patientDoc.exists) {
                    console.warn(`Patient ${appointment.patientId} not found.`);
                    continue;
                }
                const patient = patientDoc.data();

                if (!patient.email) {
                    console.log(`Patient ${patient.name} has no email. Skipping.`);
                    continue;
                }

                // Send Email
                const emailParams = {
                    Destination: {
                        ToAddresses: [patient.email],
                    },
                    Message: {
                        Body: {
                            Text: {
                                Data: `Dear ${patient.name},\n\nThis is a reminder for your appointment tomorrow at ${new Date(appointment.date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}.\n\nPlease contact us if you need to reschedule.\n\nBest regards,\nDr. Copilot Team`,
                            },
                        },
                        Subject: {
                            Data: "Appointment Reminder",
                        },
                    },
                    Source: process.env.SES_FROM_EMAIL || "noreply@drcopilot.com",
                };

                const command = new SendEmailCommand(emailParams);
                await sesClient.send(command);
                console.log(`Reminder sent to ${patient.email}`);
                sentCount++;

            } catch (err) {
                console.error(`Error processing appointment ${doc.id}:`, err);
                errorCount++;
            }
        }

        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Reminders processed',
                sent: sentCount,
                errors: errorCount
            }),
        };

    } catch (error) {
        console.error('Fatal error in reminders job:', error);
        return { statusCode: 500, body: error.message };
    }
};
