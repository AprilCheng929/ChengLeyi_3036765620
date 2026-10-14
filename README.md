# Replication and Extension of Card & Krueger (1994)

**ECO6067 — Individual Project: AI-assisted empirical replication**

Replication of Card, D. and Krueger, A. B. (1994), "Minimum Wages and
Employment: A Case Study of the Fast-Food Industry in New Jersey and
Pennsylvania", *American Economic Review*, 84(4), 772–793 — plus an
independent extension on the incidence of the minimum wage.

> **Deliverables.** The empirical report is [`report/report.pdf`](report/report.pdf)
> (Markdown source: [`report/report.md`](report/report.md)); the AI usage
> disclosure is [`report/ai_usage_disclosure.md`](report/ai_usage_disclosure.md).
> This README is the reproducibility package: it documents the data, the
> variable definitions, and the workflow that regenerates every table and figure.

---

## 1. Research question

On 1 April 1992 New Jersey raised its minimum wage from $4.25 to $5.05 per
hour. Pennsylvania's minimum wage was unchanged. This project:

1. **Replicates** the paper's core results (Tables 2–5 and Figure 1), which
   compare employment change in New Jersey fast-food restaurants with
   restaurants across the Delaware River in eastern Pennsylvania.
2. **Extends** the analysis by asking *who actually bears the cost of the
   minimum wage increase* — shareholders, workers through reduced employment,
   or consumers through higher prices.

---

## 2. Data

**Source.** The store-level survey data (`public.csv`) is distributed to the
course as `01_DID.zip` through the ECO6067 course materials. It is the public
replication file for the paper, containing 410 observations and 46 columns.
The original replication package is available from Princeton University.

**How to obtain it.** The ECO6067 course materials grant use of this file for
teaching and coursework only, and expressly forbid redistributing it or
uploading it to public repositories. It is therefore **not** committed here.
To reproduce the results:

1. Obtain `Package 01` (18 KB ZIP, "Minimum wage / DID") from the ECO6067
   *Project Data Downloads* page. Access is available until 22 October 2026,
   23:59 Hong Kong time.
2. Extract it and copy `public.csv` into the `data/` folder so the layout is:

```
econ6067-ck1994-minwage/
└── data/
    └── public.csv          <- you supply this file
```

3. Run `do master.do`. Every table and figure is then regenerated from scratch.

The raw file is never modified. `code/01_clean.do` reads it once and derives an
intermediate `data/analysis.dta`, which is also not committed because it is
recreated on every run.

**Note.** Table 1 of the paper (sample design and response rates) cannot be
reproduced: it requires the original sampling frame, refusal counts, and
interviewing mode, none of which are present in the public release. This is
acknowledged in the course materials.

---

## 3. How to reproduce

### Requirements

- **Stata 17 or newer** (the code uses only built-in commands and `estout`;
  no version-specific features beyond Stata 15 syntax).
- Install the one external command used for table export:

```stata
ssc install estout, replace
```

### Run

Open Stata in the project root and run:

```stata
do master.do
```

`master.do` executes the full pipeline in order. **No manual editing of the
data or of any do-file is required.** Outputs are written to `output/tables/`,
`output/figures/`, and `logs/master.log`.

### Custom project location

`code/00_settings.do` resolves the project root automatically from the working
directory. If your layout differs, set the environment variable before running:

```stata
global root "C:/path/to/econ6067-ck1994-minwage"
```

Everything else is defined relative to that root in `00_settings.do`; edit that
file only.

---

## 4. Reusable workflow — regenerating every table and figure

The course brief asks for *"a reusable skill or workflow that generates the main
tables and figures"*. This repository is that workflow. It is self-contained:
given the input CSV, one command produces every number reported in the paper
replication and in the extension.

```
data/public.csv  ──►  do master.do  ──►  output/tables/*   (7 files)
                                         output/figures/*  (4 figures)
                                         logs/master.log   (full run log)
```

**How to use it**

1. Place `public.csv` in `data/` (see Section 2).
2. From the project root, run `do master.do`.
3. Read the outputs from `output/tables/` and `output/figures/`. The run is
   complete when the log's last line is `pipeline finished`.

**Why it is reusable**

- **No manual steps.** The pipeline contains no interactive prompts, no
  hard-coded file paths beyond the project root, and no edits required to the
  data or the code between runs.
- **Single point of configuration.** `code/00_settings.do` defines every path
  and global; nothing else in the pipeline hard-codes a location. To relocate
  the project, set `global root "..."` and run — no other file changes.
- **Modular stages.** Each do-file is a self-contained stage (clean → tables →
  figure → specification tests → extension). A stage can be re-run in isolation
  without re-running the whole pipeline, which is what makes it usable for a
  different sample or a new robustness check.
- **Deterministic.** No random number generation and no network access, so
  repeated runs produce byte-identical output.
- **Extensible to a new paper.** The structure — settings, cleaning, one file
  per table, one per figure, extension — is not specific to Card & Krueger. It
  is the reusable part: only `01_clean.do` and the table do-files change when
  the underlying study changes, while the orchestration and settings layout
  carry over unchanged.

---

## 5. Pipeline overview

| File | Purpose |
| --- | --- |
| `code/00_settings.do` | Paths, globals, raw-data check |
| `code/01_clean.do` | Build the analysis sample and all constructed variables |
| `code/02_table2.do` | Table 2 — means of key variables |
| `code/03_table3.do` | Table 3 — employment before and after |
| `code/04_table4.do` | Table 4 — reduced-form employment models |
| `code/05_figure1.do` | Figure 1 — starting-wage distributions |
| `code/06_table5.do` | Table 5 — specification tests |
| `code/07_extension_prices.do` | Independent extension — price pass-through |

### Key variable definitions

These follow the paper exactly and are the most common source of error.

**Full-time equivalent employment** (footnote 8):

```
FTE = EMPFT + NMGRS + 0.5 * EMPPT
```

Full-time workers **including managers and assistant managers**, plus one half
of part-time workers.

**Initial wage gap** (text p. 13):

```
GAP = 0                        if Pennsylvania
    = 0                        if New Jersey and Wave-1 wage >= $5.05
    = (5.05 - W1) / W1         otherwise
```

The proportional increase in the Wave-1 starting wage required to reach the new
minimum. Mean GAP among New Jersey stores is 0.105 (paper: 0.11).

**Proportional employment change** (footnote 18): the change divided by
*average* employment across the two waves, set to −1 for closed stores.

**Full meal price**: after-tax price of a medium soda, a small order of fries,
and a main entree (`PSODA + PFRY + PENTREE`).

**Closed stores** (Table 3 note): Wave-2 employment is zero for permanently
closed stores; temporarily closed stores are treated as missing in the baseline
and set to zero only in the dedicated specification test. Wave-2 wages of
closed stores are imputed at the state mean (footnote 16) — this imputation is
what brings the Table 4 sample to the published 357.

---

## 6. Replication results

| Result | This project | Card & Krueger (1994) |
| --- | --- | --- |
| FTE employment, Wave 1 (NJ / PA) | 20.44 / 23.33 | 20.44 / 23.33 |
| NJ stores by Wave-1 wage ($4.25 / 4.26–4.99 / ≥$5.00) | 101 / 140 / 73 | 101 / 140 / 73 |
| Table 3, DID of employment change | +2.75 | +2.75 |
| Table 3, temp. closures at zero | +2.51 | +2.51 |
| Table 4 sample | 357 | 357 |
| Table 4, col (1) NJ coefficient | 2.33 (1.19) | 2.33 (1.19) |
| Table 4, col (3) GAP coefficient | 15.65 (6.08) | 15.65 (6.08) |
| Table 4, col (8) GAP, proportional | 0.39 (0.26) | 0.39 (0.26) |
| Table 5, base row (reproduces Table 4 cols 2/4/7/9) | 2.30 / 14.92 | 2.30 / 14.92 |
| Figure 1, NJ low-wage stores moving to exactly $5.05 | 86.4% | 85.2% |
| Table 7, col (1) NJ coefficient | 0.0325 (0.0144) | 0.033 (0.014) |

All Table 4 coefficients and standard errors match the published table to two
decimal places. Standard errors are conventional (non-robust), matching the
paper — robust standard errors are systematically larger and do not reproduce
the published values.

**Documented deviations.** The Table 7 sample is 317 rather than the published
315; the extension sample inherits this. Table 5 row 2 (temporarily closed
stores treated as permanently closed) gives an NJ coefficient of 2.03 against
the published 2.20, a difference attributable to how the four temporarily closed
stores enter the sample. These deviations are discussed in the report.

---

## 7. Extension: who bears the cost?

The paper finds that employment did not fall in New Jersey, that after-tax meal
prices rose about 3.2% faster than in Pennsylvania, but — the authors note —
that within New Jersey prices rose at roughly the same rate at stores with very
different initial wages. They describe this as inconsistent with a simple
pass-through story but do not resolve it.

This extension addresses three gaps:

1. **Joint identification.** The paper reports the NJ–PA contrast and the GAP
   coefficient in separate specifications. We nest both. The NJ dummy remains
   economically and marginally statistically significant (≈3.1%, t ≈ 1.8) while
   the GAP coefficient becomes small and insignificant — confirming that price
   responses are *not* proportional to treatment intensity.

2. **Pre-tax prices.** New Jersey cut its sales tax by 1 percentage point
   between the two waves, and all recorded prices are tax-inclusive. Removing
   the tax component raises the estimated NJ price effect to ≈4.0%, closer to
   full pass-through of the implied cost increase.

3. **Product-level response.** The three meal components respond very
   differently: the entree price rises about 9.9% in New Jersey (significant),
   while soda and fries are essentially flat. This is consistent with pass-
   through being concentrated where the wage cost share is highest.

**Interpretation.** Taken together, the evidence favours *partial* pass-through
concentrated in the highest-cost product line, rather than the uniform price
increase a competitive model would predict. Consumers bear part of the cost;
the absence of an employment response means workers did not.

---

## 8. Repository structure

```
econ6067-ck1994-minwage/
├── README.md
├── master.do                     # one-click pipeline
├── code/
│   ├── 00_settings.do
│   ├── 01_clean.do
│   ├── 02_table2.do
│   ├── 03_table3.do
│   ├── 04_table4.do
│   ├── 05_figure1.do
│   ├── 06_table5.do
│   └── 07_extension_prices.do
├── data/
│   ├── README.md                 # how to obtain public.csv (not committed)
│   └── (public.csv — YOU SUPPLY THIS FILE, see section 2)
├── output/
│   ├── tables/                   # table2.csv, table3.csv, table4.rtf,
│   │                             # table5.csv, table7.rtf, table8_extension.csv
│   └── figures/                  # figure1a/1b/1c, extension_passthrough
├── logs/                         # master.log (not committed: run artefact)
└── report/
    ├── report.md                 # full empirical report (Markdown source)
    ├── report.pdf                # same report, rendered PDF
    └── ai_usage_disclosure.md
```

---

## 9. AI usage

All AI assistance is documented in `report/ai_usage_disclosure.md`, including
where AI tools were used, how their output was verified, and the errors that
were caught and corrected.

---

## 10. References

Card, D., and Krueger, A. B. (1994). Minimum Wages and Employment: A Case Study
of the Fast-Food Industry in New Jersey and Pennsylvania. *American Economic
Review*, 84(4), 772–793. Working paper: NBER WP 4509,
DOI [10.3386/w4509](https://doi.org/10.3386/w4509).
