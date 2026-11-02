# DZDS Agent

An Android AI assistant that operates the Algerian national digital-services
portal ([dzds.dz](https://dzds.dz)) on your behalf. It is driven by **Gemini**
(function-calling), which decides and performs the steps for you — login,
browsing services, filling forms, and downloading certificates.

> Built in **Flutter**. The exact API flow was reverse-engineered from a real
> captured session of the portal.

## What the AI does

You chat with it in natural language, for example:

- *"log in"*
- *"get my electronic certificates"*
- *"apply for the CNAS affiliation certificate"*
- attach a photo of your ID card / birth certificate and say *"fill the form
  with this"*

Gemini decides which **tool** to call, one step at a time, and the app executes
it against the real portal.

## Features

| Feature | Status |
|---|---|
| SSO login (password + SMS) | ✅ full flow |
| Slider ("block puzzle") captcha | ✅ human-in-the-loop |
| SMS OTP auto-read | ✅ native `RECEIVE_SMS` + SMS Retriever |
| Browse services | ✅ (scene config) |
| Start application (scene instance) | ✅ |
| List / view / download certificates | ✅ |
| Document OCR → form fields | ✅ Gemini vision |
| Dynamic form engine (`encData`) | ⚠️ integration point (see below) |

## Project layout

```
lib/
  core/
    config.dart            # base URLs, Gemini model, API key
    network/
      api_client.dart      # Dio + shared cookie jar
      endpoints.dart       # every portal/SSO endpoint
    storage/secure_store.dart
  models/domain.dart       # UserSession, CaptchaPuzzle, Certificate…
  features/
    agent/agent_controller.dart   # Gemini ↔ tools loop + events
    ai/
      gemini_service.dart         # Gemini wrapper (function calling)
      document_extractor.dart     # Gemini vision → structured fields
      tools.dart                  # tool declarations + executor
    auth/
      sso_client.dart             # real SSO login flow
      sms_service.dart            # OTP reader
    services/portal_client.dart   # services + certificates
  ui/
    screens/home_screen.dart      # chat UI
    screens/settings_screen.dart  # API key + credentials
    widgets/captcha_dialog.dart   # slider puzzle
    widgets/sms_dialog.dart       # OTP entry
android/app/src/main/kotlin/.../MainActivity.kt   # native SMS receiver
```

## Setup

1. Get a **Gemini API key** from
   [Google AI Studio](https://aistudio.google.com/apikey).

2. Either pass it at build time:
   ```bash
   flutter run --dart-define=GEMINI_API_KEY=AIza...
   ```
   …or enter it in the in-app **Settings** screen (it is stored in the Android
   Keystore via `flutter_secure_storage`).

3. (Optional) In **Settings**, store your portal username/password so the agent
   can log in for you. Credentials are stored securely.

4. Run:
   ```bash
   cd dzds_agent
   flutter pub get
   flutter run
   ```

## How login + captcha + SMS works

1. `POST /api/auth/signin/cms` → SSO authorize URL.
2. Follow redirects to obtain the OAuth `lck` context.
3. `queryAuthMethods` → password auth chain.
4. `captcha/getBlockPuzzle` → background + jigsaw images + token.
5. **You** drag the slider once (`CaptchaDialog`); the app submits
   `checkCaptcha` with `pointJson` + token.
6. `sendSms` → the app reads the OTP from your phone (native `RECEIVE_SMS`
   receiver + SMS Retriever) and auto-fills it.
7. `authExecute` (password) → `authExecute` (SMS code) → `authnEngine` →
   OAuth callback → session established.

The captcha is deliberately **human-in-the-loop**: a captcha exists to stop
bots, so the app never tries to auto-solve it.

## Known integration point — form engine `encData`

The dynamic forms (`/formCenter/well/form/filling/*`) encrypt their payloads
with a hybrid AES + RSA scheme (`{"encData":"…"}` + the `Hoox-Data-Key`
header), implemented in the portal's browser JS. Replicating it requires that
JS. This repository ships the complete login / service / certificate flows and
the form client scaffolding; the `encData` encryption is the one piece to
finish before fully-automatic form submission works end-to-end.

## Legal note

Use this only with **your own account**. Automating a government portal is
subject to its terms of service and local law; do not use it to bypass security
controls or to act on behalf of others.
