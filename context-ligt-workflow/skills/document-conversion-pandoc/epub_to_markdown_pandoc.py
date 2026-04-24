from __future__ import annotations

import argparse
import subprocess
from pathlib import Path


def run_command(command: list[str]) -> None:
    result = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"Command failed ({' '.join(command)}):\n{result.stderr.strip()}"
        )


def convert_epub(
    epub_path: Path,
    output_path: Path,
    markdown_format: str,
    wrap: str,
    extract_media_dir: Path | None,
) -> None:
    command = [
        "pandoc",
        "-f",
        "epub",
        "-t",
        markdown_format,
        f"--wrap={wrap}",
        "--markdown-headings=atx",
    ]

    if extract_media_dir is not None:
        media_dir = extract_media_dir / epub_path.stem
        media_dir.mkdir(parents=True, exist_ok=True)
        command.extend(["--extract-media", str(media_dir)])

    command.extend([str(epub_path), "-o", str(output_path)])
    run_command(command)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert EPUB files to Markdown using pandoc."
    )
    parser.add_argument("--input-dir", type=Path, required=True)
    parser.add_argument("--glob", default="*.epub")
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument(
        "--format",
        choices=["gfm", "markdown"],
        default="gfm",
        help="Markdown output flavor.",
    )
    parser.add_argument(
        "--wrap",
        choices=["none", "auto", "preserve"],
        default="none",
        help="Pandoc line wrapping behavior.",
    )
    parser.add_argument(
        "--extract-media-dir",
        type=Path,
        help="Optional root directory for extracted media assets.",
    )
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    input_dir = args.input_dir
    output_dir = args.output_dir or input_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    epub_files = sorted(input_dir.glob(args.glob))
    if not epub_files:
        raise SystemExit(f"No EPUB files found in {input_dir} using pattern {args.glob}")

    converted = 0
    skipped = 0

    for epub_path in epub_files:
        output_path = output_dir / f"{epub_path.stem}.md"

        if output_path.exists() and not args.overwrite:
            skipped += 1
            continue

        if args.dry_run:
            print(f"[dry-run] {epub_path.name} -> {output_path}")
            continue

        convert_epub(
            epub_path=epub_path,
            output_path=output_path,
            markdown_format=args.format,
            wrap=args.wrap,
            extract_media_dir=args.extract_media_dir,
        )
        converted += 1
        print(f"Converted {epub_path.name} -> {output_path.name}")

    print(f"Done. Converted={converted}, Skipped={skipped}")


if __name__ == "__main__":
    main()
