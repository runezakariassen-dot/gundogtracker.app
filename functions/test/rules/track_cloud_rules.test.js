const fs = require("node:fs");
const path = require("node:path");
const { after, before, beforeEach, test } = require("node:test");

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
} = require("firebase/firestore");
const {
  deleteObject,
  getBytes,
  ref,
  uploadBytes,
} = require("firebase/storage");

const projectId = "demo-jakthund-track-rules";
const dogId = "dog-track-rules";
const otherDogId = "dog-other";
const existingTrackId = "track-existing";
const sessionId = "session-with-track-edit";
const activeRoles = ["owner", "admin", "editor", "viewer"];
const writers = new Set(["owner", "admin", "editor"]);
const inactiveMembers = ["pending", "revoked"];

let testEnv;

function firestoreFor(uid) {
  return uid === null
    ? testEnv.unauthenticatedContext().firestore()
    : testEnv.authenticatedContext(uid).firestore();
}

function storageFor(uid) {
  return uid === null
    ? testEnv.unauthenticatedContext().storage()
    : testEnv.authenticatedContext(uid).storage();
}

function trackDocument(db, targetDogId, trackId) {
  return doc(db, "dogs", targetDogId, "tracks", trackId);
}

function trackObject(storage, targetDogId, trackId) {
  return ref(storage, `dogs/${targetDogId}/tracks/${trackId}/track.json`);
}

function metadata(targetDogId, trackId) {
  return {
    trackId,
    sessionId: `session-${trackId}`,
    dogId: targetDogId,
    cloudDogId: targetDogId,
    source: "emulator-test",
    pointCount: 1,
    storagePath: `dogs/${targetDogId}/tracks/${trackId}/track.json`,
    createdAt: new Date("2026-01-01T10:00:00.000Z"),
    updatedAt: new Date("2026-01-01T10:00:00.000Z"),
    schemaVersion: 1,
  };
}

function rawTrack(trackId) {
  return Buffer.from(JSON.stringify({
    schemaVersion: 1,
    trackId,
    createdAt: "2026-01-01T10:00:00.000Z",
    source: "emulator-test",
    pointCount: 1,
    points: [{
      lat: 60.0,
      lon: 10.0,
      time: "2026-01-01T10:00:00.000Z",
    }],
  }));
}

function trackEdit() {
  return {
    schemaVersion: 1,
    sourceTrackId: existingTrackId,
    startIndexInclusive: 1,
    endIndexExclusive: 3,
    startTimeAnchor: new Date("2026-01-01T10:01:00.000Z"),
    endTimeAnchor: new Date("2026-01-01T10:03:00.000Z"),
    sourcePointCount: 4,
    sourceFingerprint: "deadbeef",
    createdAt: new Date("2026-01-01T11:00:00.000Z"),
    updatedAt: new Date("2026-01-01T11:00:00.000Z"),
    updatedByUserId: "owner",
  };
}

function sessionDocument(createdByUserId = "owner") {
  return {
    id: sessionId,
    sessionId,
    dogId,
    cloudDogId: dogId,
    createdByUserId,
    dateTime: new Date("2026-01-01T10:00:00.000Z"),
    updatedAt: new Date("2026-01-01T11:00:00.000Z"),
    trackEdit: trackEdit(),
  };
}

async function seedFixture() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const storage = context.storage();
    for (const role of activeRoles) {
      await setDoc(doc(db, "dogs", dogId, "members", role), {
        uid: role,
        role,
        status: "active",
      });
    }
    for (const status of inactiveMembers) {
      await setDoc(doc(db, "dogs", dogId, "members", status), {
        uid: status,
        role: "editor",
        status,
      });
    }
    await setDoc(doc(db, "dogs", otherDogId, "members", "other-member"), {
      uid: "other-member",
      role: "owner",
      status: "active",
    });
    await setDoc(
      trackDocument(db, dogId, existingTrackId),
      metadata(dogId, existingTrackId),
    );
    await setDoc(
      doc(db, "dogs", dogId, "sessions", sessionId),
      sessionDocument(),
    );
    await uploadBytes(
      trackObject(storage, dogId, existingTrackId),
      rawTrack(existingTrackId),
      { contentType: "application/json; charset=utf-8" },
    );
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, "../../../firestore.rules"),
        "utf8",
      ),
    },
    storage: {
      rules: fs.readFileSync(
        path.resolve(__dirname, "../../../storage.rules"),
        "utf8",
      ),
    },
  });
});

test("Session trackEdit read follows active membership", async (t) => {
  for (const role of activeRoles) {
    await t.test(`${role} can read trackEdit`, async () => {
      await assertSucceeds(getDoc(
        doc(firestoreFor(role), "dogs", dogId, "sessions", sessionId),
      ));
    });
  }
  for (const uid of ["non-member", ...inactiveMembers, null]) {
    await t.test(`${uid ?? "unauthenticated"} cannot read trackEdit`, async () => {
      await assertFails(getDoc(
        doc(firestoreFor(uid), "dogs", dogId, "sessions", sessionId),
      ));
    });
  }
});

test("Only owner, admin, and editor can create or update trackEdit", async (t) => {
  for (const role of activeRoles) {
    const shouldWrite = writers.has(role);
    await t.test(`${role} create=${shouldWrite}`, async () => {
      const createdId = `session-create-${role}`;
      const value = sessionDocument(role);
      value.id = createdId;
      value.sessionId = createdId;
      const operation = setDoc(
        doc(firestoreFor(role), "dogs", dogId, "sessions", createdId),
        value,
      );
      await (shouldWrite ? assertSucceeds(operation) : assertFails(operation));
    });
    await t.test(`${role} update=${shouldWrite}`, async () => {
      const changed = trackEdit();
      changed.startIndexInclusive = 0;
      changed.updatedByUserId = role;
      const operation = updateDoc(
        doc(firestoreFor(role), "dogs", dogId, "sessions", sessionId),
        { trackEdit: changed, updatedAt: new Date("2026-01-02T11:00:00.000Z") },
      );
      await (shouldWrite ? assertSucceeds(operation) : assertFails(operation));
    });
  }

  for (const uid of ["non-member", ...inactiveMembers, null]) {
    await t.test(`${uid ?? "unauthenticated"} cannot update`, async () => {
      await assertFails(updateDoc(
        doc(firestoreFor(uid), "dogs", dogId, "sessions", sessionId),
        { trackEdit: trackEdit() },
      ));
    });
  }
});

test("viewer cannot reset edit while managers can", async (t) => {
  const tombstone = {
    schemaVersion: 1,
    deletedAt: new Date("2026-01-03T11:00:00.000Z"),
    updatedAt: new Date("2026-01-03T11:00:00.000Z"),
  };
  await assertFails(updateDoc(
    doc(firestoreFor("viewer"), "dogs", dogId, "sessions", sessionId),
    { trackEdit: tombstone },
  ));
  for (const role of writers) {
    await t.test(`${role} can reset`, async () => {
      await assertSucceeds(updateDoc(
        doc(firestoreFor(role), "dogs", dogId, "sessions", sessionId),
        { trackEdit: tombstone },
      ));
      await seedFixture();
    });
  }
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.clearStorage();
  await seedFixture();
});

after(async () => {
  await testEnv.cleanup();
});

test("Firestore Track read follows active dog membership", async (t) => {
  for (const role of activeRoles) {
    await t.test(`${role} can read`, async () => {
      await assertSucceeds(
        getDoc(trackDocument(firestoreFor(role), dogId, existingTrackId)),
      );
    });
  }

  for (const uid of ["non-member", ...inactiveMembers, null]) {
    await t.test(`${uid ?? "unauthenticated"} cannot read`, async () => {
      await assertFails(
        getDoc(trackDocument(firestoreFor(uid), dogId, existingTrackId)),
      );
    });
  }

  await t.test("member of another dog cannot read", async () => {
    await assertFails(
      getDoc(trackDocument(
        firestoreFor("other-member"),
        dogId,
        existingTrackId,
      )),
    );
  });
});

test("Firestore Track create is limited to active managers", async (t) => {
  for (const role of activeRoles) {
    await t.test(`${role} ${writers.has(role) ? "can" : "cannot"} create`,
      async () => {
        const trackId = `track-create-${role}`;
        const operation = setDoc(
          trackDocument(firestoreFor(role), dogId, trackId),
          metadata(dogId, trackId),
        );
        if (writers.has(role)) {
          await assertSucceeds(operation);
        } else {
          await assertFails(operation);
        }
      });
  }

  for (const uid of ["non-member", ...inactiveMembers, null]) {
    await t.test(`${uid ?? "unauthenticated"} cannot create`, async () => {
      const trackId = `track-create-${uid ?? "unauthenticated"}`;
      await assertFails(setDoc(
        trackDocument(firestoreFor(uid), dogId, trackId),
        metadata(dogId, trackId),
      ));
    });
  }
});

test("Firestore Track metadata is immutable for every role", async (t) => {
  for (const uid of [
    ...activeRoles,
    "non-member",
    ...inactiveMembers,
    null,
  ]) {
    await t.test(`${uid ?? "unauthenticated"} cannot update`, async () => {
      await assertFails(updateDoc(
        trackDocument(firestoreFor(uid), dogId, existingTrackId),
        { source: "changed" },
      ));
    });
    await t.test(`${uid ?? "unauthenticated"} cannot delete`, async () => {
      await assertFails(deleteDoc(
        trackDocument(firestoreFor(uid), dogId, existingTrackId),
      ));
    });
  }
});

test("Firestore rejects wrong dog and mismatched Track paths", async () => {
  const ownerDb = firestoreFor("owner");
  await assertFails(setDoc(
    trackDocument(ownerDb, otherDogId, "track-wrong-dog"),
    metadata(otherDogId, "track-wrong-dog"),
  ));
  await assertFails(setDoc(
    trackDocument(ownerDb, dogId, "track-mismatched-payload"),
    metadata(otherDogId, "track-mismatched-payload"),
  ));
  await assertFails(setDoc(
    doc(ownerDb, "dogs", dogId, "unexpectedTracks", "track-wrong-path"),
    metadata(dogId, "track-wrong-path"),
  ));
});

test("Storage Track read follows active dog membership", async (t) => {
  for (const role of activeRoles) {
    await t.test(`${role} can read`, async () => {
      await assertSucceeds(
        getBytes(trackObject(storageFor(role), dogId, existingTrackId)),
      );
    });
  }

  for (const uid of ["non-member", ...inactiveMembers, null]) {
    await t.test(`${uid ?? "unauthenticated"} cannot read`, async () => {
      await assertFails(
        getBytes(trackObject(storageFor(uid), dogId, existingTrackId)),
      );
    });
  }

  await t.test("member of another dog cannot read", async () => {
    await assertFails(getBytes(trackObject(
      storageFor("other-member"),
      dogId,
      existingTrackId,
    )));
  });
});

test("Storage Track create is limited to active managers", async (t) => {
  for (const role of activeRoles) {
    await t.test(`${role} ${writers.has(role) ? "can" : "cannot"} create`,
      async () => {
        const trackId = `track-create-${role}`;
        const operation = uploadBytes(
          trackObject(storageFor(role), dogId, trackId),
          rawTrack(trackId),
          { contentType: "application/json; charset=utf-8" },
        );
        if (writers.has(role)) {
          await assertSucceeds(operation);
        } else {
          await assertFails(operation);
        }
      });
  }

  for (const uid of ["non-member", ...inactiveMembers, null]) {
    await t.test(`${uid ?? "unauthenticated"} cannot create`, async () => {
      const trackId = `track-create-${uid ?? "unauthenticated"}`;
      await assertFails(uploadBytes(
        trackObject(storageFor(uid), dogId, trackId),
        rawTrack(trackId),
        { contentType: "application/json" },
      ));
    });
  }
});

test("Storage raw Track is immutable for every role", async (t) => {
  for (const uid of [
    ...activeRoles,
    "non-member",
    ...inactiveMembers,
    null,
  ]) {
    await t.test(`${uid ?? "unauthenticated"} cannot overwrite`, async () => {
      await assertFails(uploadBytes(
        trackObject(storageFor(uid), dogId, existingTrackId),
        rawTrack(existingTrackId),
        { contentType: "application/json" },
      ));
    });
    await t.test(`${uid ?? "unauthenticated"} cannot delete`, async () => {
      await assertFails(deleteObject(
        trackObject(storageFor(uid), dogId, existingTrackId),
      ));
    });
  }
});

test("Storage rejects wrong dog, wrong path, and wrong content type", async () => {
  const ownerStorage = storageFor("owner");
  await assertFails(uploadBytes(
    trackObject(ownerStorage, otherDogId, "track-wrong-dog"),
    rawTrack("track-wrong-dog"),
    { contentType: "application/json" },
  ));
  await assertFails(uploadBytes(
    ref(ownerStorage, `dogs/${dogId}/tracks/track-wrong-path/raw.json`),
    rawTrack("track-wrong-path"),
    { contentType: "application/json" },
  ));
  await assertFails(uploadBytes(
    trackObject(ownerStorage, dogId, "track-wrong-content-type"),
    rawTrack("track-wrong-content-type"),
    { contentType: "text/plain" },
  ));
});
