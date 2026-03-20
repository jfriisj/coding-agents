# Translation Quality Human Evaluation Rubric (Epic 2.4)

This rubric defines how to rate human translation quality for the `da→en` mini-benchmark.

## Scope

- Language pair: `da→en`
- Dimensions: `adequacy`, `fluency`
- Scale: integer `1–5`
- Input template: `datasets/translation-quality/human-ratings-template.csv`

## Rating Dimensions

### Adequacy
How well the translation preserves meaning from the source sentence.

- **5**: Meaning is fully preserved; no important omissions/additions; correct intent.
- **4**: Meaning is mostly preserved; minor loss/addition that does not change intent.
- **3**: Core meaning is partially preserved; one or more noticeable meaning issues.
- **2**: Major meaning errors, omissions, or additions; intent often unclear.
- **1**: Meaning is not preserved; translation is misleading or unusable.

### Fluency
How natural and grammatically correct the translation is in English.

- **5**: Native-like, grammatical, natural phrasing.
- **4**: Mostly fluent with minor wording/grammar issues.
- **3**: Understandable but awkward or error-prone phrasing.
- **2**: Disfluent with frequent grammar/word-choice problems.
- **1**: Unreadable or largely ungrammatical.

## Rater Instructions

1. Rate each sample independently on both dimensions.
2. Use integer scores only (`1`, `2`, `3`, `4`, `5`).
3. Judge adequacy first against source meaning, then fluency as standalone English.
4. Do not add free-form notes columns in the CSV (aggregate-only policy).
5. If uncertain between two adjacent scores, choose the lower score.

## CSV Contract

- Required columns: `sample_id,adequacy,fluency`
- Forbidden free-form columns: `notes`, `note`, `comment`, `comments`, `freeform`
- Empty rows are ignored; rows with `sample_id` starting with `#` are ignored.

## Aggregation

Run with:

- `python -m tools.quality_eval_cli --run-id <run_id> --human-ratings-csv <ratings.csv>`

The output `human_summary.json` contains only auditable aggregates (`mean/min/max/count`) and no free-form text.
