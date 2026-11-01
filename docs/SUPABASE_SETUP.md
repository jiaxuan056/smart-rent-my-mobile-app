# Supabase setup

The current application runs without Supabase so every customer and
administrator workflow can be demonstrated immediately. Its JSON records are
local to one emulator or phone. Connect Supabase only when the team is ready
for shared multi-device records.

## Create the backend

1. Create a free Supabase project.
2. Open the Supabase SQL Editor.
3. Review and run `supabase/schema.sql`.
4. Enable email authentication.
5. Create staff users normally, then change only approved profile rows to
   `role = 'admin'` through the Supabase dashboard.
6. Copy the project URL and client-safe publishable or anonymous key.
7. Never place a service-role key or Stripe secret key in Flutter.

## Planned Flutter configuration

Supply client-safe values at runtime:

```powershell
flutter run --dart-define=SUPABASE_URL=YOUR_PROJECT_URL --dart-define=SUPABASE_ANON_KEY=YOUR_CLIENT_SAFE_KEY
```

Installing the package and passing these values does not automatically replace
the local repositories. A team member must implement Supabase repositories for
profiles, cars, bookings, favourites, notifications and reviews, then inject
them into `AppState`.

## Security model

The schema enables Row Level Security on every application table.

- Customers can read and update their own profile.
- Customers can create and read their own bookings.
- Administrators manage vehicles and booking statuses.
- Customers manage only their own favourites and notifications.
- A customer can review only their own completed booking once.
- Administrators can hide or restore reviews.
- Deactivated vehicles remain visible to administrators only.

Customer cancellation and all real payment confirmation should be implemented
through a secure database function or backend endpoint. Do not let a Flutter
client freely edit booking totals, payment references or arbitrary statuses.

The fuel-price snapshot fields preserve the values used for each estimate so
an old booking does not change when official weekly prices are updated.
