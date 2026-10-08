const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const {
  buildNotificationPayload,
  isEligibleMember,
  isPermanentFcmError,
  processSharedDogSessionCreated,
  shouldNotifyUser,
} = require("../lib/shared_dog_session_notifications.js");

function member(uid, role = "viewer", status = "active") {
  const data = { uid, role };
  if (status !== undefined) data.status = status;
  return { id: uid, data };
}

function device(id, token, enabled = true) {
  return {
    id,
    path: `users/recipient/devices/${id}`,
    data: { fcmToken: token, enabled },
  };
}

function createDependencies(overrides = {}) {
  const state = {
    dog: { name: "Zoë" },
    members: [member("creator", "owner"), member("recipient")],
    users: new Map(),
    devices: new Map([["recipient", [device("phone", "token-1")]]]),
    reservations: new Set(),
    sentDeliveries: [],
    releasedDeliveries: [],
    disabledPaths: [],
    multicastCalls: [],
  };
  const deliveryKey = (value) =>
    `${value.dogId}:${value.sessionId}:${value.recipientUid}`;
  const dependencies = {
    async getDog() { return state.dog; },
    async listMembers() { return state.members; },
    async getUser(uid) { return state.users.get(uid) ?? null; },
    async listDevices(uid) { return state.devices.get(uid) ?? []; },
    async reserveDelivery(value) {
      const key = deliveryKey(value);
      if (state.reservations.has(key)) return false;
      state.reservations.add(key);
      return true;
    },
    async markDeliverySent(value) { state.sentDeliveries.push(value); },
    async releaseDelivery(value) {
      state.reservations.delete(deliveryKey(value));
      state.releasedDeliveries.push(value);
    },
    async disableDevice(devicePath) {
      state.disabledPaths.push(devicePath);
    },
    async sendMulticast(tokens, payload) {
      state.multicastCalls.push({ tokens, payload });
      return tokens.map(() => ({ success: true }));
    },
    ...overrides,
  };
  return { state, dependencies };
}

function process(dependencies, sessionData = { createdByUserId: "creator" }) {
  return processSharedDogSessionCreated({
    dogId: "dog-path-id",
    sessionId: "session-path-id",
    sessionData,
  }, dependencies);
}

test("creator is excluded while another active member receives push", async () => {
  const { state, dependencies } = createDependencies();
  const summary = await process(dependencies);
  assert.equal(summary.recipientCount, 1);
  assert.deepEqual(state.multicastCalls[0].tokens, ["token-1"]);
  assert.equal(state.sentDeliveries[0].recipientUid, "recipient");
});

test("creator as only member results in no push", async () => {
  const { state, dependencies } = createDependencies();
  state.members = [member("creator", "owner")];
  const summary = await process(dependencies);
  assert.equal(summary.skippedReason, "no-recipients");
  assert.equal(state.multicastCalls.length, 0);
});

test("pending and revoked members are ineligible", () => {
  assert.equal(isEligibleMember(member("a", "viewer", "pending"), "creator"), false);
  assert.equal(isEligibleMember(member("b", "editor", "revoked"), "creator"), false);
  assert.equal(isEligibleMember(member("c", "admin", "cancelled"), "creator"), false);
  assert.equal(isEligibleMember(member("d", "owner", "expired"), "creator"), false);
});

test("legacy owner without status is eligible", () => {
  assert.equal(isEligibleMember({
    id: "owner",
    data: { uid: "owner", role: "owner" },
  }, "creator"), true);
  assert.equal(isEligibleMember({
    id: "viewer",
    data: { uid: "viewer", role: "viewer" },
  }, "creator"), false);
});

test("false preference suppresses push and missing preference allows it", async () => {
  assert.equal(shouldNotifyUser({
    notificationPreferences: { sharedDogSessionCreated: false },
  }), false);
  assert.equal(shouldNotifyUser({ notificationPreferences: {} }), true);
  assert.equal(shouldNotifyUser(null), true);

  const { state, dependencies } = createDependencies();
  state.users.set("recipient", {
    notificationPreferences: { sharedDogSessionCreated: false },
  });
  const summary = await process(dependencies);
  assert.equal(summary.skippedReason, "no-devices");
  assert.equal(state.multicastCalls.length, 0);
});

test("disabled devices are ignored", async () => {
  const { state, dependencies } = createDependencies();
  state.devices.set("recipient", [device("old", "old-token", false)]);
  const summary = await process(dependencies);
  assert.equal(summary.skippedReason, "no-devices");
  assert.equal(state.multicastCalls.length, 0);
});

test("multiple devices are included and duplicate tokens are sent once", async () => {
  const { state, dependencies } = createDependencies();
  state.devices.set("recipient", [
    device("phone", "token-1"),
    device("tablet", "token-2"),
    device("duplicate", "token-1"),
  ]);
  const summary = await process(dependencies);
  assert.equal(summary.deviceCount, 2);
  assert.deepEqual(state.multicastCalls[0].tokens, ["token-1", "token-2"]);
});

test("more than 500 tokens are split into multicast batches", async () => {
  const { state, dependencies } = createDependencies();
  state.devices.set("recipient", Array.from({ length: 501 }, (_, index) =>
    device(`device-${index}`, `token-${index}`)));
  const summary = await process(dependencies);
  assert.equal(summary.deviceCount, 501);
  assert.equal(state.multicastCalls.length, 2);
  assert.equal(state.multicastCalls[0].tokens.length, 500);
  assert.equal(state.multicastCalls[1].tokens.length, 1);
});

test("tombstone and missing creator stop without push", async () => {
  const tombstone = createDependencies();
  assert.equal(
    (await process(tombstone.dependencies, {
      createdByUserId: "creator",
      deletedAt: "timestamp",
    })).skippedReason,
    "tombstone",
  );
  assert.equal(tombstone.state.multicastCalls.length, 0);

  const missingCreator = createDependencies();
  assert.equal(
    (await process(missingCreator.dependencies, {})).skippedReason,
    "missing-creator",
  );
  assert.equal(missingCreator.state.multicastCalls.length, 0);
});

test("missing session or dog stops without push", async () => {
  const missingSession = createDependencies();
  assert.equal(
    (await processSharedDogSessionCreated({
      dogId: "dog-path-id",
      sessionId: "session-path-id",
      sessionData: null,
    }, missingSession.dependencies)).skippedReason,
    "missing-session",
  );

  const missingDog = createDependencies();
  missingDog.state.dog = null;
  assert.equal(
    (await process(missingDog.dependencies)).skippedReason,
    "missing-dog",
  );
  assert.equal(missingDog.state.multicastCalls.length, 0);
});

test("payload uses authoritative path ids and dog name", async () => {
  const { state, dependencies } = createDependencies();
  await process(dependencies, {
    createdByUserId: "creator",
    dogId: "untrusted-dog",
    sessionId: "untrusted-session",
  });
  assert.deepEqual(state.multicastCalls[0].payload, {
    notification: {
      title: "GundogTracker",
      body: "Ny økt registrert for Zoë",
    },
    data: {
      type: "sharedDogSessionCreated",
      dogId: "dog-path-id",
      sessionId: "session-path-id",
    },
  });
  assert.equal(
    buildNotificationPayload("dog", "session", "").notification.body,
    "Ny økt registrert på en delt hund",
  );
});

test("dog nickname is preferred as the existing display name", async () => {
  const { state, dependencies } = createDependencies();
  state.dog = { name: "Kennelnavn", nickname: "Zoë" };
  await process(dependencies);
  assert.equal(
    state.multicastCalls[0].payload.notification.body,
    "Ny økt registrert for Zoë",
  );
});

test("permanent invalid token disables device and completes delivery", async () => {
  const { state, dependencies } = createDependencies({
    async sendMulticast(tokens, payload) {
      state.multicastCalls.push({ tokens, payload });
      return [{
        success: false,
        errorCode: "messaging/registration-token-not-registered",
      }];
    },
  });
  const summary = await process(dependencies);
  assert.equal(summary.failureCount, 1);
  assert.deepEqual(state.disabledPaths, ["users/recipient/devices/phone"]);
  assert.equal(state.sentDeliveries.length, 1);
  assert.equal(isPermanentFcmError("messaging/invalid-registration-token"), true);
});

test("transient FCM error preserves device and releases delivery for retry", async () => {
  const { state, dependencies } = createDependencies({
    async sendMulticast(tokens, payload) {
      state.multicastCalls.push({ tokens, payload });
      return [{ success: false, errorCode: "messaging/internal-error" }];
    },
  });
  await assert.rejects(() => process(dependencies), /Transient FCM/);
  assert.deepEqual(state.disabledPaths, []);
  assert.equal(state.releasedDeliveries.length, 1);
  assert.equal(state.sentDeliveries.length, 0);
});

test("same event and recipient is suppressed by atomic reservation", async () => {
  const { state, dependencies } = createDependencies();
  await process(dependencies);
  const repeated = await process(dependencies);
  assert.equal(repeated.skippedReason, "no-devices");
  assert.equal(state.multicastCalls.length, 1);
});

test("source exports an onCreate trigger, not an update trigger", () => {
  const source = fs.readFileSync(
    path.join(__dirname, "../src/index.ts"),
    "utf8",
  );
  assert.match(source, /onSharedDogSessionCreated[\s\S]*\.onCreate\(/);
  assert.doesNotMatch(source, /onSharedDogSessionCreated[\s\S]*\.onWrite\(/);
  assert.doesNotMatch(source, /onSharedDogSessionCreated[\s\S]*\.onUpdate\(/);
});
