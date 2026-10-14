const fs = require("node:fs");
const path = require("node:path");
const { after, before, beforeEach, test } = require("node:test");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const { deleteDoc, doc, getDoc, setDoc, updateDoc } = require("firebase/firestore");

const projectId = "demo-jakthund-event-rules";
const dogId = "dog-events";
const eventId = "event-1";
const roles = ["owner", "admin", "editor", "viewer"];
const writers = new Set(["owner", "admin", "editor"]);
let testEnv;

function db(uid) {
  return uid == null
    ? testEnv.unauthenticatedContext().firestore()
    : testEnv.authenticatedContext(uid).firestore();
}

function eventDoc(database, id = eventId, targetDog = dogId) {
  return doc(database, "dogs", targetDog, "events", id);
}

function payload(creator = "owner", id = eventId, targetDog = dogId) {
  return {
    eventId: id,
    sessionId: "session-1",
    dogId: targetDog,
    type: "stand",
    occurredAt: new Date("2026-01-01T10:00:00Z"),
    sourceTrackId: "track-1",
    trackPointIndex: 4,
    latitude: 60.1,
    longitude: 10.2,
    birdSpecies: null,
    note: null,
    source: "manual",
    sourceWaypointName: null,
    sourceWaypointSymbol: null,
    createdAt: new Date("2026-01-01T10:00:00Z"),
    updatedAt: new Date("2026-01-01T10:00:00Z"),
    createdByUserId: creator,
    updatedByUserId: creator,
    deletedAt: null,
    schemaVersion: 1,
  };
}

async function seed() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const database = context.firestore();
    for (const role of roles) {
      await setDoc(doc(database, "dogs", dogId, "members", role), {
        uid: role,
        role,
        status: "active",
      });
    }
    for (const status of ["pending", "revoked"]) {
      await setDoc(doc(database, "dogs", dogId, "members", status), {
        uid: status,
        role: "editor",
        status,
      });
    }
    await setDoc(doc(database, "dogs", "other-dog", "members", "other"), {
      uid: "other",
      role: "owner",
      status: "active",
    });
    await setDoc(eventDoc(database), payload());
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(path.resolve(__dirname, "../../../firestore.rules"), "utf8"),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await seed();
});

after(async () => testEnv.cleanup());

test("active roles read; inactive, wrong-dog and unauthenticated users do not", async (t) => {
  for (const role of roles) {
    await t.test(`${role} reads`, () => assertSucceeds(getDoc(eventDoc(db(role)))));
  }
  for (const uid of ["pending", "revoked", "non-member", "other", null]) {
    await t.test(`${uid ?? "unauthenticated"} denied`, () =>
      assertFails(getDoc(eventDoc(db(uid)))));
  }
});

test("owner admin editor create/update tombstones; viewer cannot write", async (t) => {
  for (const role of roles) {
    const allowed = writers.has(role);
    await t.test(`${role} create=${allowed}`, async () => {
      const id = `created-${role}`;
      const operation = setDoc(eventDoc(db(role), id), payload(role, id));
      await (allowed ? assertSucceeds(operation) : assertFails(operation));
    });
    await t.test(`${role} update=${allowed}`, async () => {
      const operation = updateDoc(eventDoc(db(role)), {
        note: "updated",
        updatedAt: new Date("2026-01-02T10:00:00Z"),
        updatedByUserId: role,
      });
      await (allowed ? assertSucceeds(operation) : assertFails(operation));
      if (allowed) await seed();
    });
  }
  await assertSucceeds(updateDoc(eventDoc(db("owner")), {
    deletedAt: new Date("2026-01-03T10:00:00Z"),
    updatedAt: new Date("2026-01-03T10:00:00Z"),
  }));
  await assertFails(deleteDoc(eventDoc(db("owner"))));
});

test("invalid identity type coordinates and creator mutation are denied", async () => {
  const invalidId = payload("owner", "wrong-id");
  await assertFails(setDoc(eventDoc(db("owner"), "new-id"), invalidId));

  const invalidType = payload("owner", "bad-type");
  invalidType.type = "unknown";
  await assertFails(setDoc(eventDoc(db("owner"), "bad-type"), invalidType));

  const invalidCoordinates = payload("owner", "bad-coordinates");
  invalidCoordinates.latitude = 91;
  await assertFails(setDoc(eventDoc(db("owner"), "bad-coordinates"), invalidCoordinates));

  await assertFails(updateDoc(eventDoc(db("owner")), {
    createdByUserId: "editor",
    updatedAt: new Date("2026-01-02T10:00:00Z"),
  }));
});
