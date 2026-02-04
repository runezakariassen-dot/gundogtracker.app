import { getApps, initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import * as functions from "firebase-functions";
import * as logger from "firebase-functions/logger";

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
