---
name: document-conversion-pandoc
description: Convert PDF and EPUB documents to Markdown with repository-native tooling and consistent Pandoc-based workflows. Use this skill when users request document conversion, bulk regeneration of Markdown files from source PDFs/EPUBs, or when they need a standardized, reproducible conversion process that can be executed via VS Code tasks or terminal commands.
---

# Document Conversion (Pandoc)

Standardized conversion workflow for transforming PDF and EPUB files into Markdown using repository tools.

---

## Scope

Use this skill when the user asks to:
- Convert one or many `.pdf` files to `.md`
- Convert one or many `.epub` files to `.md`
- Regenerate Markdown outputs in bulk
- Keep conversion commands reproducible via skill-local scripts

This skill is for document conversion workflows only.

---

## Repository Tools

### PDF → Markdown
- Script: `.github/skills/document-conversion-pandoc/pdf_to_markdown_pandoc.py`
- Pipeline: `pdftotext` extraction + cleanup heuristics + `pandoc` normalization
- Current heuristics handle common book front matter better, including contents-page trimming, front-matter heading normalization, and structured filename title fallback

### EPUB → Markdown
- Script: `.github/skills/document-conversion-pandoc/epub_to_markdown_pandoc.py`
- Pipeline: direct `pandoc` conversion with configurable markdown flavor and wrapping

---

## Standard Workflow

### 1) Dry-run first

Preview conversion targets before writing files.

```bash
python .github/skills/document-conversion-pandoc/pdf_to_markdown_pandoc.py --input-dir <DIR> --glob "*.pdf" --dry-run
```

```bash
python .github/skills/document-conversion-pandoc/epub_to_markdown_pandoc.py --input-dir <DIR> --glob "*.epub" --dry-run
```

### 2) Convert (overwrite only when requested)

```bash
python .github/skills/document-conversion-pandoc/pdf_to_markdown_pandoc.py --input-dir <DIR> --glob "*.pdf" --overwrite
```

```bash
python .github/skills/document-conversion-pandoc/epub_to_markdown_pandoc.py --input-dir <DIR> --glob "*.epub" --format gfm --wrap none --overwrite
```

### 3) Optional media extraction for EPUB

```bash
python .github/skills/document-conversion-pandoc/epub_to_markdown_pandoc.py --input-dir <DIR> --glob "*.epub" --extract-media-dir <DIR>/media --overwrite
```

### 4) Verify output quality quickly

Check line count, heading count, and references presence:

```bash
for f in *.md; do lines=$(wc -l < "$f" | tr -d ' '); h2=$(grep -Ec '^## ' "$f" || true); refs=$(grep -Eic '^## references$|^# references$|^references$' "$f" || true); printf "%-70s %8s %8s %10s\n" "$f" "$lines" "$h2" "$refs"; done | sort -k2,2n
```

---

## Default Recommendations

- Prefer `--dry-run` before bulk conversion
- Use `--overwrite` only when regeneration is intended
- Prefer `--format gfm --wrap none` for stable Markdown diffs
- For PDFs, expect some table/OCR noise and page-marker artifacts; spot-check representative files
- Keep PDF filenames structured when possible, for example `<AUTHOR>_-_<TITLE>_-_<SUBTITLE>.pdf`, to improve title fallback when embedded PDF metadata is missing or unusable

---

## Troubleshooting

### `pandoc` command not found
Install pandoc in the runtime/container where conversion is executed.

If system `pandoc` is unavailable, the PDF converter can also use a `pypandoc`-managed binary when available in the active Python environment.

### `pdftotext` / `pdfinfo` not found (PDF script)
Install Poppler utilities in the runtime/container.

### Low-quality PDF output
Likely source extraction limitations (scanned/OCR-heavy, publisher front matter, or multi-column artifacts). Re-run with selective manual cleanup after conversion.

---

## Suggested VS Code Task

A matching task label exists in `.vscode/tasks.json`:
- `epub-to-markdown-systematic-review`

Run via VS Code **Run Task** for repeatable execution.
