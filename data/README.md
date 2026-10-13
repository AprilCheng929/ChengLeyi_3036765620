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
