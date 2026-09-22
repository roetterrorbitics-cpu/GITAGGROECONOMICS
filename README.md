# Rendert — europäische KI aus Bonn

Rendert enthält jetzt einen SaaS-MVP-Unterbau: Landingpage, Account-UI, Supabase Authentication und serverseitigen PayPal-Subscription-Start.

## Architektur
Browser → /api/config → öffentliche Supabase-Konfiguration → Supabase Auth
Browser → /api/paypal/create-subscription → PayPal OAuth → PayPal Subscriptions API

Der PayPal Client Secret bleibt serverseitig. PayPal REST APIs verwenden OAuth 2.0.

## Produktionsvariablen
SUPABASE_URL
SUPABASE_ANON_KEY
PAYPAL_CLIENT_ID
PAYPAL_CLIENT_SECRET
PAYPAL_PLAN_ID_CREATOR
PAYPAL_PLAN_ID_PRO
PAYPAL_WEBHOOK_ID
PAYPAL_RETURN_URL
PAYPAL_CANCEL_URL
PAYPAL_ENVIRONMENT=production

Keine echten Secrets in Git committen.

## Supabase
supabase/schema.sql im Projekt ausführen und E-Mail-Auth aktivieren.

## PayPal
Die Plan-IDs müssen auf aktive Billing-Pläne zeigen. Die finale Freischaltung sollte nach verifiziertem Subscription-Webhook erfolgen.

## Deployment
Vercel ist der vorgesehene Produktionshost für Frontend plus /api. GitHub Pages bleibt als statische Vorschau möglich.

Rechtstexte, Datenschutz, Impressum, Widerrufsbelehrung und steuerliche Angaben vor öffentlichem Verkauf finalisieren.

## Native Apple App

Unter `apple/` liegt die native SwiftUI-App für iPhone/iPad und Mac. Sie enthält native Supabase-Authentifizierung, Keychain-Session-Speicherung sowie StoreKit-2-Abos für Creator und Pro.

Die Apple-Abo-Transaktionen werden serverseitig über die App Store Server API mit dem Rendert-Benutzerkonto synchronisiert. Vor der Veröffentlichung müssen App Store Connect, Signing, Produktpreise und Server-Credentials eingerichtet werden.

