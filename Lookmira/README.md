# Lookmira

Lookmira is an offline makeup diary for iPhone and iPad. You log a finished look — a photo, the products you used, style tags, and notes — then find it later on a calendar, in favorites, or by searching a tag or a product name.

It is a journal. It does not try makeup on a live camera, keep a clothing closet, track a skincare routine, or run a product inventory.

Bundle ID: `com.jackyliu.lookmira`

## Open in Xcode

Open `Lookmira.xcodeproj`. The app target links the local Swift package `LookmiraCore`. Deployment is iOS 17, for iPhone and iPad. The first launch writes three example looks and copies their photos onto the device. Delete them like any other entry.

Photos come from the system photo picker and stay in the app’s storage. There is no account and no network call for the diary. A daily reminder exists in Settings and stays off until you turn it on.

## Tests

Core rules live in `Sources/LookmiraCore` and do not import SwiftUI. From this folder:

```
swift test
```

That covers creating and editing looks, calendar grouping, search, favorites, recreating a look, the first-launch samples, the reminder schedule, and the JSON file on disk.
