# Release-sjekkliste (iPad/iPhone) før App Store-upload

Denne sjekklisten skal brukes før opplasting til App Store Connect.

## 1. Automatisk sjekk

Kjør disse kommandoene i rekkefølge:

- [ ] fvm flutter clean
- [ ] fvm flutter pub get
- [ ] fvm flutter gen-l10n
- [ ] fvm flutter analyze
- [ ] fvm flutter test

## 2. Fysisk enhet-test før upload

- [ ] Installer release/test build på iPad
- [ ] Installer eller test på liten iPhone/simulator
- [ ] Start appen helt på nytt etter lagringstester
- [ ] Test offline hvis relevant

## 3. Kritiske regresjonstester (manuell avkryssing)

- [ ] Stamtavlelink lagres etter restart
- [ ] Profilbilde på hund lagres etter restart
- [ ] Kjønn hanhund/tispe lagres etter restart
- [ ] Administratorrolle beholdes etter restart
- [ ] Pro-status viser riktig etter kjøp/restore
- [ ] Pro-rubrikk er kompakt når Pro er aktiv
- [ ] Oppgrader til Pro-knapp er trykkbar når ikke-Pro
- [ ] Brukerprofil lagres etter restart
- [ ] Personlig standmål lagres og viser korrekt progress
- [ ] Målgratulasjon vises bare én gang per mål
- [ ] Bursdagshilsen vises bare én gang samme dag
- [ ] Løpetid vises kun for tisper
- [ ] Løpetid lagres etter restart
- [ ] Løpetid kan redigeres/slettes
- [ ] Home/dashboard viser mål, siste økt og start-knapp
- [ ] Ingen tekst/tall brytes stygt på iPad eller liten skjerm
- [ ] Språk sjekkes på norsk og engelsk

## 4. App Store upload-gate

Do not upload to App Store Connect until this checklist is completed.

## 5. Sign-off

- Dato:
- Testet av:
- Enheter testet:
- iOS-versjon:
- Build/version:
- Godkjent for upload (ja/nei):

## Arbeidsregler

- Kun dokumentasjon.
- Ikke endre appkode.
- Ikke merge til main.
- Ikke send App Store-build.