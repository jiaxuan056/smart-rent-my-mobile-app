# SmartRent MY

> This is a collaborative mobile-development assignment. The repository is
> published as a portfolio copy with the original group contributors credited
> in [PROJECT_CREDITS.md](PROJECT_CREDITS.md).

SmartRent MY is a Flutter mobile application that combines car-rental
planning with Malaysian government open data. It helps customers compare the
complete estimated cost of a journey instead of comparing only daily rental
rates.

## Implemented customer functions

- Local registration, sign-in and session routing
- Password validation from 8 to 30 characters
- Hashed recovery phrase, forgot-password flow and signed-in password change
- Editable display name, phone number and Android profile photo
- Thirteen-vehicle catalogue with sourced real photographs and offline fallbacks
- Search plus fuel, transmission, seats and daily-price filters
- Smart vehicle recommendations based on dates, passengers, distance, fuel and budget
- Favourites and two-to-three-car comparison
- Official weekly fuel prices from data.gov.my
- Petrol, diesel, hybrid and electric trip-cost calculations
- Date-based availability and overlapping-booking prevention
- Stripe-style test payment simulation with success and decline scenarios
- Active bookings separated from completed and cancelled booking history
- Confirmed, ongoing, completed and cancelled booking statuses
- In-app booking notifications
- Reviews and ratings after a completed rental
- Digital receipt with a QR code and private PDF export
- Vehicle-registration trend dashboard with hybrid category handling
- Government-data attribution and SDG 9 explanation

## Implemented administrator functions

- Separate administrator demonstration mode
- Dashboard with booking, vehicle, customer and revenue summaries
- Search, filter and sort all booking records
- Controlled booking transitions: confirmed to ongoing or cancelled, then ongoing to completed
- Vehicle search and availability filters
- Add and edit rental vehicles, including a private Android photo upload
- Mark vehicles available, unavailable, under maintenance or deactivated
- Search customers and inspect their booking totals without exposing password hashes
- Review moderation with hide and restore actions

## Government datasets

### Price of Petroleum and Diesel

- Dataset ID: `fuelprice`
- Publisher: Ministry of Finance Malaysia
- API: `https://api.data.gov.my/data-catalogue?id=fuelprice`

The application uses the latest available RON95, RON97 and Peninsular
Malaysia diesel prices in its trip-cost calculations.

### Monthly Vehicle Registrations by Vehicle and Fuel Type

- Dataset ID: `registrations_type_fuel`
- Publishers: Road Transport Department and Ministry of Transport
- API: `https://api.data.gov.my/data-catalogue?id=registrations_type_fuel`

The dashboard filters car records and excludes aggregate fuel and vehicle-type
rows. Figures represent vehicle registrations, not sales. Both datasets are
available under the Creative Commons Attribution 4.0 International licence.

## Vehicle catalogue data and imagery

Rental prices and branches are demonstration values created for this student
prototype. New-model efficiency values are linked to official manufacturer
references inside the vehicle records. Real vehicle photographs come from
Wikimedia Commons under their stated reusable licences. Complete credits are
listed in `docs/IMAGE_ATTRIBUTIONS.md`.

Some photographs are bundled locally. Others are loaded from their Wikimedia
thumbnail URLs and fall back to the original project illustration or a
coloured vehicle placeholder if the network is unavailable.

## Cost formulas

For petrol, diesel and hybrid vehicles:

```text
Fuel required = expected distance / vehicle efficiency
Fuel cost = fuel required * latest official fuel price
```

For electric vehicles:

```text
Energy required = expected distance * kWh per 100 km / 100
Charging cost = energy required * configured charging rate
```

The electric charging rate is explicitly labelled as a SmartRent MY
configuration and not Malaysian government data.

## Payment simulation

The checkout is a local Stripe-style test simulator. It does not transmit card
details, contact Stripe or charge money. Successful test payments create a
test payment reference before the booking is saved.

- Success card: `4242 4242 4242 4242`
- Declined card: `4000 0000 0000 0002`
- Expiry: any future `MM/YY`, such as `12/34`
- CVC: any three digits

A real Stripe integration must create its PaymentIntent through a secure
backend. A Stripe secret key must never be embedded in this Flutter project.

## Demonstration roles

The sign-in page includes two classroom shortcuts:

- `Enter demonstration mode` opens the customer app with seeded active and historical bookings.
- `Enter admin demonstration mode` opens the staff dashboard and management tools.

Register a real local account when testing profile editing, password changes
or recovery-phrase validation.

## SDG 9 alignment

SmartRent MY supports SDG 9 by applying mobile technology and Malaysian
government open data to improve transport decision-making, encourage
cost-efficient mobility and increase awareness of newer vehicle technologies.

## Run the application

Group members receiving the project as a ZIP should first read
`GROUP_MEMBER_SETUP.md`.

```powershell
flutter pub get
flutter run
```

## Verify the project

```powershell
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

## Local and cloud data status

This version is fully usable without cloud credentials. It saves two JSON
records in Android private app storage:

- `smartrent_accounts.json` stores profiles and salted password/recovery hashes.
- `smartrent_app_data.json` stores vehicles, bookings, favourites, notifications and reviews.

Profile, vehicle and receipt files are also saved in private subfolders. Data
is local to each emulator or phone and is not synchronised between group
members. A future Supabase schema with Row Level Security is provided in
`supabase/schema.sql`; see `docs/SUPABASE_SETUP.md` before connecting it.

Production password recovery should use verified email rather than a security
phrase, and real payments must be implemented through a secure backend.
