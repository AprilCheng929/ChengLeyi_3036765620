# Data

The raw survey file `public.csv` is **not committed** to this repository, in
accordance with the course data-access terms (do not redistribute the data or
download links, and do not publish restricted raw data in a public repository).

## How to obtain it

1. Download **Package 01** (18 KB ZIP, "Minimum wage / DID") from the ECO6067
   *Project Data Downloads* page. Access is available until 22 October 2026,
   23:59 Hong Kong time (UTC+8).
2. Extract the archive. It contains a README, a data dictionary, and the CSV.
3. Copy `public.csv` into this folder.

The expected layout is:

```
econ6067-ck1994-minwage/
└── data/
    └── public.csv          <- you supply this file
```

## File description

`public.csv` — store-level survey data for the Card & Krueger (1994) study:
410 observations, 46 columns. Suffix `2` denotes the second survey wave
(November–December 1992); the unsuffixed columns are the first wave
(February–March 1992). Blank cells are missing values.

See the course `DATA_DICTIONARY.md` for the full column definitions.

## Notes

- The file is read-only input. The pipeline never writes back to it.
- `01_clean.do` produces `data/analysis.dta` from it on every run; that file is
  also untracked.
- The paper's Table 1 (sample design and response rates) is not reproducible
  from this file.

## Verifying you have the correct file

Before running the pipeline, confirm that the CSV you obtained is the file this
project was built against. From the project root:

**Expected shape.** 410 observations (rows including the header row's columns),
46 columns. Check the column count with the first line of the file:

```bash
head -1 data/public.csv | awk -F',' '{print NF}'      # should print 46
```

```stata
* or from within Stata, after loading:
import delimited "data/public.csv", clear
describe, short        // Observations: 410 ; Variables: 46
```

**Expected content.** The file must contain the following columns, among others:
`SHEET`, `CHAIN`, `CO_OWNED`, `STATE`, `NJ`, `SOUTHJ`, `CENTRALJ`, `NORTHEAST`,
`PA1`, `PA2`, `EMPFT`, `EMPPT`, `NMGRS`, `WAGE_ST`, `PSODA`, `PFRY`,
`PENTREE`, and their Wave-2 counterparts with a `2` suffix (`EMPFT2`, `EMPPT2`,
`NMGRS2`, `WAGE_ST2`, `PSODA2`, `PFRY2`, `PENTREE2`).

**Expected downstream counts.** If the file is correct, `01_clean.do` will
report these, and they are the quickest end-to-end check:

| Check | Expected |
| --- | --- |
| Observations after cleaning | 410 |
| New Jersey / Pennsylvania split | 331 / 79 |
| New Jersey Wave-1 wage groups ($4.25 / 4.26–4.99 / ≥$5.00) | 101 / 140 / 73 |
| Table 4 estimation sample | 357 |
| Mean GAP among New Jersey stores | 0.105 |

If any of these differ, the CSV is not the expected release — re-download
Package 01 rather than adjusting the code.
