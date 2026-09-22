#!/usr/bin/env python3
"""Create a shareable briefing PDF for the proposed Bonn-based AI UG."""

from pathlib import Path
from textwrap import wrap


OUT = Path("docs/konzeptpapier-ki-ug-bonn.pdf")
WIDTH, HEIGHT = 595, 842  # A4 in PDF points
MARGIN = 54


def esc(text: str) -> str:
    """Encode PDF literal text using the WinAnsi character set."""
    data = text.encode("cp1252", "replace")
    return "(" + data.replace(b"\\", b"\\\\").replace(b"(", b"\\(").replace(b")", b"\\)").decode("latin1") + ")"


class Pdf:
    def __init__(self) -> None:
        self.pages: list[list[str]] = []
        self.current: list[str] = []

    def new_page(self) -> None:
        if self.current:
            self.pages.append(self.current)
        self.current = ["q"]

    def rect(self, x: int, y: int, w: int, h: int, color: tuple[float, float, float]) -> None:
        self.current.append(f"{color[0]} {color[1]} {color[2]} rg {x} {y} {w} {h} re f")

    def text(self, x: int, y: int, value: str, size: int = 11, bold: bool = False, color=(0.08, 0.12, 0.16)) -> None:
        font = "F2" if bold else "F1"
        self.current.append(f"BT /{font} {size} Tf {color[0]} {color[1]} {color[2]} rg 1 0 0 1 {x} {y} Tm {esc(value)} Tj ET")

    def finish(self) -> None:
        if self.current:
            self.current.append("Q")
            self.pages.append(self.current)
            self.current = []
        objects: list[bytes] = []
        objects.append(b"<< /Type /Catalog /Pages 2 0 R >>")
        kids = " ".join(f"{6 + i} 0 R" for i in range(len(self.pages)))
        objects.append(f"<< /Type /Pages /Kids [{kids}] /Count {len(self.pages)} >>".encode())
        objects.append(b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>")
        objects.append(b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>")
        objects.append(b"<< /Producer (Bonn AI UG briefing generator) /Title (Konzeptpapier KI UG Bonn) >>")
        for i, page in enumerate(self.pages):
            stream = "\n".join(page).encode("latin1")
            page_obj = 6 + i
            content_obj = 6 + len(self.pages) + i
            objects.append(f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {WIDTH} {HEIGHT}] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents {content_obj} 0 R >>".encode())
            objects.append(f"<< /Length {len(stream)} >>\nstream\n".encode() + stream + b"\nendstream")
        data = bytearray(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
        offsets = [0]
        for num, obj in enumerate(objects, 1):
            offsets.append(len(data))
            data.extend(f"{num} 0 obj\n".encode() + obj + b"\nendobj\n")
        startxref = len(data)
        data.extend(f"xref\n0 {len(objects) + 1}\n0000000000 65535 f \n".encode())
        for offset in offsets[1:]:
            data.extend(f"{offset:010d} 00000 n \n".encode())
        data.extend(f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R /Info 5 0 R >>\nstartxref\n{startxref}\n%%EOF\n".encode())
        OUT.parent.mkdir(parents=True, exist_ok=True)
        OUT.write_bytes(data)


def add_footer(pdf: Pdf, number: int) -> None:
    pdf.text(MARGIN, 30, "Konzeptpapier | Vertraulicher Diskussionsentwurf | 22. September 2026", 8, color=(0.35, 0.39, 0.43))
    pdf.text(WIDTH - MARGIN - 12, 30, str(number), 8, color=(0.35, 0.39, 0.43))


def add_body_page(pdf: Pdf, number: int, title: str, sections: list[tuple[str, list[str]]]) -> None:
    pdf.new_page()
    pdf.rect(0, HEIGHT - 76, WIDTH, 76, (0.05, 0.25, 0.28))
    pdf.text(MARGIN, HEIGHT - 45, title, 21, True, (1, 1, 1))
    y = HEIGHT - 110
    for heading, bullets in sections:
        pdf.text(MARGIN, y, heading, 13, True, (0.05, 0.25, 0.28))
        y -= 20
        for bullet in bullets:
            lines = wrap(bullet, width=86, break_long_words=False)
            pdf.text(MARGIN, y, "• " + lines[0], 10)
            y -= 14
            for line in lines[1:]:
                pdf.text(MARGIN + 12, y, line, 10)
                y -= 14
            y -= 5
        y -= 5
    add_footer(pdf, number)


def build() -> None:
    pdf = Pdf()
    pdf.new_page()
    pdf.rect(0, 0, WIDTH, HEIGHT, (0.04, 0.16, 0.19))
    pdf.rect(0, 0, WIDTH, 12, (0.26, 0.71, 0.62))
    pdf.text(MARGIN, 655, "KONZEPTPAPIER", 12, True, (0.55, 0.88, 0.80))
    pdf.text(MARGIN, 580, "Vertrauenswürdige KI", 31, True, (1, 1, 1))
    pdf.text(MARGIN, 540, "aus Bonn", 31, True, (1, 1, 1))
    pdf.text(MARGIN, 485, "Gründung einer UG (haftungsbeschränkt)", 15, False, (0.82, 0.91, 0.90))
    pdf.rect(MARGIN, 390, 92, 5, (0.26, 0.71, 0.62))
    pdf.text(MARGIN, 350, "Für: Herrn Gerd Jung", 13, True, (1, 1, 1))
    pdf.text(MARGIN, 325, "Stand: 22. September 2026", 11, False, (0.82, 0.91, 0.90))
    pdf.text(MARGIN, 150, "Ziel: Eine europäisch geprägte, sichere und ressourcenbewusste", 11, False, (0.82, 0.91, 0.90))
    pdf.text(MARGIN, 132, "KI-Initiative mit Hauptsitz in Bonn aufbauen.", 11, False, (0.82, 0.91, 0.90))
    pdf.text(MARGIN, 55, "Vertraulicher Diskussionsentwurf – keine Rechts- oder Steuerberatung.", 8, False, (0.62, 0.74, 0.73))
    pdf.current.append("Q")
    pdf.pages.append(pdf.current)
    pdf.current = []

    add_body_page(pdf, 2, "1. Ausgangspunkt und Zielbild", [
        ("Vorschlag", [
            "Gründung einer UG (haftungsbeschränkt) mit Sitz und operativem Schwerpunkt in Bonn.",
            "Entwicklung, Betrieb und Lizenzierung von vertrauenswürdigen KI-Produkten für internationale Nutzer und Partner.",
            "Kernprinzipien: europäische Werte, Datenschutz, Sicherheit, Transparenz, verantwortungsvolle Innovation und messbare Ressourceneffizienz.",
        ]),
        ("Warum zunächst eine UG?", [
            "Schneller und kapitalärmer zu gründen als eine GmbH, bei grundsätzlich auf das Gesellschaftsvermögen begrenzter Haftung.",
            "Geeignet, um Produkt, Team, erste Pilotkunden und belastbare Governance vor einer größeren Finanzierungsrunde aufzubauen.",
            "Eine spätere Kapitalerhöhung oder Umwandlung zur GmbH bleibt möglich, wenn Geschäft, Risiken und Finanzierung wachsen.",
        ]),
        ("Wichtige Klarstellung", [
            "Potenzielle Kontakte zu BSI, Telekom, Apple, Meta, Alphabet, Tesla oder einzelnen Persönlichkeiten sind keine bestehende Unterstützung. Namen und Logos dürfen nur mit ausdrücklicher schriftlicher Freigabe verwendet werden.",
        ]),
    ])
    add_body_page(pdf, 3, "2. Rechtliche und organisatorische Basis", [
        ("Gründung", [
            "Firma mit dem Pflichtzusatz ‚UG (haftungsbeschränkt)‘; Satzung, Notartermin, Handelsregistereintragung, Geschäftskonto, steuerliche Erfassung und Gewerbeanmeldung sauber vorbereiten.",
            "Das Stammkapital wird vor Eintragung vollständig in Geld eingezahlt. Für die Startfähigkeit sollten neben dem Kapital ausreichende Mittel für laufende Kosten geplant werden.",
        ]),
        ("Eigentum und Verantwortung", [
            "Gründervereinbarung mit Rollen, Anteilen, Vesting, Entscheidungsrechten, Konfliktlösung und Regeln für den Austritt eines Gründers abschließen.",
            "Code, Modelle, Domains, Marken, Datenbanken und Dokumentation durch schriftliche Verträge vollständig der UG zuordnen.",
            "Arbeits-, Freelancer- und Beraterverträge mit Vertraulichkeit, IP-Übertragung und Open-Source-Compliance verwenden.",
        ]),
        ("Compliance vor Pilotbetrieb", [
            "Datenflüsse, Rechtsgrundlagen, Löschfristen, Auftragsverarbeitung, Sicherheitsmaßnahmen und Modellrisiken dokumentieren.",
            "Anwendungsfälle vor Veröffentlichung auf Datenschutz-, Urheberrechts-, Sicherheits- und EU-AI-Act-Pflichten prüfen lassen.",
        ]),
    ])
    add_body_page(pdf, 4, "3. Finanzierung und Mittelverwendung", [
        ("Einnahmen ausschließlich über die UG", [
            "Gründerkapital, Investorengelder, Fördermittel, Projektmittel und Kundenumsätze gehen auf Geschäftskonten der UG – nie auf private Konten.",
            "Für jede Geldquelle werden Herkunft, Vertrag, Zweck, Freigabe und Belege dokumentiert.",
        ]),
        ("Getrennte Kostenstellen", [
            "1. Eigenkapital und Investitionen; 2. öffentliche Fördermittel; 3. Kundenumsätze; 4. Forschungspartnerschaften.",
            "Fördermittel bleiben strikt zweckgebunden. Zahlungen an Gründer, Berater oder verbundene Parteien erfolgen nur mit Vertrag, marktüblicher Vergütung und dokumentierter Freigabe.",
        ]),
        ("Priorität der Ausgaben", [
            "Zuerst: Recht, Steuern, Buchhaltung, Datenschutz, IT-Sicherheit und Versicherungen.",
            "Danach: Personal, europäische Cloud- und Compute-Kapazitäten, Produktentwicklung, Evaluation und sorgfältig gesteuerte Pilotprojekte.",
            "Liquidität sichern: Steuerlast, Fixkosten und eine realistische Reserve vor aggressivem Compute- oder Marketingbudget planen.",
        ]),
    ])
    add_body_page(pdf, 5, "4. Europäische Werte und geringe Wasserlast", [
        ("Technologieentscheidungen", [
            "Bevorzugung europäischer Datenresidenz, überprüfbarer Sicherheitsstandards und vertragsfähiger Ausstiegsmöglichkeiten gegenüber dauerhaften Plattformabhängigkeiten.",
            "Cloud- und Rechenzentrumsanbieter nach Energieeffizienz, Stromherkunft, PUE, WUE/Wasserverbrauch, Wasserquelle, Standort und Transparenz bewerten.",
        ]),
        ("Produktprinzipien", [
            "Privacy by design, klare Nutzungsgrenzen, Dokumentation von Fähigkeiten und Risiken, menschliche Aufsicht bei sensiblen Anwendungen und ein Meldeprozess für Vorfälle.",
            "Effiziente Modelle, kleinere Modellvarianten, Caching, Batch-Verarbeitung und gezielte Evaluierung bevorzugen, um Energie- und Wasserbedarf zu senken.",
        ]),
        ("Nachweisbarkeit", [
            "Energie-, Wasser- und CO2-Kennzahlen für Training und Betrieb erfassen. Öffentliche Nachhaltigkeitsaussagen nur verwenden, wenn sie messbar und belegbar sind.",
            "Ein jährlicher Transparenzbericht stärkt Vertrauen bei Kunden, öffentlichen Stellen, Investoren und der Zivilgesellschaft.",
        ]),
    ])
    add_body_page(pdf, 6, "5. Nächste Schritte", [
        ("Die ersten 30 Tage", [
            "Gründerkreis, Beteiligungen, Geschäftsführung und vorhandenes geistiges Eigentum verbindlich klären.",
            "Notar, Steuerberater und auf IT-/Datenschutzrecht spezialisierte Rechtsberatung auswählen.",
            "Satzung und Gründervereinbarung vorbereiten; UG gründen, Konto eröffnen und Buchhaltung mit getrennten Kostenstellen einrichten.",
        ]),
        ("Danach", [
            "Datenschutz-, Sicherheits- und Modell-Governance als Mindeststandard vor dem ersten Pilotprojekt umsetzen.",
            "Partneransprache nur mit klarer Rollenbeschreibung, Due Diligence und belastbaren Vertragsmustern beginnen.",
            "Infrastruktur anhand europäischer Kriterien und messbarer Wasser- sowie Energiekennzahlen auswählen.",
        ]),
        ("Entscheidungsvorlage", [
            "Die UG ist der geeignete erste Schritt, wenn die Gründer bereit sind, Eigentum, Daten, Geldflüsse und Sicherheitsverantwortung von Beginn an professionell zu organisieren.",
        ]),
    ])
    pdf.finish()


if __name__ == "__main__":
    build()
    print(f"Created {OUT}")
