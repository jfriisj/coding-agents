from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import unicodedata
from pathlib import Path


HEADING_KEYWORDS = {
    "abstract",
    "acknowledgements",
    "acknowledgments",
    "artwork",
    "bibliography",
    "introduction",
    "foreword",
    "preface",
    "contents",
    "table of contents",
    "on the cover",
    "related work",
    "related works",
    "background",
    "method",
    "methods",
    "methodology",
    "approach",
    "experiments",
    "experimental setup",
    "results",
    "discussion",
    "conclusion",
    "conclusions",
    "limitations",
    "future work",
    "references",
    "appendix",
    "epilogue",
}

FRONT_MATTER_HEADINGS = {
    "foreword",
    "preface",
    "introduction",
    "contents",
    "table of contents",
    "on the cover",
    "acknowledgements",
    "acknowledgments",
    "epilogue",
}

MINOR_TITLE_WORDS = {
    "a",
    "an",
    "and",
    "as",
    "at",
    "by",
    "for",
    "from",
    "in",
    "of",
    "on",
    "or",
    "the",
    "to",
    "with",
}

TITLE_BLACKLIST_FRAGMENTS = {
    "series",
    "object mentor",
    "pearson",
    "informit",
    "copyright",
    "fax",
    "isbn",
    "rights and contracts",
    "printed in the united states",
    "first printing",
    "robert c. martin",
    "michael c. feathers",
    "timothy r. ottinger",
    "jeffrey j. langr",
    "brett l. schuchert",
    "james w. grenning",
    "kevin dean wampler",
}

NOISE_PATTERNS = [
    re.compile(r"^arxiv:\S+", re.IGNORECASE),
    re.compile(r"^authorized licensed use limited to", re.IGNORECASE),
    re.compile(r"^downloaded on ", re.IGNORECASE),
    re.compile(r"^acm isbn", re.IGNORECASE),
    re.compile(r"^https?://doi\.org/", re.IGNORECASE),
    re.compile(r"^doi:\s*", re.IGNORECASE),
    re.compile(r"^©\s*\d{4}"),
    re.compile(r"^ccs concepts", re.IGNORECASE),
    re.compile(r"^acm reference format", re.IGNORECASE),
    re.compile(r"^keywords\s*[—:-]", re.IGNORECASE),
    re.compile(r"^chi\s*['’]?\d+", re.IGNORECASE),
    re.compile(r"^this work is licensed", re.IGNORECASE),
    re.compile(r"^authorized licensed use", re.IGNORECASE),
    re.compile(r"^\d{4}\s+\d+(?:st|nd|rd|th)$", re.IGNORECASE),
    re.compile(r"^international conference on", re.IGNORECASE),
    re.compile(r"^\d+(?:st|nd|rd|th)\s+international conference", re.IGNORECASE),
    re.compile(r"^\d{3,}-\d{1,}-\d{1,}-\d{1,}/\d{2,}/\$\d+\.\d+", re.IGNORECASE),
    re.compile(r"^\s*\|\s*doi:\s*10\.", re.IGNORECASE),
    re.compile(r"^this page intentionally left blank$", re.IGNORECASE),
]


def run_command(command: list[str], input_text: str | None = None) -> str:
    result = subprocess.run(
        command,
        input=input_text,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"Command failed ({' '.join(command)}):\n{result.stderr.strip()}"
        )
    return result.stdout


def extract_pdf_text(pdf_path: Path) -> str:
    return run_command(["pdftotext", "-raw", "-nopgbrk", str(pdf_path), "-"])


def extract_pdf_title(pdf_path: Path) -> str | None:
    info = run_command(["pdfinfo", str(pdf_path)])
    for line in info.splitlines():
        if line.lower().startswith("title:"):
            title = collapse_spaces(line.split(":", 1)[1])
            if title and title.lower() not in {"untitled", "none"}:
                return title
    return None


def infer_title_from_filename(pdf_path: Path) -> str | None:
    stem = pdf_path.stem
    if "_-_" not in stem:
        return None

    parts = [collapse_spaces(part.replace("_", " ")) for part in stem.split("_-_") if part]
    if not parts:
        return None

    if len(parts) >= 3 and len(parts[0].split()) <= 3:
        parts = parts[1:]

    if not parts:
        return None

    title = parts[0]
    if len(parts) > 1:
        title = f"{title}: {' '.join(parts[1:])}"
    return title


def normalize_text(text: str) -> str:
    text = unicodedata.normalize("NFKC", text)
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = text.replace("\u00ad", "")
    return text


def collapse_spaces(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


def clean_paragraph_text(value: str) -> str:
    cleaned = value
    cleaned = re.sub(r"This work is licensed[^.]*\.\s*", "", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"ACM ISBN[^.]*\.\s*", "", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"CHI\s*['’]?\d+[^.]*\.\s*", "", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"https?://doi\.org/\S+", "", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"\[cs\.[A-Za-z]+\]\s+[A-Za-z]{3}", "", cleaned)
    return collapse_spaces(cleaned)


def expand_compound_heading_words(value: str) -> str:
    expanded = re.sub(r"(?<=[a-z])(?=[A-Z])", " ", value)
    return collapse_spaces(expanded)


def title_case_words(value: str) -> str:
    words = value.split()
    normalized: list[str] = []
    for index, word in enumerate(words):
        lower = word.lower()
        if index > 0 and lower in MINOR_TITLE_WORDS:
            normalized.append(lower)
        else:
            normalized.append(lower.capitalize())
    return " ".join(normalized)


def looks_like_title_case(value: str) -> bool:
    value = expand_compound_heading_words(value)
    words = [word for word in re.split(r"\s+", value) if re.search(r"[A-Za-z]", word)]
    if not words:
        return False

    matches = 0
    for word in words:
        stripped = re.sub(r"^[^A-Za-z]+|[^A-Za-z]+$", "", word)
        if not stripped:
            continue
        if stripped.lower() in MINOR_TITLE_WORDS or stripped[0].isupper():
            matches += 1
    return matches >= max(len(words) - 1, 1)


def is_standalone_title_line(line: str) -> bool:
    trimmed = expand_compound_heading_words(line)
    if len(trimmed) < 3 or len(trimmed) > 90:
        return False
    if trimmed.endswith((".", "?", "!", ":")):
        return False
    if re.search(r"https?://|@", trimmed, re.IGNORECASE):
        return False
    if re.search(r"\b(?:copyright|isbn|edition|printed|rights and contracts)\b", trimmed, re.IGNORECASE):
        return False
    if is_noise_line(trimmed):
        return False
    return looks_like_title_case(trimmed)


def is_front_matter_heading(value: str) -> bool:
    return collapse_spaces(value).lower().rstrip(".:") in FRONT_MATTER_HEADINGS


def is_compact_heading_text(value: str) -> bool:
    compact = expand_compound_heading_words(value)
    if not compact:
        return False
    if len(compact.split()) > 12:
        return False
    if compact.endswith((".", ",", ";", ":")):
        return False
    if compact.count(",") >= 2:
        return False
    if re.search(r"\b\w+\(\d+\)", compact):
        return False
    digit_count = sum(character.isdigit() for character in compact)
    if digit_count > 4 and not re.match(r"^\d+(?:\.\d+)*\s", compact):
        return False
    return True


def is_probable_embedded_heading(value: str) -> bool:
    candidate = expand_compound_heading_words(value)
    lowered = candidate.lower().rstrip(".:")
    if len(candidate) > 90 or not is_compact_heading_text(candidate):
        return False
    if lowered in HEADING_KEYWORDS or lowered in FRONT_MATTER_HEADINGS:
        return True
    if re.match(r"^chapter\s+\d+(?:\.\d+)*\s*[:\-]?\s+", candidate, re.IGNORECASE):
        return True
    return looks_like_title_case(candidate)


def is_table_of_contents_entry(value: str) -> bool:
    compact = collapse_spaces(value)
    if not compact:
        return False
    return bool(re.search(r"\.{5,}|[…]{2,}", compact))


def heading_key(value: str) -> str:
    return normalize_heading_text(value).lower()


def extract_contents_heading_keys(blocks: list[tuple[str, str]]) -> set[str]:
    contents_index = find_contents_index(blocks)
    if contents_index is None:
        return set()

    heading_keys: set[str] = set()
    for kind, value in blocks[contents_index + 1 :]:
        if kind != "heading":
            continue
        if not is_table_of_contents_entry(value):
            break
        entry = re.sub(r"(?:\.{5,}|[…]{2,}).*$", "", collapse_spaces(value)).strip()
        if not entry:
            continue
        heading_keys.add(heading_key(entry))
        chapter_match = re.match(r"^chapter\s+\d+(?:\.\d+)*\s*[:\-]?\s+(.+)$", entry, re.IGNORECASE)
        if chapter_match:
            heading_keys.add(heading_key(chapter_match.group(1).strip()))

    return heading_keys


def find_contents_index(blocks: list[tuple[str, str]]) -> int | None:
    return next(
        (
            index
            for index, (kind, value) in enumerate(blocks)
            if kind == "heading"
            and collapse_spaces(value).lower().rstrip(".:") in {"contents", "table of contents"}
        ),
        None,
    )


def split_embedded_page_heading_line(line: str) -> list[str]:
    stripped = collapse_spaces(line)
    if not stripped:
        return [stripped]

    leading_chapter_header = re.fullmatch(
        r"\d+\s+(chapter\s+\d+(?:\.\d+)*\s*[:\-]?\s+.+)",
        stripped,
        re.IGNORECASE,
    )
    if leading_chapter_header:
        return [leading_chapter_header.group(1)]

    trailing_chapter_header = re.match(
        r"^(.*\S)\d+\s+(Chapter\s+\d+(?:\.\d+)*\s*[:\-]?\s+.+)$",
        stripped,
        re.IGNORECASE,
    )
    if trailing_chapter_header and len(trailing_chapter_header.group(2)) <= 90:
        return [trailing_chapter_header.group(1).rstrip()]

    trailing_heading = re.match(r"^(.*\S)\d+\s+(.+)$", stripped)
    if trailing_heading:
        prefix = trailing_heading.group(1).rstrip()
        candidate = trailing_heading.group(2).strip()
        if is_probable_embedded_heading(candidate):
            return [prefix, expand_compound_heading_words(candidate)]

    return [stripped]


def should_demote_heading(value: str) -> bool:
    compact = expand_compound_heading_words(value)
    lowered = compact.lower()

    if not compact or is_table_of_contents_entry(compact):
        return False
    if compact.startswith("("):
        return True
    if lowered.startswith(("figure ", "listing ", "table ", "book ", "by ", "of ", "and ")):
        return True
    if lowered.endswith((" and", " or", " of", " by", " the", " a", " an")):
        return True
    if any(token in compact for token in ["{", "}", ";", "=", "%20", "]("]):
        return True
    if any(token in lowered for token in ["http://", "https://", "www.", ".java"]):
        return True
    if re.search(r"\b(?:throws|return|private|public|protected|class|interface)\b", lowered):
        return True
    if re.search(r"(?:\.\d+|\]\d+)$", compact):
        return True
    if re.match(r"^\d+\.\s", compact):
        suffix = re.sub(r"^\d+\.\s*", "", compact)
        if len(suffix.split()) > 6 or compact.endswith("?"):
            return True
    if "," in compact and any(
        token in lowered for token in ["author", "inventor", "founder", "godfather", "thought leader"]
    ):
        return True
    if re.search(r"[A-Za-z][ivxlcdm]{2,}\b", compact):
        return True
    return False


def postprocess_blocks(
    blocks: list[tuple[str, str]], contents_heading_keys: set[str]
) -> list[tuple[str, str]]:
    processed: list[tuple[str, str]] = []
    recent_headings: list[str] = []
    contents_index = find_contents_index(blocks)
    index = 0

    while index < len(blocks):
        kind, value = blocks[index]
        if kind != "heading":
            if (
                kind == "paragraph"
                and contents_heading_keys
                and contents_index is not None
                and index > contents_index
                and is_standalone_title_line(value)
            ):
                paragraph_key = heading_key(value)
                if paragraph_key in contents_heading_keys and paragraph_key not in recent_headings:
                    processed.append(("heading", normalize_heading_text(value)))
                    recent_headings.append(paragraph_key)
                    recent_headings = recent_headings[-6:]
                    index += 1
                    continue
            processed.append((kind, value))
            index += 1
            continue

        normalized = normalize_heading_text(value)
        normalized_key = normalized.lower()
        if normalized_key in recent_headings:
            index += 1
            continue

        if is_table_of_contents_entry(value):
            processed.append(("heading", value))
            recent_headings.append(normalized_key)
            recent_headings = recent_headings[-6:]
            index += 1
            continue

        sequence = [value]
        sequence_end = index + 1
        while sequence_end < len(blocks) and blocks[sequence_end][0] == "heading":
            next_value = blocks[sequence_end][1]
            if is_table_of_contents_entry(next_value):
                break
            next_key = normalize_heading_text(next_value).lower()
            if next_key in recent_headings:
                sequence_end += 1
                continue
            sequence.append(next_value)
            sequence_end += 1
            if len(sequence) >= 3:
                break

        if len(sequence) > 1:
            combined = expand_compound_heading_words(" ".join(sequence))
            combined_key = heading_key(combined)
            allowed_combined = (not contents_heading_keys) or combined_key in contents_heading_keys
            if allowed_combined and is_heading_line(combined):
                normalized = normalize_heading_text(combined)
                normalized_key = normalized.lower()
                if normalized_key not in recent_headings:
                    processed.append(("heading", normalized))
                    recent_headings.append(normalized_key)
                    recent_headings = recent_headings[-6:]
                index = sequence_end
                continue

        apply_contents_whitelist = (
            bool(contents_heading_keys)
            and contents_index is not None
            and index > contents_index
        )
        allowed_by_contents = (not apply_contents_whitelist) or normalized_key in contents_heading_keys
        if not allowed_by_contents or (not apply_contents_whitelist and should_demote_heading(normalized)):
            processed.append(("paragraph", expand_compound_heading_words(value)))
        else:
            processed.append(("heading", normalized))
            recent_headings.append(normalized_key)
            recent_headings = recent_headings[-6:]
        index += 1

    return processed


def is_noise_line(line: str) -> bool:
    if not line:
        return False
    if all(ch in "-_=*·•" for ch in line):
        return True
    if re.fullmatch(r"\d+", line):
        return True
    if len(line) <= 2 and line.isalpha():
        return True
    if "@" in line:
        return True
    for pattern in NOISE_PATTERNS:
        if pattern.search(line):
            return True
    return False


def is_heading_line(line: str) -> bool:
    if not line:
        return False
    trimmed = expand_compound_heading_words(line)
    if len(trimmed) > 120:
        return False

    lowered = trimmed.lower().rstrip(".:")
    if lowered in HEADING_KEYWORDS or lowered in FRONT_MATTER_HEADINGS:
        return True

    numbered_match = re.fullmatch(
        r"(\d{1,3}(?:\.\d+)*|[IVXLCMivxlcm]+)[\.)]?\s+([A-Z][\w\s\-:,()'’?]{1,100})",
        trimmed,
    )
    if numbered_match and is_compact_heading_text(numbered_match.group(2)):
        return True

    chapter_match = re.fullmatch(
        r"chapter\s+\d+(?:\.\d+)*\s*[:\-]?\s+[A-Z][\w\s\-:,()'’?]{1,100}",
        trimmed,
        re.IGNORECASE,
    )
    if chapter_match:
        chapter_suffix = re.sub(r"^chapter\s+\d+(?:\.\d+)*\s*[:\-]?\s+", "", trimmed, flags=re.IGNORECASE)
        if is_compact_heading_text(chapter_suffix):
            return True

    if re.fullmatch(
        r"[A-Z][\.)]\s+[A-Z][\w\s\-:,()?]{1,100}",
        trimmed,
    ) and is_compact_heading_text(trimmed.split(None, 1)[1]):
        return True

    if re.search(r"\b[A-Z]\.", trimmed):
        return False

    if looks_like_title_case(trimmed) and is_compact_heading_text(trimmed):
        word_count = len(trimmed.split())
        if word_count >= 2:
            return True
        if word_count == 1 and len(trimmed) >= 7:
            return True

    return False


def merge_hyphenated_lines(lines: list[str]) -> list[str]:
    merged: list[str] = []
    index = 0
    while index < len(lines):
        line = lines[index]
        if (
            line.endswith("-")
            and index + 1 < len(lines)
            and lines[index + 1]
            and lines[index + 1][0].islower()
        ):
            line = line[:-1] + lines[index + 1].lstrip()
            index += 1
        merged.append(line)
        index += 1
    return merged


def parse_inline_heading(line: str) -> tuple[str, str] | None:
    match = re.match(r"^(abstract|keywords|index terms)\s*[—–:-]\s*(.*)$", line, re.IGNORECASE)
    if not match:
        return None
    heading = match.group(1).strip().title()
    body = collapse_spaces(match.group(2))
    return heading, body


def starts_new_paragraph(line: str) -> bool:
    if re.match(r"^\[\d+\]\s+", line):
        return True
    if line.startswith("•"):
        return True
    if re.match(r"^(fig\.|figure|table)\s+", line, re.IGNORECASE):
        return True
    return False


def to_blocks(raw_text: str) -> list[tuple[str, str]]:
    lines: list[str] = []
    for raw_line in normalize_text(raw_text).splitlines():
        stripped = raw_line.strip()
        if not stripped:
            lines.append("")
            continue
        lines.extend(split_embedded_page_heading_line(stripped))
    lines = [line for line in lines if not is_noise_line(line)]
    lines = merge_hyphenated_lines(lines)

    blocks: list[tuple[str, str]] = []
    buffer: list[str] = []
    skip_keyword_continuation = False
    in_table_block = False

    def flush_paragraph() -> None:
        if not buffer:
            return
        paragraph = clean_paragraph_text(" ".join(buffer))
        if paragraph:
            blocks.append(("paragraph", paragraph))
        buffer.clear()

    for line in lines:
        if not line:
            flush_paragraph()
            if skip_keyword_continuation:
                skip_keyword_continuation = False
            continue

        if in_table_block and re.match(r"^(?:[IVXLCM]+|\d+)[\.)]?\s+[A-Z]", line):
            in_table_block = False

        if skip_keyword_continuation:
            if is_heading_line(line):
                skip_keyword_continuation = False
            else:
                continue

        if re.match(r"^table\s+[IVXLCM\d]", line, re.IGNORECASE):
            flush_paragraph()
            blocks.append(("paragraph", collapse_spaces(line)))
            in_table_block = True
            continue

        inline_heading = parse_inline_heading(line)
        if inline_heading:
            flush_paragraph()
            heading, body = inline_heading
            if heading.lower() == "keywords":
                skip_keyword_continuation = True
                continue
            blocks.append(("heading", heading))
            if body:
                blocks.append(("paragraph", body))
            continue

        if is_heading_line(line) and not in_table_block:
            flush_paragraph()
            heading = collapse_spaces(line).rstrip(":")
            blocks.append(("heading", heading))
            continue

        if is_standalone_title_line(line) and not in_table_block:
            flush_paragraph()
            line_text = clean_paragraph_text(line)
            if line_text:
                blocks.append(("paragraph", line_text))
            continue

        if starts_new_paragraph(line):
            flush_paragraph()
            line_text = clean_paragraph_text(line)
            if line_text:
                blocks.append(("paragraph", line_text))
            continue

        buffer.append(line)

    flush_paragraph()
    return postprocess_blocks(blocks, extract_contents_heading_keys(blocks))


def is_title_candidate(value: str, *, allow_heading: bool = False) -> bool:
    words = value.split()
    alpha_words = [word for word in words if re.search(r"[A-Za-z]", word)]
    lowered = value.lower()
    if len(alpha_words) < 2 or len(alpha_words) > 18:
        return False
    if len(value) > 180:
        return False
    if not allow_heading and is_heading_line(value):
        return False
    if any(
        token in lowered
        for token in [
            "university",
            "department",
            "conference",
            "proceedings",
            "abstract",
            "keywords",
            "doi",
            "@",
            "http",
            "copyright",
        ]
    ):
        return False
    if re.match(r"^(figure|table)\s+\d+", lowered):
        return False
    return True


def score_title_candidate(value: str, *, allow_heading: bool = False) -> int:
    normalized = collapse_spaces(value)
    if not is_title_candidate(normalized, allow_heading=allow_heading):
        return -1

    lowered = normalized.lower()
    score = 0
    if 2 <= len(normalized.split()) <= 12:
        score += 2
    if len(normalized) <= 80:
        score += 1
    if ":" in normalized:
        score += 4
    if looks_like_title_case(normalized):
        score += 2
    if normalized.endswith((".", "?", "!")):
        score -= 2
    if any(fragment in lowered for fragment in TITLE_BLACKLIST_FRAGMENTS):
        score -= 5
    return score


def find_title(blocks: list[tuple[str, str]], metadata_title: str | None) -> str:
    if metadata_title:
        return metadata_title

    contents_index = next(
        (
            index
            for index, (kind, value) in enumerate(blocks)
            if kind == "heading"
            and collapse_spaces(value).lower().rstrip(".:") in {"contents", "table of contents"}
        ),
        None,
    )

    if contents_index is not None:
        search_slice = blocks[:contents_index]
    else:
        first_heading_index = next(
            (
                index
                for index, (kind, value) in enumerate(blocks)
                if kind == "heading"
                and value.lower().rstrip(".:") in {"abstract", "1 introduction", "introduction"}
            ),
            min(len(blocks), 30),
        )
        search_slice = blocks[: max(first_heading_index, 1)]

    best_title: str | None = None
    best_score = -1
    for index, (kind, value) in enumerate(search_slice):
        if kind == "paragraph":
            candidate = value
            score = score_title_candidate(candidate)
        elif kind == "heading":
            candidate = normalize_heading_text(value)
            lowered = collapse_spaces(candidate).lower().rstrip(".:")
            if lowered in HEADING_KEYWORDS or lowered in FRONT_MATTER_HEADINGS:
                continue
            if is_table_of_contents_entry(value):
                continue
            score = score_title_candidate(candidate, allow_heading=True) - 1
        else:
            continue

        if score > best_score or (score == best_score and best_title is not None):
            best_title = candidate
            best_score = score

    if best_title and best_score >= 0:
        return best_title

    return "Converted PDF"


def find_first_body_index(blocks: list[tuple[str, str]]) -> int:
    contents_index = next(
        (
            index
            for index, (kind, value) in enumerate(blocks)
            if kind == "heading"
            and collapse_spaces(value).lower().rstrip(".:") in {"contents", "table of contents"}
        ),
        None,
    )

    search_start = contents_index + 1 if contents_index is not None else 0
    for index, (kind, value) in enumerate(blocks[search_start:], start=search_start):
        if kind != "heading":
            continue
        if is_table_of_contents_entry(value):
            continue
        lowered = collapse_spaces(value).lower().rstrip(".:")
        if lowered in {"contents", "table of contents"}:
            continue
        if is_front_matter_heading(value) or lowered in HEADING_KEYWORDS:
            return index
        if re.match(r"^(?:chapter\s+\d+(?:\.\d+)*|\d+(?:\.\d+)*|[ivxlcm]+)[\.)]?(?:\s+|:\s+)", lowered):
            return index

    return 0


def normalize_heading_text(value: str) -> str:
    clean = expand_compound_heading_words(value)
    chapter_match = re.match(r"^chapter\s+(\d+(?:\.\d+)*)\s*[:\-]?\s+(.+)$", clean, re.IGNORECASE)
    if chapter_match:
        suffix = chapter_match.group(2).strip()
        if suffix.isupper():
            suffix = suffix.title()
        return f"{chapter_match.group(1)}. {suffix}"

    roman_match = re.match(r"^([IVXLCMivxlcm]+)[\.)]?\s+(.+)$", clean)
    if roman_match:
        suffix = roman_match.group(2).strip()
        if suffix.lower().rstrip(".:") in FRONT_MATTER_HEADINGS:
            return title_case_words(suffix)
        if suffix.isupper():
            suffix = suffix.title()
        return f"{roman_match.group(1).upper()}. {suffix}"

    numeric_match = re.match(r"^(\d+(?:\.\d+)*)(?:[\.):]|\s)\s*(.+)$", clean)
    if numeric_match:
        suffix = numeric_match.group(2).strip()
        if suffix.isupper():
            suffix = suffix.title()
        return f"{numeric_match.group(1)}. {suffix}"

    alpha_match = re.match(r"^([A-Z])[\.)]\s+(.+)$", clean)
    if alpha_match:
        suffix = alpha_match.group(2).strip()
        if suffix.isupper():
            suffix = suffix.title()
        return f"{alpha_match.group(1)}. {suffix}"

    if clean.lower().rstrip(".:") == "references":
        return "References"
    if clean.islower() or clean.isupper():
        return clean.title()
    return clean


def split_reference_items(paragraph: str) -> list[str]:
    text = collapse_spaces(paragraph)
    if not text:
        return []

    if not re.search(r"(?:^|\s)(?:\[\d+\]|\d+\.)\s", text):
        return [text]

    chunks = re.split(r"\s+(?=(?:\[\d+\]|\d+\.\s))", text)
    items = [chunk.strip() for chunk in chunks if chunk.strip()]
    items = [item for item in items if not re.fullmatch(r"\d+\.?", item)]
    items = [item for item in items if len(item.split()) > 2]
    return items or [text]


def blocks_to_markdown(blocks: list[tuple[str, str]], metadata_title: str | None) -> str:
    title = find_title(blocks, metadata_title)
    first_body_index = find_first_body_index(blocks)

    output_lines: list[str] = [f"# {title}", ""]
    in_references = False
    last_reference_line_index: int | None = None

    for kind, value in blocks[first_body_index:]:
        if kind == "heading":
            heading = normalize_heading_text(value)
            output_lines.append(f"## {heading}")
            output_lines.append("")
            in_references = heading.lower() == "references"
            last_reference_line_index = None
            continue

        if in_references:
            ref_items = split_reference_items(value)
            for item in ref_items:
                marker_match = re.match(r"^\[(\d+)\]\s*(.*)$", item)
                if marker_match:
                    output_lines.append(f"{marker_match.group(1)}. {marker_match.group(2)}")
                    last_reference_line_index = len(output_lines) - 1
                    continue
                marker_match = re.match(r"^(\d+)\.\s*(.*)$", item)
                if marker_match:
                    output_lines.append(f"{marker_match.group(1)}. {marker_match.group(2)}")
                    last_reference_line_index = len(output_lines) - 1
                    continue
                if last_reference_line_index is not None:
                    output_lines[last_reference_line_index] = (
                        f"{output_lines[last_reference_line_index]} {item}"
                    )
                else:
                    output_lines.append(f"- {item}")
                    last_reference_line_index = len(output_lines) - 1
            output_lines.append("")
            continue

        output_lines.append(value)
        output_lines.append("")

    markdown = "\n".join(output_lines).strip() + "\n"
    return markdown


def normalize_with_pandoc(markdown_text: str) -> str:
    pandoc_path = shutil.which("pandoc")
    if pandoc_path is None:
        try:
            import pypandoc

            pandoc_path = pypandoc.get_pandoc_path()
        except (ImportError, OSError):
            pandoc_path = "pandoc"

    return run_command(
        [
            pandoc_path,
            "-f",
            "markdown",
            "-t",
            "gfm",
            "--wrap=none",
            "--markdown-headings=atx",
        ],
        input_text=markdown_text,
    )


def convert_pdf(pdf_path: Path, output_path: Path) -> None:
    metadata_title = extract_pdf_title(pdf_path) or infer_title_from_filename(pdf_path)
    extracted = extract_pdf_text(pdf_path)
    blocks = to_blocks(extracted)
    markdown = blocks_to_markdown(blocks, metadata_title)
    normalized = normalize_with_pandoc(markdown)
    output_path.write_text(normalized, encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert PDFs to cleaner Markdown using pdftotext + pandoc normalization."
    )
    parser.add_argument("--input-dir", type=Path, required=True)
    parser.add_argument("--glob", default="*.pdf")
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    input_dir = args.input_dir
    pdf_files = sorted(input_dir.glob(args.glob))

    if not pdf_files:
        raise SystemExit(f"No PDF files found in {input_dir} using pattern {args.glob}")

    converted = 0
    skipped = 0

    for pdf_path in pdf_files:
        output_path = pdf_path.with_suffix(".md")
        if output_path.exists() and not args.overwrite:
            skipped += 1
            continue

        if args.dry_run:
            print(f"[dry-run] {pdf_path.name} -> {output_path.name}")
            continue

        convert_pdf(pdf_path, output_path)
        converted += 1
        print(f"Converted {pdf_path.name} -> {output_path.name}")

    print(f"Done. Converted={converted}, Skipped={skipped}")


if __name__ == "__main__":
    main()