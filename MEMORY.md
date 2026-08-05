# Auth feature memory

## Local development

- Install Supabase CLI with `brew install supabase/tap/supabase`.
- Generate local settings with `./scripts/run-app.sh`.
- Run debug with `flutter run --dart-define-from-file=env/dev.json`.
- Run profile with `flutter run --profile --dart-define-from-file=env/dev.json`.
- For Android Emulator, generate with `FLEETGO_SUPABASE_HOST=10.0.2.2 ./scripts/run-app.sh`.
- Run release with `flutter run --release --dart-define-from-file=env/prod.json`.
- Reset local data with `supabase db reset`.
- Run database tests with `supabase test db`.
- Run database advisors with `supabase db advisors --local`.
- The script starts local Supabase and writes its current public settings to env/dev.json.
- Release reads env/prod.json. Missing production values stop startup.
- Local owner: `owner@fleetgo.local`.
- Local password: `LocalPass123!`.

## Supabase configuration

- Auth callback: `com.cuboidinc.fleetgo://auth-callback`.
- Add the callback under Authentication, URL Configuration, Additional Redirect URLs.
- Self-service signup stays disabled.
- Password minimum is 8 characters.
- The mobile app stores only the public key.
- The invite-staff function keeps the secret key server-side.

## Remote setup

1. Run `supabase login`.
2. Run `supabase link --project-ref YOUR_PROJECT_REF`.
3. Run `supabase db push`.
4. Run `supabase functions deploy invite-staff`.
5. Create the first Auth user, tenant, owner membership, profile, and access-pack rows through an approved bootstrap SQL operation.

## Auth decisions

- Supabase Auth owns passwords and sessions.
- PostgreSQL membership rows own tenant access and roles.
- RLS remains the security boundary. UI permission checks only hide unavailable actions.
- Invitation links create a session. The invited member sets a password, then accept_invitation activates the membership.
- Suspended or missing membership routes to Access unavailable.
- Staff invitations run through one authenticated Edge Function. The mobile app never receives a secret key.
- Feature code uses showSuccess, showError, showWarning, or showInfo for snackbars.
