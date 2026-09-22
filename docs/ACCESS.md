# Zugänge & Secrets (Platzhalter)

Diese Datei ist eine **Checkliste, kein Secret Store**. Niemals echte Tokens, Passwörter, API-Schlüssel, Kundendaten oder private Schlüssel in Git committen. Produktionswerte gehören in Render Environment Groups/Secrets, den Domain-Registrar und das PayPal Developer Dashboard.

## Render

| Zweck | Platzhalter | Ablage |
| --- | --- | --- |
| Render-Konto | `RENDER_ACCOUNT_EMAIL=<eintragen>` | Passwortmanager |
| Service-ID | `RENDER_SERVICE_ID=<eintragen>` | Passwortmanager / Render |
| Deploy Hook | `RENDER_DEPLOY_HOOK_URL=<eintragen>` | Render Secret |
| API-Key (optional) | `RENDER_API_KEY=<eintragen>` | Render Secret |

## Domain & DNS

| Zweck | Platzhalter | Ablage |
| --- | --- | --- |
| Registrar | `DOMAIN_REGISTRAR=<eintragen>` | Passwortmanager |
| Domain | `PRIMARY_DOMAIN=<eintragen>` | Konfigurationsinventar |
| DNS-Provider | `DNS_PROVIDER=<eintragen>` | Passwortmanager |
| DNS-Zugang / API-Token | `DNS_API_TOKEN=<eintragen>` | Passwortmanager / Secret Store |
| Render-DNS-Record | `RENDER_DNS_TARGET=<aus Render übernehmen>` | DNS-Zone |

## PayPal

| Zweck | Platzhalter | Ablage |
| --- | --- | --- |
| Umgebung | `PAYPAL_ENVIRONMENT=sandbox` | Render Environment |
| Client ID | `PAYPAL_CLIENT_ID=<eintragen>` | Render Secret |
| Client Secret | `PAYPAL_CLIENT_SECRET=<eintragen>` | Render Secret |
| Webhook-ID | `PAYPAL_WEBHOOK_ID=<eintragen>` | Render Secret |
| Rückgabe-URL | `PAYPAL_RETURN_URL=https://<domain>/` | Render Environment |

## Vor dem Go-live

- [ ] Geheimnisse liegen ausschließlich in den vorgesehenen Secret Stores.
- [ ] `.env` und lokale Exportdateien sind nicht versioniert.
- [ ] DNS- und TLS-Status der Domain sind geprüft.
- [ ] PayPal ist zunächst in `sandbox`, die Webhook-Signatur wird serverseitig validiert.
- [ ] Erst nach rechtlicher, steuerlicher und datenschutzrechtlicher Freigabe auf PayPal Live umstellen.
