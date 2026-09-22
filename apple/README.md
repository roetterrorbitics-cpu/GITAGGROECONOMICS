# Rendert Apple App

Native SwiftUI app foundation for Rendert.

## Xcode

Open:

    apple/Rendert.xcodeproj

The project is prepared as a shared SwiftUI codebase for iPhone/iPad and Mac Catalyst/macOS. The same architecture can be extended to visionOS and watchOS with dedicated targets.

## Subscriptions

Apple-platform digital subscriptions use StoreKit 2:

- com.roetterrorbitics.rendert.creator
- com.roetterrorbitics.rendert.pro

These Product IDs are placeholders and must exist in App Store Connect before a real purchase can work.

The existing PayPal subscriptions remain the web checkout. Do not expose the PayPal checkout as the in-app purchase mechanism for digital SaaS features.

## Next integration

1. Connect native authentication to the existing Supabase project.
2. Add StoreKit subscription verification and entitlement sync to the backend.
3. Add the real Rendert AI workspace.
4. Configure signing, App ID, App Store Connect, TestFlight and release metadata.
