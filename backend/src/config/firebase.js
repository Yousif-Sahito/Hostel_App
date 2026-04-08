import admin from 'firebase-admin';
import dotenv from 'dotenv';

dotenv.config();

// Initialize Firebase Admin SDK
// Make sure you have FIREBASE_SERVICE_ACCOUNT_KEY in your .env file
let firebaseApp = null;
let isInitialized = false;

// Parse the service account key from environment variable if it exists
const initializeFirebase = () => {
  if (isInitialized) {
    return firebaseApp;
  }

  try {
    const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT_KEY
      ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY)
      : null;

    if (!serviceAccountKey) {
      console.warn(
        'Firebase service account key not found. Notifications will be disabled.'
      );
      isInitialized = true;
      return null;
    }

    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccountKey),
    });

    isInitialized = true;
    console.log('Firebase Admin SDK initialized successfully');
    return firebaseApp;
  } catch (error) {
    console.error('Firebase initialization error:', error.message);
    isInitialized = true;
    return null;
  }
};

// Send notification to specific device
export const sendNotification = async (fcmToken, title, body, data = {}) => {
  try {
    const app = initializeFirebase();
    if (!app) {
      console.warn('Firebase not initialized. Notification not sent.');
      return null;
    }

    if (!fcmToken) {
      throw new Error('FCM token is required');
    }

    const message = {
      notification: {
        title,
        body,
      },
      data,
      token: fcmToken,
    };

    const response = await admin.messaging().send(message);
    console.log(`Notification sent successfully: ${response}`);
    return response;
  } catch (error) {
    console.error('Error sending notification:', error.message);
    return null;
  }
};

// Send notification to multiple devices
export const sendMulticastNotification = async (
  fcmTokens,
  title,
  body,
  data = {}
) => {
  try {
    const app = initializeFirebase();
    if (!app) {
      console.warn('Firebase not initialized. Multicast notification not sent.');
      return null;
    }

    if (!fcmTokens || fcmTokens.length === 0) {
      throw new Error('At least one FCM token is required');
    }

    const message = {
      notification: {
        title,
        body,
      },
      data,
    };

    const response = await admin.messaging().sendMulticast({
      ...message,
      tokens: fcmTokens,
    });

    console.log(
      `Multicast notification sent. Success: ${response.successCount}, Failure: ${response.failureCount}`
    );
    return response;
  } catch (error) {
    console.error('Error sending multicast notification:', error.message);
    return null;
  }
};

export const initFirebase = initializeFirebase;
