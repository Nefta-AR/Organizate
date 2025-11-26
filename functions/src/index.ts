import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

admin.initializeApp();

const firestore = admin.firestore();
const messaging = admin.messaging();

const QUEUE_COLLECTION = 'notificationQueue';
const MAX_PER_RUN = 50;

type QueueDoc = {
  taskId?: string;
  taskTitle?: string;
  runAt?: admin.firestore.Timestamp;
  status?: string;
  type?: string;
  reminderMinutes?: number;
};

export const processDueNotifications = functions.pubsub
  .schedule('every 1 minutes')
  .timeZone('Etc/UTC')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const snapshot = await firestore
      .collectionGroup(QUEUE_COLLECTION)
      .where('status', '==', 'pending')
      .where('runAt', '<=', now)
      .limit(MAX_PER_RUN)
      .get();

    if (snapshot.empty) {
      return null;
    }

    const jobs = snapshot.docs.map(async (doc) => {
      const data = doc.data() as QueueDoc;
      const userRef = doc.ref.parent.parent;
      if (!userRef) {
        await doc.ref.set(
          {
            status: 'failed',
            lastError: 'Missing user reference',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        return;
      }

      const userSnap = await userRef.get();
      const tokens: string[] = Array.isArray(userSnap.get('fcmTokens'))
        ? userSnap.get('fcmTokens')
        : [];

      if (tokens.length === 0) {
        await doc.ref.set(
          {
            status: 'no_tokens',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        return;
      }

      const title = data.taskTitle ?? 'Recordatorio';
      const body = 'Tienes una tarea pendiente.';
      const taskId = data.taskId ?? doc.id;

      const message: admin.messaging.MulticastMessage = {
        tokens,
        notification: { title, body },
        data: {
          taskId,
          type: data.type ?? 'task',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'tareas_channel',
          },
        },
        apns: {
          payload: {
            aps: {
              contentAvailable: true,
              sound: 'default',
              alert: { title, body },
            },
          },
        },
      };

      try {
        const response = await messaging.sendEachForMulticast(message);
        const hasSuccess = response.successCount > 0;
        await doc.ref.set(
          {
            status: hasSuccess ? 'sent' : 'failed',
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            lastError: hasSuccess
              ? admin.firestore.FieldValue.delete()
              : JSON.stringify(response.responses.find((r) => !r.success)?.error ?? {}),
          },
          { merge: true },
        );
      } catch (error) {
        await doc.ref.set(
          {
            status: 'failed',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            lastError: (error as Error).message,
          },
          { merge: true },
        );
      }
    });

    await Promise.all(jobs);
    return null;
  });
