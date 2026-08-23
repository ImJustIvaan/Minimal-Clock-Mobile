# Minimal Clock

A minimal, distraction-free clock app built with Flutter, with companion
apps for iOS home screen widgets, Apple Watch, and tvOS, plus an Android
home screen widget.

## Features

### Clock
- Large, minimal digital clock with animated digit transitions
- 12/24-hour format, optional seconds, date, and weekday display
- Configurable font family and size
- World clocks: add tiles for other timezones alongside the main clock
- "Keep screen awake" option
- Optional hourly chime notification
- UI can be hidden for a fully distraction-free display

### Timer
- Set a countdown by duration or by a specific "until" time of day
- Circular progress ring with remaining time
- Background-resilient: survives the app being suspended without losing time
- Local notification when the timer finishes

### Stopwatch
- Count-up stopwatch alongside the Timer, with start/pause/resume/reset
- `mm:ss.hundredths` display (switches to `h:mm:ss.hundredths` past an hour)
- Same background-resilient timekeeping as the Timer

### Countdowns
- Create a countdown to any future date, synced via Supabase
- Share a countdown by link or ID for others to follow
- Followers can opt in to their own notification for a countdown
- Owners can delete a countdown; followers can remove it from their list
- Countdowns sync to the iOS/Android home screen widgets, Apple Watch, and
  tvOS app

### Settings
- Light / dark / system theme
- Per-feature toggles and preferences described above, persisted locally

## Platform companions

- **iOS home screen widgets**: digital clock, analog clock, and a
  configurable countdown widget (pick which countdown to display)
- **Apple Watch app**: clock/timer view and a countdowns view, synced via
  Supabase and a phone-sync manager
- **tvOS app**: clock/timer view, countdowns view, and QR-code-based
  sign-in/pairing with the phone app
- **Android home screen widget**: live clock and date

## Backend

Countdown data (creation, following, notification preferences) is backed by
Supabase — see `supabase/schema.sql` for the schema and row-level security
policies.

## Getting Started

This is a standard Flutter project.

```
flutter pub get
flutter run
```

A few resources if you're new to Flutter:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
