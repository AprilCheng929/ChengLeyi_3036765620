# AI Usage Disclosure

**ECO6067 — Individual Project: Card & Krueger (1994) replication and extension**

This document records where AI tools were used in this project, how their output
was verified, and — most importantly — the errors detected and corrected. It is
organised to match the disclosure requirements in the course brief.

---

## 1. Where AI was used

| Stage | AI involvement | Human responsibility |
| --- | --- | --- |
| Reading the paper | Exegetical support: locating and transcribing the definitions of FTE, GAP, the proportional change measure, and the sample rules from the PDF | Read the paper; confirmed each definition against the source text |
| Variable construction | Drafting the Stata code in `01_clean.do` | Specified which paper passages govern each variable; verified the constructions reproduce published counts |
| Regression code | Drafting `02_table2.do` through `06_table5.do` | Verified every coefficient against the published tables |
| Extension design | Discussion of candidate extensions; the pre-tax decomposition and product-level split were developed in dialogue | Chose the research question; decided which extensions were economically meaningful |
| Report drafting | Structural and editorial assistance | Wrote and revised the argument; all interpretation is the author's |
| Code review | Used to cross-check the empirical output independently | Independently verified the replication numbers |

---

## 2. How AI output was checked

Three verification practices were applied throughout.

**Independent recomputation.** The replication figures were recomputed from the
raw CSV using a separate implementation (Python/NumPy OLS) before the Stata code
was finalised. Where the two disagreed, the discrepancy was investigated rather
than resolved in favour of either estimate. This is what surfaced the sample
construction error described in Section 3.2 below.

**Comparison against published values.** Every table was checked cell-by-cell
against the scanned published tables. This was treated as a genuine test, not a
formality: a `~` flag was recorded for any coefficient that did not match to two
decimal places, and each flagged value was investigated.

**Internal consistency checks.** Sample sizes, group counts, and the mean and
standard deviation of the dependent variable — all reported in the paper — were
checked alongside the coefficients. These are more diagnostic than coefficients
alone, because they reveal whether the underlying sample is correctly built.
When the Table 4 sample reached exactly 357 and the dependent variable's standard
deviation reached exactly 8.825, that was strong evidence the sample construction
rather than the regression was correct.

---

## 3. Errors and suggestions that were corrected or rejected

### 3.1 Figure 1 misidentified as an employment distribution

**Initial assumption:** Figure 1 plots the distribution of employment across
stores, since the paper's central subject is employment.

**Correction:** The text states explicitly that the figure plots "the overall
distributions of **starting wages** in the two states from the two waves". The
initial reading inverted the figure's purpose entirely, and would have produced
a chart that looked plausible but answered the wrong question.

**Resolution:** Code rewritten to plot wage distributions. The observed 85.5
percent pile-up at $5.05 (paper: 85.2 percent) confirmed the corrected reading.

### 3.2 Table 5 specifications combined the NJ dummy and GAP in one regression

**Initial implementation:** All four Table 5 columns were estimated by entering
both `nj` and `gap` into a single regression.

**Symptom:** The base row returned 1.06 and 11.92 against published values of
2.30 and 14.92 — visibly wrong, and inconsistent with Table 4, which shares the
same base specification.

**Diagnosis:** Table 4's columns (2) and (4) — which the Table 5 base row is
stated to reproduce — each contain only *one* of the two variables. Entering both
jointly changes the estimand: the New Jersey dummy absorbs part of the effect
that GAP would otherwise capture.

**Resolution:** Rewrote `t5row` so that `nj` and `gap` are estimated in
**separate** regressions. The base row then reproduced 2.30 / 14.92 / 0.05 / 0.34
exactly. A comment was added to the do-file flagging this explicitly, since it is
the kind of error that produces plausible-looking output.

### 3.3 Tables 3 rows 3 and 4 constructed identically

**Initial implementation:** Both rows were computed from the balanced-sample
change variable `dfte`.

**Symptom:** The two rows returned identical values, and the shared value
matched the paper's row 4 but not its row 3 (2.75 against a published 2.76).

**Diagnosis:** The paper's rows are subtly different objects. Row 3 differences
two separately estimated means — the Wave-1 and Wave-2 samples need not coincide
— whereas row 4 differences within-store changes and forces a common sample.

**Resolution:** Row 3 rebuilt as `mean(fte2) − mean(fte1)` with the standard
error of a difference of independent means. Rows now return 2.76 and 2.75
respectively, matching the paper. This would have gone undetected without the
independent recomputation described in Section 2: both rows would have looked
internally consistent while silently misrepresenting the paper's construction.

### 3.4 Robust standard errors did not reproduce the published values

**Initial implementation:** Robust (heteroskedasticity-consistent) standard
errors in all Table 4 regressions.

**Symptom:** Coefficients matched exactly, but standard errors were
systematically larger — 1.45 against 1.19 in column (1).

**Diagnosis:** Consistent and one-directional across all ten columns, which is
characteristic of a standard-error convention mismatch rather than a data
problem. The paper reported conventional OLS standard errors.

**Resolution:** Switched to conventional standard errors, which match published
values throughout. The choice is documented in the report rather than left
implicit, since it is a defensible modelling decision and not merely a device
for improving the fit.

### 3.5 Rejected suggestion: dropping the Wave-2 wage requirement

**Suggestion received:** Simplify the Table 4 sample rule to "non-missing
employment and Wave-1 wage in both waves", omitting the Wave-2 wage condition.

**Why rejected:** This produces a sample of 365, against a published 357. The
missing eight stores are the six permanently closed stores, whose Wave-2 wages
are absent by construction. Footnote 16 resolves this: closed stores are
assigned a Wave-2 wage equal to their state average. Applying that imputation
yields exactly 357 — the published figure. Accepting the simplification would
have abandoned an exact replication of the sample for a marginal reduction in
code length.

### 3.6 Rejected suggestion: including the NJ dummy in the Pennsylvania-only placebo

**Suggestion received:** Estimate the Pennsylvania-only placebo regression with
the full control set including the New Jersey dummy.

**Why rejected:** The New Jersey dummy is identically zero within Pennsylvania,
making the design matrix singular and the coefficient undefined. In the paper's
Table 5, the Pennsylvania-only row reports only the GAP coefficient and shows a
dash for the dummy columns — confirming that the original authors faced the same
constraint. The code was written to omit the dummy in that specification.

### 3.7 Extension scope reduced

**Initial proposal:** A substantially broader extension adding external data on
state-level economic conditions and a synthetic control construction.

**Why scaled back:** The additional analysis would have required external data
whose collection time exceeded the value it added, and the synthetic control
design was poorly suited to a two-state setting with a single treated unit.
Resources were redirected to the three extensions reported, each of which
addresses a specific gap identified in the published paper.

---

## 4. What was not delegated

The following decisions were made by the author, not by AI tools:

- The choice of extension question (cost incidence) and the judgement that the
  paper's price-analysis tension was worth pursuing.
- The interpretation of the extension results — in particular the reading that
  product-level concentration reconciles the aggregate puzzle.
- The assessment of which deviations from the published results were acceptable
  and which indicated a genuine error requiring correction.
- The decision to report the Table 5 row 2 deviation rather than attempt to
  reverse-engineer the original authors' processing.

---

## 5. Summary

AI tools substantially accelerated code drafting and document preparation. They
also, on six occasions documented above, produced output that was confidently
wrong. Three of those errors — the misidentified figure, the incorrect Table 5
specification, and the duplicated Table 3 construction — would have been
invisible in the final results without explicit verification against the
published tables and an independent recomputation. The replication would have
looked complete while being wrong in three separate places.

The verification discipline, not the code generation, is what determines whether
the result is trustworthy.
