# Deployment auf Render

## Zielarchitektur

Das Projekt wird als **Render Static Site** bereitgestellt. Render liefert die Dateien aus `site/` direkt aus; ein Build-Schritt ist nicht nötig. Die deklarative Definition liegt in [`../render.yaml`](../render.yaml).

## Erstbereitstellung

1. Repository in einen Git-Host pushen und in Render **New → Static Site** wählen.
2. Das Repository verbinden; Render erkennt `render.yaml` oder die Werte dort manuell übernehmen.
3. Branch `work` (bzw. später die gewünschte Produktions-Branch) festlegen und deployen.
4. Die Render-URL öffnen und die Foliennavigation auf Desktop und Mobilgerät prüfen.
5. Für Änderungen: committen, pushen und den automatischen Deploy abwarten.

## Custom Domain & DNS

1. In Render unter **Settings → Custom Domains** die primäre Domain hinzufügen.
2. Den von Render angezeigten DNS-Record beim DNS-Provider eintragen — Ziel und Record-Typ nicht raten, sondern aus Render übernehmen.
3. DNS-Propagation und die von Render ausgestellte TLS-Verbindung abwarten.
4. HTTPS, Redirect auf die primäre Domain und die Präsentation testen.

## PayPal-Vorbereitung

Das aktuelle Pitchdeck nimmt **keine Zahlung** entgegen. Falls später eine Zahlungsfunktion ergänzt wird:

1. Werte aus [`ACCESS.md`](ACCESS.md) als Render Environment Variables bzw. Secrets eintragen.
2. Zuerst PayPal Sandbox und einen serverseitigen Endpunkt verwenden; ein Client Secret darf nie im Browser landen.
3. Webhooks und Signaturprüfung implementieren, dann erfolglose/abgebrochene Zahlungen testen.
4. Erst nach Freigaben und Live-Tests auf `PAYPAL_ENVIRONMENT=live` umstellen.

## Rollback

Bei einer fehlerhaften Veröffentlichung in Render den vorherigen erfolgreichen Deploy wiederherstellen. Danach Ursache im Git-Verlauf korrigieren und erneut deployen.
