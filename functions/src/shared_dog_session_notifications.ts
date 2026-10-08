export const SHARED_DOG_SESSION_EVENT = "sharedDogSessionCreated";
export const FCM_MULTICAST_LIMIT = 500;

const supportedRoles = new Set(["owner", "admin", "editor", "viewer"]);
const permanentFcmErrorCodes = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);

export interface MemberRecord {
  id: string;
  data: Record<string, unknown>;
}

export interface DeviceRecord {
  id: string;
  path: string;
  data: Record<string, unknown>;
}

export interface MulticastResponseItem {
  success: boolean;
  errorCode?: string;
}

export interface SharedDogSessionDependencies {
  getDog(dogId: string): Promise<Record<string, unknown> | null>;
  listMembers(dogId: string): Promise<MemberRecord[]>;
  getUser(uid: string): Promise<Record<string, unknown> | null>;
  listDevices(uid: string): Promise<DeviceRecord[]>;
  reserveDelivery(input: DeliveryIdentity): Promise<boolean>;
  markDeliverySent(input: DeliveryIdentity): Promise<void>;
  releaseDelivery(input: DeliveryIdentity): Promise<void>;
  disableDevice(path: string): Promise<void>;
  sendMulticast(
    tokens: string[],
    payload: NotificationPayload,
  ): Promise<MulticastResponseItem[]>;
}

export interface DeliveryIdentity {
  eventType: typeof SHARED_DOG_SESSION_EVENT;
  dogId: string;
  sessionId: string;
  recipientUid: string;
}

export interface NotificationPayload {
  notification: { title: string; body: string };
  data: { type: string; dogId: string; sessionId: string };
}

export interface ProcessingSummary {
  recipientCount: number;
  deviceCount: number;
  successCount: number;
  failureCount: number;
  skippedReason?: string;
}

export class TransientDeliveryError extends Error {
  constructor(
    message: string,
    readonly summary: ProcessingSummary,
    readonly cause?: unknown,
  ) {
    super(message);
    this.name = "TransientDeliveryError";
  }
}

interface RecipientTarget {
  delivery: DeliveryIdentity;
  tokens: Set<string>;
}

interface CandidateRecipient {
  delivery: DeliveryIdentity;
  devices: { device: DeviceRecord; token: string }[];
}

interface TokenTarget {
  token: string;
  devicePaths: Set<string>;
}

function nonEmptyString(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim();
  return normalized.length === 0 ? null : normalized;
}

export function isEligibleMember(
  member: MemberRecord,
  creatorUid: string,
): boolean {
  const uid = nonEmptyString(member.data.uid) ?? nonEmptyString(member.id);
  if (uid === null || uid === creatorUid) return false;

  const role = nonEmptyString(member.data.role)?.toLowerCase() ?? null;
  if (role === null || !supportedRoles.has(role)) return false;

  const status = nonEmptyString(member.data.status)?.toLowerCase() ?? null;
  if (status === "active") return true;
  return status === null && role === "owner";
}

export function shouldNotifyUser(
  userData: Record<string, unknown> | null,
): boolean {
  if (userData === null) return true;
  const preferences = userData.notificationPreferences;
  if (typeof preferences !== "object" || preferences === null) return true;
  const value = (preferences as Record<string, unknown>)
    .sharedDogSessionCreated;
  return value !== false;
}

export function activeDeviceToken(device: DeviceRecord): string | null {
  if (device.data.enabled !== true) return null;
  return nonEmptyString(device.data.fcmToken);
}

export function buildNotificationPayload(
  dogId: string,
  sessionId: string,
  dogName: unknown,
): NotificationPayload {
  const name = nonEmptyString(dogName);
  return {
    notification: {
      title: "GundogTracker",
      body: name === null
        ? "Ny økt registrert på en delt hund"
        : `Ny økt registrert for ${name}`,
    },
    data: {
      type: SHARED_DOG_SESSION_EVENT,
      dogId,
      sessionId,
    },
  };
}

export function isPermanentFcmError(errorCode: string | undefined): boolean {
  return errorCode !== undefined && permanentFcmErrorCodes.has(errorCode);
}

export function chunk<T>(items: T[], size = FCM_MULTICAST_LIMIT): T[][] {
  const result: T[][] = [];
  for (let index = 0; index < items.length; index += size) {
    result.push(items.slice(index, index + size));
  }
  return result;
}

export async function processSharedDogSessionCreated(
  input: {
    dogId: string;
    sessionId: string;
    sessionData: Record<string, unknown> | null;
  },
  dependencies: SharedDogSessionDependencies,
): Promise<ProcessingSummary> {
  const { dogId, sessionId, sessionData } = input;
  if (sessionData === null) return skipped("missing-session");
  if (sessionData.deletedAt !== undefined && sessionData.deletedAt !== null) {
    return skipped("tombstone");
  }
  const creatorUid = nonEmptyString(sessionData.createdByUserId);
  if (creatorUid === null) return skipped("missing-creator");

  const dog = await dependencies.getDog(dogId);
  if (dog === null) return skipped("missing-dog");

  const members = await dependencies.listMembers(dogId);
  const eligibleMembers = members.filter((member) =>
    isEligibleMember(member, creatorUid));
  if (eligibleMembers.length === 0) return skipped("no-recipients");

  const candidates: CandidateRecipient[] = [];

  for (const member of eligibleMembers) {
    const uid = nonEmptyString(member.data.uid) ?? nonEmptyString(member.id);
    if (uid === null) continue;
    const user = await dependencies.getUser(uid);
    if (!shouldNotifyUser(user)) continue;

    const devices = await dependencies.listDevices(uid);
    const activeDevices = devices
      .map((device) => ({ device, token: activeDeviceToken(device) }))
      .filter((entry): entry is { device: DeviceRecord; token: string } =>
        entry.token !== null);
    if (activeDevices.length === 0) continue;

    const delivery: DeliveryIdentity = {
      eventType: SHARED_DOG_SESSION_EVENT,
      dogId,
      sessionId,
      recipientUid: uid,
    };
    candidates.push({ delivery, devices: activeDevices });
  }

  if (candidates.length === 0) return skipped("no-devices");

  const recipientTargets: RecipientTarget[] = [];
  const tokenTargets = new Map<string, TokenTarget>();
  try {
    for (const candidate of candidates) {
      if (!(await dependencies.reserveDelivery(candidate.delivery))) continue;
      const recipient = {
        delivery: candidate.delivery,
        tokens: new Set<string>(),
      };
      recipientTargets.push(recipient);
      for (const { device, token } of candidate.devices) {
        recipient.tokens.add(token);
        const target = tokenTargets.get(token) ?? {
          token,
          devicePaths: new Set<string>(),
        };
        target.devicePaths.add(device.path);
        tokenTargets.set(token, target);
      }
    }
  } catch (error) {
    await Promise.all(recipientTargets.map((recipient) =>
      dependencies.releaseDelivery(recipient.delivery)));
    throw error;
  }

  if (tokenTargets.size === 0) return skipped("no-devices");

  const dogDisplayName = nonEmptyString(dog.nickname) ??
    nonEmptyString(dog.name);
  const payload = buildNotificationPayload(dogId, sessionId, dogDisplayName);
  const targets = [...tokenTargets.values()];
  const outcomes = new Map<string, MulticastResponseItem>();
  let sendError: unknown = null;

  for (const batch of chunk(targets)) {
    try {
      const responses = await dependencies.sendMulticast(
        batch.map((target) => target.token),
        payload,
      );
      batch.forEach((target, index) => {
        outcomes.set(target.token, responses[index] ?? {
          success: false,
          errorCode: "messaging/unknown-error",
        });
      });
    } catch (error) {
      sendError = error;
      break;
    }
  }

  let successCount = 0;
  let failureCount = 0;
  const devicesToDisable = new Set<string>();
  for (const target of targets) {
    const outcome = outcomes.get(target.token);
    if (outcome?.success === true) {
      successCount++;
    } else {
      failureCount++;
      if (outcome !== undefined && isPermanentFcmError(outcome.errorCode)) {
        target.devicePaths.forEach((path) => devicesToDisable.add(path));
      }
    }
  }
  // Cleanup is best-effort. A failed cleanup must not retry already delivered
  // notifications; the same invalid token will be retried on a later event.
  await Promise.allSettled([...devicesToDisable].map((path) =>
    dependencies.disableDevice(path)));

  let shouldRetry = sendError !== null;
  for (const recipient of recipientTargets) {
    const recipientOutcomes = [...recipient.tokens]
      .map((token) => outcomes.get(token));
    const hasSuccess = recipientOutcomes.some((outcome) =>
      outcome?.success === true);
    const hasTransientFailure = recipientOutcomes.some((outcome) =>
      outcome === undefined ||
      (outcome.success === false && !isPermanentFcmError(outcome.errorCode)));
    if (hasTransientFailure && !hasSuccess) {
      await dependencies.releaseDelivery(recipient.delivery);
      shouldRetry = true;
    } else {
      await dependencies.markDeliverySent(recipient.delivery);
    }
  }

  if (shouldRetry) {
    throw new TransientDeliveryError(
      "Transient FCM delivery failure",
      {
        recipientCount: recipientTargets.length,
        deviceCount: targets.length,
        successCount,
        failureCount,
      },
      sendError,
    );
  }

  return {
    recipientCount: recipientTargets.length,
    deviceCount: targets.length,
    successCount,
    failureCount,
  };
}

function skipped(reason: string): ProcessingSummary {
  return {
    recipientCount: 0,
    deviceCount: 0,
    successCount: 0,
    failureCount: 0,
    skippedReason: reason,
  };
}
