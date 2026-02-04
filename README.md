# jakthund_app

A new Flutter project.

## Authentication / Login (Intentional design choice)

Dette er et bevisst designvalg i na-vaerende fase.

- Offline-first na: appen fungerer fullt ut uten konto og uten palogging.
- Hvorfor login ikke er med na: tidlig fase, fokus pa lokal UX, og ingen cloud sync a stotte enda.
- Planlagt fremtidig oppforsel: login skal bare komme nar cloud sync aktiveres og brukeren velger det.
- Teknisk note: domenelag og sync er forberedt, men auth er ikke wired.

### TODO / Guardrails

Se `docs/roadmap.md` for guardrails rundt autentisering/login.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Testing

Use `./tool/test_fast.sh` and `./tool/test_all.sh` for the recommended fast/full suites and `flutter test --tags slow` when you need the slow fixtures. See `tools/TESTING.md` for details on the engine stamp issue and how to keep `flutter test` working without escalated privileges.

### Manual QA: Milestones (10 min)

1. Start a new session for a dog that has fewer than 10 stand/ session milestones logged.
2. Hit “Save” when a milestone threshold (e.g., `stands_1`) is crossed so MilestoneService awards a new ID.
3. Expect the “Ny milepæl!” SnackBar to appear with the dog’s name and at least one milestone title.
4. Tap **Se** – it should open that dog’s detail page and show the milestone list with the new entry.
5. Save the same dog/session again – no duplicate milestone should fire, only the fallback “lagret” toast if nothing new is earned.
6. Force-close the app and restart – the milestone list should still show the achieved IDs from `DogMilestoneState`.
7. Switch to another dog and repeat – milestones should never leak between dogs.
