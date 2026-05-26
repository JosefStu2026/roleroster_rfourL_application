const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

async function sendPushToRecipient(recipientId, payload) {
  const userSnap = await db.collection('users').doc(recipientId).get();
  if (!userSnap.exists) return;

  const token = userSnap.get('fcmToken');
  if (!token) return;

  await admin.messaging().send({
    token,
    notification: payload.notification,
    android: payload.android,
    data: payload.data,
  });
}

// Send FCM when a notification document is created
exports.sendFcmOnNotification = functions.firestore
  .document('notifications/{nid}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;
    const recipientId = data.recipientId;
    if (!recipientId) return null;

    try {
      const payload = {
        notification: {
          title: data.title || 'Notification',
          body: data.body || '',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'role_roster_notifications',
            sound: 'default',
          },
        },
        data: {
          type: data.type || '',
          groupId: data.groupId || '',
          taskId: data.taskId || '',
          actorId: data.actorId || '',
        },
      };

      await sendPushToRecipient(recipientId, payload);
    } catch (err) {
      console.error('sendFcmOnNotification error', err);
    }

    return null;
  });

// Scheduled job: check groups for due date arrival and create/send notifications
exports.scheduledDueDateCheck = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const nowIso = new Date().toISOString();
    try {
      const groupsSnap = await db
        .collection('groups')
        .where('archived', '==', false)
        .where('dueAt', '<=', nowIso)
        .get();

      for (const gdoc of groupsSnap.docs) {
        const g = gdoc.data();
        const groupId = gdoc.id;
        const groupName = g.name || g.name || '';
        const leaderId = g.leaderId || '';
        const memberIds = Array.isArray(g.memberIds) ? g.memberIds : [];

        for (const memberId of memberIds) {
          const nId = `group_due_${groupId}_${memberId}`;
          const nRef = db.collection('notifications').doc(nId);
          const nSnap = await nRef.get();
          if (nSnap.exists) continue; // already notified

          const payload = {
            recipientId: memberId,
            type: 'group_due_date',
            title: 'Group due date',
            body: `Project ${groupName} is due.`,
            taskId: '',
            groupId: groupId,
            actorId: leaderId,
            actorName: g.leaderName || '',
            createdAt: new Date().toISOString(),
            readAt: null,
          };

          await nRef.set(payload);

          // send immediate FCM if token exists
          try {
            await sendPushToRecipient(memberId, {
              notification: {
                title: payload.title,
                body: payload.body,
              },
              android: {
                priority: 'high',
                notification: {
                  channelId: 'role_roster_notifications',
                  sound: 'default',
                },
              },
              data: { type: payload.type, groupId: payload.groupId },
            });
          } catch (err) {
            console.error('scheduledDueDateCheck send error', err);
          }
        }
      }
    } catch (err) {
      console.error('scheduledDueDateCheck error', err);
    }

    return null;
  });
