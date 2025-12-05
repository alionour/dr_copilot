// Create diverse sample notifications to showcase the dashboard UI
const admin = require('firebase-admin');

// Initialize Firebase Admin from environment variable
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

if (admin.apps.length === 0) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}

const db = admin.firestore();

// Comprehensive sample notifications with variety
const sampleNotifications = [
    // System notifications
    {
        title: "🎉 Welcome to Dr. Copilot",
        message: "Thank you for joining! Explore features to manage your clinic efficiently with our comprehensive healthcare management platform.",
        type: "system",
        isRead: true,
        daysAgo: 7
    },
    {
        title: "📱 New Mobile App Version Available",
        message: "Version 2.5.0 is now available with improved performance, bug fixes, and new video consultation features.",
        type: "system",
        isRead: false,
        daysAgo: 1
    },
    // Alert notifications
    {
        title: "⚠️ System Maintenance Scheduled",
        message: "Scheduled maintenance on Saturday, Dec 7th from 2:00 AM to 4:00 AM EST. Please save all work before this time.",
        type: "alert",
        isRead: false,
        daysAgo: 0
    },
    {
        title: "🔒 Security Alert: New Login Location",
        message: "A new device signed into your account from Cairo, Egypt. If this wasn't you, please change your password immediately.",
        type: "alert",
        isRead: true,
        daysAgo: 3
    },
    // Appointment notifications
    {
        title: "📅 Upcoming Appointment",
        message: "You have an appointment with Dr. Ahmed tomorrow at 10:30 AM. Please arrive 15 minutes early.",
        type: "appointment",
        isRead: false,
        daysAgo: 0
    },
    {
        title: "✅ Appointment Confirmed",
        message: "Your appointment on December 6th at 3:00 PM has been confirmed. You will receive a reminder 24 hours before.",
        type: "appointment",
        isRead: true,
        daysAgo: 2
    },
    // Payment notifications
    {
        title: "💰 Payment Received",
        message: "Payment of $150.00 received from Ahmed Hassan for consultation services. Transaction ID: TXN-2024-12345",
        type: "payment",
        isRead: false,
        daysAgo: 0
    },
    {
        title: "💳 Invoice Generated",
        message: "Invoice #INV-2024-567 has been generated for $250.00. Payment is due within 7 days.",
        type: "payment",
        isRead: true,
        daysAgo: 5
    },
    // Report notifications
    {
        title: "📊 Monthly Report Available",
        message: "Your November 2024 financial report is ready. Total revenue: $15,430. View detailed analytics in the Reports section.",
        type: "report",
        isRead: false,
        daysAgo: 1
    },
    {
        title: "📈 Patient Statistics Updated",
        message: "Weekly patient statistics: 24 new patients, 156 appointments completed, 98% satisfaction rate.",
        type: "report",
        isRead: true,
        daysAgo: 4
    },
    // Reminder notifications
    {
        title: "⏰ Update Your Schedule",
        message: "Please update your availability for next week. Go to Settings > Schedule to make changes.",
        type: "reminder",
        isRead: false,
        daysAgo: 0
    },
    {
        title: "📝 Complete Patient Forms",
        message: "You have 3 pending patient intake forms that require your review. Complete them before the appointments.",
        type: "reminder",
        isRead: false,
        daysAgo: 1
    },
    // Message notifications
    {
        title: "💬 New Message from Patient",
        message: "Sara Ali sent you a message: 'Thank you for the excellent consultation. I'm feeling much better now!'",
        type: "message",
        isRead: false,
        daysAgo: 0
    },
    {
        title: "⭐ Patient Review Received",
        message: "Ahmed Hassan left a 5-star review: 'Professional, caring, and thorough. Highly recommend!'",
        type: "message",
        isRead: true,
        daysAgo: 2
    },
    {
        title: "📧 Team Message",
        message: "From Dr. Mohamed: 'Team meeting scheduled for Friday at 2 PM to discuss new protocols.'",
        type: "message",
        isRead: false,
        daysAgo: 1
    },
];

async function createDiverseNotifications() {
    console.log('🎨 Creating diverse sample notifications for UI testing...\n');

    try {
        // Get any user from the database
        const usersSnapshot = await db.collection('users').limit(5).get();

        if (usersSnapshot.empty) {
            console.log('❌ No users found in database. Please add users first.');
            process.exit(1);
        }

        const userIds = usersSnapshot.docs.map(doc => doc.id);
        console.log(`👥 Found ${userIds.length} users for testing\n`);

        let successCount = 0;
        let errorCount = 0;

        for (const sample of sampleNotifications) {
            // Pick a random user
            const randomUserId = userIds[Math.floor(Math.random() * userIds.length)];

            // Calculate timestamp based on daysAgo
            const timestamp = new Date();
            timestamp.setDate(timestamp.getDate() - sample.daysAgo);
            timestamp.setHours(timestamp.getHours() - Math.floor(Math.random() * 24));
            timestamp.setMinutes(Math.floor(Math.random() * 60));

            try {
                const notificationRef = db.collection('notifications').doc();

                await notificationRef.set({
                    id: notificationRef.id,
                    userId: randomUserId,
                    title: sample.title,
                    message: sample.message,
                    type: sample.type,
                    isRead: sample.isRead,
                    createdAt: admin.firestore.Timestamp.fromDate(timestamp),
                    actionUrl: '/notifications',
                    metadata: {
                        sentBy: 'test-dashboard-script',
                        sentAt: new Date().toISOString(),
                        isTestData: true,
                        uiTesting: true
                    },
                    sender: {
                        type: 'app_system',
                        senderId: 'system',
                        senderName: 'Dr. Copilot System'
                    },
                    target: {
                        type: 'all_users',
                        targetRoles: null,
                        ownerId: null,
                        clinicIds: null
                    }
                });

                const statusIcon = sample.isRead ? '✉️' : '📧';
                const timeInfo = sample.daysAgo === 0 ? 'Today' : `${sample.daysAgo}d ago`;
                console.log(`${statusIcon} Created: "${sample.title.substring(0, 40)}..." [${sample.type}] ${timeInfo}`);
                successCount++;

            } catch (error) {
                console.error(`❌ Error creating "${sample.title}":`, error.message);
                errorCount++;
            }
        }

        console.log(`\n${'='.repeat(60)}`);
        console.log(`📊 Summary:`);
        console.log(`   ✅ Successfully created: ${successCount} notifications`);
        if (errorCount > 0) {
            console.log(`   ❌ Failed: ${errorCount} notifications`);
        }

        console.log(`\n📋 Notification Types:`);
        const typeCounts = {};
        sampleNotifications.forEach(n => {
            typeCounts[n.type] = (typeCounts[n.type] || 0) + 1;
        });
        Object.entries(typeCounts).forEach(([type, count]) => {
            console.log(`   • ${type}: ${count}`);
        });

        console.log(`\n📖 Read Status:`);
        const readCount = sampleNotifications.filter(n => n.isRead).length;
        const unreadCount = sampleNotifications.filter(n => !n.isRead).length;
        console.log(`   • Read: ${readCount}`);
        console.log(`   • Unread: ${unreadCount}`);

        console.log(`\n🎉 Sample notifications created successfully!`);
        console.log(`🔗 View them at: https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/admin/notifications\n`);

    } catch (error) {
        console.error('❌ Error creating sample notifications:', error);
    }

    process.exit(0);
}

createDiverseNotifications();
