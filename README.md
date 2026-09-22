# Peach — europäische KI-Infrastruktur aus Bonn

Dieses Repository bündelt das **versionierbare Pitchdeck** und die schlanke Projekt-Website für Peach. Es ist bewusst als statische Website angelegt: schnell auslieferbar, ohne Serverlaufzeit und damit wasser- sowie betriebsbewusst.

> **Hinweis zu Partnern:** BSI, Deutsche Telekom, Apple, Meta, Alphabet, Tesla sowie Elon Musk und Max Tegmark sind im Zielbild als gewünschte Dialog-, Technologie- oder Ökosystempartner genannt. Daraus folgt **keine** bestehende Zusammenarbeit, Förderung oder Empfehlung durch diese Organisationen bzw. Personen.

## Zielbild

Peach entwickelt KI für die Welt mit Hauptsitz in Bonn: europäisch ausgerichtet, nachvollziehbar, sicher und ressourcenschonend. Das Pitchdeck konkretisiert die erste Marktgeschichte:

- **Souveränität:** Datenhoheit, nachvollziehbare Modelle und klare Governance.
- **Sicherheit:** Orientierung an belastbaren Sicherheits- und Compliance-Praktiken; mögliche fachliche Abstimmung mit relevanten Akteuren wie dem BSI.
- **Nutzwert:** KI, die in europäischen Organisationen produktiv einsetzbar ist.
- **Ressourcen:** Messbare Effizienz als Produktkriterium, einschließlich möglichst geringer Wasser- und Energieintensität.

## Projektstruktur

```text
.
├── docs/
│   ├── ACCESS.md             # Zugangsdaten-Checkliste (nur Platzhalter)
│   ├── DEPLOYMENT.md         # Render-, DNS- und Release-Ablauf
│   └── PITCHDECK.md          # Inhalt, Zielgruppe und Pflege des Decks
├── site/
│   ├── index.html            # Webbasiertes Pitchdeck
│   ├── styles.css            # Responsive Präsentationsdesign
│   └── app.js                # Tastatur- und Foliennavigation
├── assets/logo-peach.svg     # Vorhandenes Marken-Asset
└── render.yaml               # Infrastructure-as-code für Render Static Site
```

## Lokale Vorschau

Für die Website ist kein Build erforderlich. Zum lokalen Testen genügt ein statischer Server:

```bash
python3 -m http.server 8000 --directory site
```

Danach `http://localhost:8000` öffnen. Die Navigation funktioniert über die Buttons, die Pfeiltasten, Leertaste sowie `Home` und `Ende`.

## Deployment-Ziel

**Render Static Site** mit dem Verzeichnis `site/` als Publish Directory. Die Konfiguration steht in [`render.yaml`](render.yaml); der vollständige Ablauf inklusive Custom Domain und PayPal-Variablen ist in [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) dokumentiert. Zugangsdaten werden niemals eingecheckt — ausschließlich die Platzhalter in [`docs/ACCESS.md`](docs/ACCESS.md) sind versioniert.

## Nächste Schritte

1. Inhalt und Kennzahlen im Pitchdeck mit belastbaren Quellen ergänzen.
2. Rechtliche Prüfung von Marken-, Partner- und Zahlungsclaims durchführen.
3. Zugangsdaten im jeweiligen Anbieter-Secret-Store hinterlegen.
4. Custom Domain verbinden und DNS/HTTPS verifizieren.

## Lizenz

Bis zur ausdrücklichen Lizenzierung: alle Rechte vorbehalten.
