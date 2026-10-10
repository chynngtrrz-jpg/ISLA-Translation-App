import argparse
import csv
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
L10N = ROOT / "lib" / "l10n"
ENGLISH_PATH = L10N / "app_en.arb"
TAGALOG_PATH = L10N / "app_tl.arb"
ROMBLOMANON_PATH = L10N / "app_rol.arb"
BANTOANON_PATH = L10N / "app_bno.arb"
ONHAN_PATH = L10N / "app_loc.arb"
CSV_PATH = ROOT / "translation_sheet.csv"
HEADERS = [
    "key",
    "screen",
    "english",
    "tagalog",
    "romblomanon",
    "bantoanon",
    "onhan",
    "validated_by",
    "notes",
]
PLACEHOLDER_PATTERN = re.compile(r"\{[^{}]+\}")


def read_arb(path):
    with path.open(encoding="utf-8") as arb_file:
        return json.load(arb_file)


def message_keys(arb):
    return [key for key in arb if key != "@@locale" and not key.startswith("@")]


def export_sheet():
    english = read_arb(ENGLISH_PATH)
    tagalog = read_arb(TAGALOG_PATH)
    romblomanon = read_arb(ROMBLOMANON_PATH)
    bantoanon = read_arb(BANTOANON_PATH)
    onhan = read_arb(ONHAN_PATH)

    with CSV_PATH.open("w", encoding="utf-8-sig", newline="") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=HEADERS)
        writer.writeheader()
        for key in message_keys(english):
            metadata = english.get(f"@{key}", {})
            writer.writerow(
                {
                    "key": key,
                    "screen": metadata.get("description", ""),
                    "english": english[key],
                    "tagalog": tagalog.get(key, english[key]),
                    "romblomanon": romblomanon.get(key, english[key]),
                    "bantoanon": bantoanon.get(key, english[key]),
                    "onhan": onhan.get(key, english[key]),
                    "validated_by": "",
                    "notes": "",
                }
            )


def import_sheet():
    english = read_arb(ENGLISH_PATH)
    romblomanon = read_arb(ROMBLOMANON_PATH)
    bantoanon = read_arb(BANTOANON_PATH)
    onhan = read_arb(ONHAN_PATH)
    keys = message_keys(english)

    with CSV_PATH.open(encoding="utf-8-sig", newline="") as csv_file:
        reader = csv.DictReader(csv_file)
        if reader.fieldnames != HEADERS:
            raise ValueError(f"CSV columns must be exactly: {', '.join(HEADERS)}")
        rows = list(reader)

    row_keys = [row["key"] for row in rows]
    if len(row_keys) != len(set(row_keys)):
        raise ValueError("CSV contains duplicate localization keys.")
    if set(row_keys) != set(keys):
        missing = sorted(set(keys) - set(row_keys))
        extra = sorted(set(row_keys) - set(keys))
        raise ValueError(f"CSV keys differ from app_en.arb; missing={missing}, extra={extra}")

    for row in rows:
        key = row["key"]
        english_placeholders = PLACEHOLDER_PATTERN.findall(english[key])
        for column, locale_name, arb in (
            ("romblomanon", "Romblomanon", romblomanon),
            ("bantoanon", "Bantoanon", bantoanon),
            ("onhan", "Onhan", onhan),
        ):
            translation = row[column]
            if translation is None:
                raise ValueError(f"Missing {locale_name} value for {key}.")
            translated_placeholders = PLACEHOLDER_PATTERN.findall(translation)
            if sorted(english_placeholders) != sorted(translated_placeholders):
                raise ValueError(
                    f"Placeholder tokens differ for {key}: "
                    f"expected {english_placeholders}, "
                    f"found {translated_placeholders}."
                )
            arb[key] = translation

    for arb_path, arb in (
        (ROMBLOMANON_PATH, romblomanon),
        (BANTOANON_PATH, bantoanon),
        (ONHAN_PATH, onhan),
    ):
        with arb_path.open("w", encoding="utf-8", newline="\n") as arb_file:
            json.dump(arb, arb_file, ensure_ascii=False, indent=2)
            arb_file.write("\n")


def main():
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("export", help="Export all locales to translation_sheet.csv")
    commands.add_parser(
        "import",
        help=        "Import Romblomanon, Bantoanon, and Onhan values from the CSV sheet",
    )
    arguments = parser.parse_args()

    if arguments.command == "export":
        export_sheet()
    else:
        import_sheet()


if __name__ == "__main__":
    main()
