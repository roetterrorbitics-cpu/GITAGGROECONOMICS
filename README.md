# Rendert — europäische KI aus Bonn

Dieses Repository enthält einen eigenständigen, statischen Pitchdeck-Prototypen für **Rendert**. Er lässt sich ohne Build-Schritt auf Render Static Sites, GitHub Pages oder jedem anderen Webserver bereitstellen.

## Lokal ansehen

```bash
python3 -m http.server 8080
```

Danach `http://localhost:8080` öffnen.

## Deployment auf Render

1. Im Render-Dashboard eine **Static Site** anlegen und dieses Repository verbinden.
2. Build Command leer lassen und als Publish Directory `.` festlegen.
3. Eine Render-Subdomain für die Vorschau verwenden.
4. Nach der Domain-Verifikation `rendert.de` als Custom Domain hinterlegen und die alte Subdomain per 301 auf die kanonische Domain leiten.

Die konkreten historischen Render-Dienste für Kindred-Notes, Mediant und Flare müssen nach Wiederherstellung des zugehörigen Kontos inventarisiert werden. Sie sind im Deck daher bewusst als verifizierungsbedürftige Projektspuren markiert, nicht als behauptete Live-Services.

## Zahlungen

Die Seite enthält keine Zugangsdaten und keine produktive Zahlungsabwicklung. Vor einer PayPal-Integration sind Geschäftsmodell, Datenschutz, Widerruf/Impressum sowie Server-seitige Order- und Webhook-Prüfung festzulegen. Die Datei `paypal.example.env` zeigt ausschließlich die benötigte Konfigurationsform.

## Aussagen zu Organisationen

HBRS wird im Pitchdeck als Alma-Mater-Bezug geführt. Mediant, Rötter Records e.V., Flare und Kindred-Notes sind Projekt- bzw. Netzwerkbezüge. BSI, Telekom, Apple, Meta, Alphabet, Tesla sowie genannte Personen werden **nicht** als bestätigte Unterstützer dargestellt. Dafür wären schriftliche, veröffentlichungsfähige Freigaben erforderlich.
