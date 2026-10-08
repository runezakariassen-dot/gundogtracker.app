import { getApps, initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import * as functions from "firebase-functions";
import * as logger from "firebase-functions/logger";
import { createHash } from "node:crypto";
import {
  DeliveryIdentity,
  NotificationPayload,
  processSharedDogSessionCreated,
  SharedDogSessionDependencies,
  TransientDeliveryError,
} from "./shared_dog_session_notifications";

if (getApps().length === 0) {
  initializeApp();
}

const db = getFirestore();

// Keep the export name stable so we update the same deployed function.
export const onAuthUserCreated = functions.auth.user().onCreate(async (user) => {
  const providerId = user.providerData?.[0]?.providerId ?? "unknown";
  const userDocRef = db.collection("users").doc(user.uid);

  const basePayload = {
    uid: user.uid,
    email: user.email ?? null,
    displayName: user.displayName ?? null,
    photoURL: user.photoURL ?? null,
    providerId,
    locale: "nb" as const,
    appVersionCreated: null,
    roles: { admin: false },
  };

  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(userDocRef);
      const lastLoginAt = FieldValue.serverTimestamp();

      if (snap.exists) {
        tx.set(userDocRef, { ...basePayload, lastLoginAt }, { merge: true });
      } else {
        tx.set(userDocRef, { ...basePayload, createdAt: lastLoginAt, lastLoginAt }, { merge: true });
      }
    });

    logger.info("users/{uid} created or updated", {
      uid: user.uid,
      providerId,
      hasEmail: !!user.email,
    });
  } catch (error) {
    logger.error("Failed writing users/{uid}", { uid: user.uid, error });
    throw error;
  }
});

function deliveryDocumentId(identity: DeliveryIdentity): string {
  const logicalKey = [
    identity.eventType,
    identity.dogId,
    identity.sessionId,
    identity.recipientUid,
  ].join(":");
  return createHash("sha256").update(logicalKey).digest("hex");
}

const sharedDogSessionDependencies: SharedDogSessionDependencies = {
  async getDog(dogId) {
    const snapshot = await db.collection("dogs").doc(dogId).get();
    return snapshot.exists ? snapshot.data() ?? null : null;
  },
  async listMembers(dogId) {
    const snapshot = await db.collection("dogs").doc(dogId)
      .collection("members").get();
    return snapshot.docs.map((doc) => ({ id: doc.id, data: doc.data() }));
  },
  async getUser(uid) {
    const snapshot = await db.collection("users").doc(uid).get();
    return snapshot.exists ? snapshot.data() ?? null : null;
  },
  async listDevices(uid) {
    const snapshot = await db.collection("users").doc(uid)
      .collection("devices").get();
    return snapshot.docs.map((doc) => ({
      id: doc.id,
      path: doc.ref.path,
      data: doc.data(),
    }));
  },
  async reserveDelivery(identity) {
    const ref = db.collection("notificationDeliveries")
      .doc(deliveryDocumentId(identity));
    return db.runTransaction(async (transaction) => {
      const existing = await transaction.get(ref);
      if (existing.exists) return false;
      transaction.create(ref, {
        ...identity,
        status: "processing",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return true;
    });
  },
  async markDeliverySent(identity) {
    await db.collection("notificationDeliveries")
      .doc(deliveryDocumentId(identity)).set({
        status: "sent",
        sentAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
  },
  async releaseDelivery(identity) {
    await db.collection("notificationDeliveries")
      .doc(deliveryDocumentId(identity)).delete();
  },
  async disableDevice(path) {
    try {
      await db.doc(path).set({
        enabled: false,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    } catch (error) {
      logger.warn("Failed disabling invalid FCM device", { path, error });
      throw error;
    }
  },
  async sendMulticast(tokens: string[], payload: NotificationPayload) {
    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: payload.notification,
      data: payload.data,
    });
    return response.responses.map((item) => ({
      success: item.success,
      errorCode: item.error?.code,
    }));
  },
};

export const onSharedDogSessionCreated = functions.firestore
  .document("dogs/{dogId}/sessions/{sessionId}")
  .onCreate(async (snapshot, context) => {
    const dogId = context.params.dogId as string;
    const sessionId = context.params.sessionId as string;
    try {
      const summary = await processSharedDogSessionCreated({
        dogId,
        sessionId,
        sessionData: snapshot.exists ? snapshot.data() : null,
      }, sharedDogSessionDependencies);
      logger.info("Shared dog session notification processed", {
        dogId,
        sessionId,
        recipientCount: summary.recipientCount,
        deviceCount: summary.deviceCount,
        successCount: summary.successCount,
        failureCount: summary.failureCount,
        skippedReason: summary.skippedReason,
      });
    } catch (error) {
      const summary = error instanceof TransientDeliveryError
        ? error.summary
        : null;
      logger.error("Shared dog session notification failed", {
        dogId,
        sessionId,
        recipientCount: summary?.recipientCount,
        deviceCount: summary?.deviceCount,
        successCount: summary?.successCount,
        failureCount: summary?.failureCount,
        error,
      });
      throw error;
    }
  });
