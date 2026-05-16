# Fix shared dog leave permission-denied

## Problem

When a shared user tries to leave/remove a shared dog, Firestore returns:

```text
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
