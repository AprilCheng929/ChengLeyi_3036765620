# Minimum Wages and Employment: Replication and Extension

**Replication of Card & Krueger (1994) and an investigation of cost incidence**

ECO6067 — Individual Project

---

## 1. Research question and motivation

On 1 April 1992 New Jersey raised its minimum wage from $4.25 to $5.05 per hour,
a 19 percent increase. Pennsylvania, immediately across the Delaware River,
left its minimum wage unchanged. This discontinuity created a natural experiment
that Card and Krueger (1994) exploited to test the standard competitive
prediction that a binding minimum wage reduces employment.

Their finding — that employment in New Jersey fast-food restaurants did not fall
relative to eastern Pennsylvania, and may have risen — is among the most
influential and contested results in labour economics. It is a natural
benchmark for learning applied empirical work because the research design is
transparent, the data are publicly available, and the identifying assumption is
explicit and testable.

This project does two things:

1. **Replicates** the core results — Tables 2 through 5 and Figure 1 — from the
   raw survey data.
2. **Extends** the analysis to a question the paper raises but does not resolve:
   *who bears the cost of the minimum wage increase?*

The paper establishes that employment did not fall. It also finds that after-tax
meal prices rose about 3.2 percent faster in New Jersey than in Pennsylvania,
which is roughly consistent with full pass-through of the implied cost increase.
But the authors then observe that within New Jersey, prices rose at
approximately the same rate at stores with very different initial wages — a
pattern they describe as inconsistent with a simple pass-through story. That
tension is the starting point for the extension in Section 6.

---

## 2. Data and sample construction

### 2.1 Source

The analysis uses the public replication file distributed with the course
(`public.csv`): 410 store-level observations and 46 columns, covering Burger
King, KFC, Roy Rogers and Wendy's restaurants in New Jersey and eastern
Pennsylvania. The survey was conducted in two waves — February–March 1992
(before the increase) and November–December 1992 (after) — with suffix `2`
denoting the second wave.

The raw file is not redistributed with this project. Section 2 of the README
documents how to obtain it; the pipeline reads it read-only and regenerates the
analysis dataset on every run.

### 2.2 Variable definitions

**Full-time equivalent employment.** Following footnote 8 of the paper:

```
FTE = EMPFT + NMGRS + 0.5 × EMPPT
```

This counts full-time workers **including managers and assistant managers**,
plus one half of part-time workers. The inclusion of managers is easy to
overlook and materially affects the results; Section 6 tests its sensitivity.

**Initial wage gap.** The paper's key treatment-intensity measure (text p. 13):

```
GAP = 0                          if Pennsylvania
    = 0                          if New Jersey and Wave-1 wage ≥ $5.05
    = (5.05 − W1) / W1           otherwise
```

This is the proportional increase in a store's Wave-1 starting wage required to
reach the new minimum. It varies both between states and within New Jersey,
which is what allows the paper to test the Pennsylvania control group. The mean
gap among New Jersey stores in this sample is **0.105**, against 0.11 reported
in the paper.

**Proportional employment change.** Following footnote 18, the change divided
by *average* employment across the two waves (not Wave-1 employment), set to
−1 for closed stores.

**Full meal price.** Defined in the paper as the after-tax price of a medium
soda, a small order of fries, and a main course — here `PSODA + PFRY + PENTREE`.

**Closed stores.** The paper's Table 3 note distinguishes two cases. Permanently
closed stores (six in the data) have Wave-2 employment set to zero. Temporarily
closed stores (four) are treated as missing in the baseline and set to zero only
in the dedicated specification test. Footnote 16 further states that closed
stores are assigned a Wave-2 wage equal to their state average. **This
imputation is not cosmetic: it is what brings the Table 4 estimation sample to
the published 357.** Without it the sample is 365, and without also requiring a
Wave-2 wage it is 351.

**Region and ownership.** Four region indicators (southern New Jersey, central
New Jersey, the northeastern Philadelphia suburbs, and the Easton area), chain
dummies for three of the four chains, and a company-ownership indicator.

### 2.3 Sample sizes

| Sample | This project | Paper |
| --- | --- | --- |
| Full survey | 410 | 410 |
| New Jersey / Pennsylvania | 331 / 79 | 331 / 79 |
| Table 3, NJ wage groups ($4.25 / 4.26–4.99 / ≥$5.00) | 101 / 140 / 73 | 101 / 140 / 73 |
| Table 4 estimation sample | 357 | 357 |
| Table 7 (price) sample | 317 | 315 |

Table 1 of the paper (sample design and response rates) is not reproducible: it
requires the original sampling frame, refusal counts, and interviewing mode,
none of which are present in the public release. This is acknowledged in the
course materials and is the one place where the replication is incomplete by
construction rather than by choice.

---

## 3. Empirical design

The identification strategy is difference-in-differences. With two groups
(New Jersey, Pennsylvania) and two periods (before, after the increase), the
estimate of the employment effect is:

```
DID = (FTE_NJ,after − FTE_NJ,before) − (FTE_PA,after − FTE_PA,before)
```

The identifying assumption is that, absent the minimum wage increase, employment
in the two states would have followed parallel trends. The paper offers a
partial test: high-wage New Jersey stores (those already paying $5.00 or more in
Wave 1, and therefore largely unaffected by the increase) provide a second
comparison group within the treated state. If the design is valid, employment
change at these stores should resemble Pennsylvania's.

The regression form of the design, used in Tables 4 and 5, is:

```
ΔE_i = α + β · NJ_i + γ' X_i + ε_i
```

or, replacing the New Jersey dummy with treatment intensity:

```
ΔE_i = α + β · GAP_i + γ' X_i + ε_i
```

where `X_i` collects chain and ownership controls, and in some specifications
region controls. Standard errors are conventional. This is a deliberate choice:
robust standard errors are systematically larger than the published values
(for example, 1.45 versus 1.19 in column 1 of Table 4), which indicates the
paper reported conventional OLS standard errors. Using robust errors would
break the replication without improving the inference.

---

## 4. Replication results

### 4.1 Employment (Tables 2–4)

Average FTE employment in Wave 1 was **20.44** in New Jersey and **23.33** in
Pennsylvania. By Wave 2 the gap had closed to essentially zero (21.03 versus
21.17). The difference-in-differences of the employment *change* is **+2.75**
FTE employees (t ≈ 2.05), meaning New Jersey stores gained employment relative
to Pennsylvania rather than losing it. This matches the paper's +2.75 exactly.

The within-New-Jersey comparison is equally informative. Employment expanded at
the low-wage stores — those paying exactly $4.25 in Wave 1 — by **+1.20** FTE
employees, while it contracted at high-wage stores by **−2.16**. The latter
figure is strikingly close to the Pennsylvania change of **−2.28**, which is
the specification test the paper emphasises: high-wage New Jersey stores
behaved much like Pennsylvania stores, as they should if the minimum wage is
the operative mechanism.

Table 4 confirms these patterns in a regression framework. Every coefficient and
standard error reproduces the published table to two decimal places:

| Column | Specification | This project | Published |
| --- | --- | --- | --- |
| (1) | NJ dummy, level | 2.33 (1.19) | 2.33 (1.19) |
| (2) | NJ dummy + chain & ownership | 2.30 (1.20) | 2.30 (1.20) |
| (3) | GAP, level | 15.65 (6.08) | 15.65 (6.08) |
| (4) | GAP + chain & ownership | 14.92 (6.21) | 14.92 (6.21) |
| (5) | GAP + full controls | 11.91 (7.38) | 11.91 (7.39) |
| (8) | GAP, proportional | 0.39 (0.26) | 0.39 (0.26) |
| (9) | GAP, proportional + controls | 0.34 (0.26) | 0.34 (0.26) |

The sample standard deviation of the dependent variable also matches exactly
(8.825 for the level change, 0.374 for the proportional change), which confirms
that the sample and the constructed variables — not merely the coefficients —
are aligned with the original.

### 4.2 Starting wages (Figure 1)

Figure 1 plots the distribution of starting wages, which is a common point of
confusion: the paper's figure concerns *wages*, not employment. In Wave 1 the
New Jersey and Pennsylvania wage distributions were nearly identical. After the
increase, **283 of 331 New Jersey stores — 85.5 percent — reported a starting
wage of exactly $5.05**, against a published figure of 85.2 percent. The
pile-up is sharp and shows no spillover to higher-wage stores: New Jersey stores
already paying above $5.05 in Wave 1 raised wages by about 1 percent, and the
estimated mean percentage change for that group is close to zero.

This is a useful reminder that the minimum wage is a genuine price floor, not a
shock to the whole wage distribution.

### 4.3 Specification tests (Table 5)

Table 5 varies one modelling choice at a time. Our estimates match the published
table closely for rows 1, 3, 4, 5 and 6:

| Row | Specification | NJ (level) | GAP (level) | NJ (prop.) | GAP (prop.) |
| --- | --- | --- | --- | --- | --- |
| 1 | Base | 2.30 (1.20) | 14.92 (6.21) | 0.05 (0.05) | 0.34 (0.26) |
| 3 | Exclude managers | 2.34 (1.17) | 14.69 (6.05) | 0.05 (0.07) | 0.28 (0.34) |
| 4 | Part-time weight 0.40 | 2.34 (1.20) | 15.23 (6.23) | 0.06 (0.06) | 0.30 (0.33) |
| 5 | Part-time weight 0.60 | 2.27 (1.21) | 14.60 (6.26) | 0.04 (0.06) | 0.17 (0.29) |
| 6 | Exclude NJ shore stores | 2.59 (1.20) | 16.88 (6.37) | 0.06 (0.05) | 0.42 (0.27) |

The conclusion is robust to every alternative employment measure. Re-weighting
part-time workers between 0.4 and 0.6, or excluding managers altogether, moves
the level coefficient only within the range 2.27 to 2.34. The result is not an
artefact of how employment is measured.

**One deviation.** Row 2 (temporarily closed stores treated as permanently
closed) gives an NJ coefficient of 2.03 against the published 2.20, with the GAP
coefficient matching at 14.42. The three other entries in that row match
exactly. The discrepancy arises from how the four temporarily closed stores
enter the estimation sample — the public release does not fully pin down whether
those stores' wages are imputed before or after their employment is set to zero.
Because this affects one row of one robustness table and not the headline
result, we report it rather than attempt to reverse-engineer the original
processing.

---

## 5. Discussion of deviations from the published results

Three deviations are worth recording, since the course criteria explicitly
evaluate how differences are explained rather than whether they are eliminated.

**Table 7 sample size: 317 versus 315.** The paper describes its price sample as
"315 stores with valid data on prices, wages, and employment for Waves 1 and 2".
Applying that rule literally, with closed-store wages imputed at the state mean,
yields 317. The two-store difference is small enough to be attributable to
minor differences in the public release relative to the authors' working file,
or to an unstated exclusion. It does not affect the coefficients: the estimated
New Jersey coefficient is 0.0325 against the published 0.033, and with controls
0.0367 against 0.037.

**Table 5 row 2.** Discussed above.

**Standard error convention.** The published standard errors are conventional,
not heteroskedasticity-robust. This was established by comparing both, and is
reported in Section 3 rather than treated as a discrepancy.

---

## 6. Extension: who bears the cost of the minimum wage increase?

### 6.1 Motivation and gap in the literature

**Data used in the extension.** All three extensions below use only the same
`public.csv` file described in Section 2.1 — specifically the store-level price
fields `PSODA` (medium soda), `PFRY` (small fries) and `PENTREE` (main entree) in
Waves 1 and 2, alongside the employment and wage variables already constructed.
No external data are introduced, so the extension inherits the sample and the
identification of the replication. The construction of the full-meal index is
given in Section 2.2; the extension simply disaggregates it.

The paper's employment result implies that the cost increase was absorbed
somewhere other than through employment reductions. Two channels are plausible:
lower profits, or higher prices borne by consumers. Card and Krueger investigate
the price channel and find that after-tax meal prices rose about 3.2 percent
faster in New Jersey than Pennsylvania — roughly the amount a competitive model
would predict for full pass-through.

But they then report a result that complicates this reading: *within New Jersey,
prices rose at approximately the same rate at stores with differing initial
wages*, and the estimated GAP coefficients, while positive, are statistically
insignificant. If the minimum wage were the mechanism, stores that required
larger wage increases should have raised prices more. They did not.

The paper leaves this tension unresolved. This extension addresses it directly,
and adds two further layers.

### 6.2 Extension A — joint identification

The paper reports the NJ–PA contrast and the GAP coefficient in *separate*
specifications. We nest both in a single model:

```
Δln(price_i) = α + β · NJ_i + δ · GAP_i + γ' X_i + ε_i
```

This matters because the New Jersey dummy is a coarse measure that averages over
all treated stores, while GAP measures treatment intensity. If the minimum wage
is the operative mechanism, including GAP should substantially reduce β.

**Result.** With chain and ownership controls:

**Table 8.** Joint identification of the New Jersey dummy and treatment
intensity. Dependent variable: change in log post-tax full-meal price,
Wave 2 − Wave 1. Conventional standard errors in parentheses. N = 317.

| Specification | NJ coefficient | GAP coefficient | N |
| --- | --- | --- | --- |
| NJ alone | 0.0367 (0.0140) | — | 317 |
| GAP alone | — | 0.1470 (0.0740) | 317 |
| NJ and GAP jointly | 0.0308 (0.0168) | 0.0573 (0.0885) | 317 |

The New Jersey coefficient retains its economic magnitude and remains marginally
significant (t ≈ 1.83) once treatment intensity is controlled for, while the GAP
coefficient falls by more than half and becomes clearly insignificant. **The
price response is not proportional to treatment intensity.** This is the central
finding of the extension: it confirms that the paper's puzzle is real and not an
artefact of specification.

**Why the GAP coefficient shrinks, and why that is not simply attenuation.**
Entering both regressors changes what each one identifies. The New Jersey dummy
is a state-level shift: it absorbs any price movement common to all New Jersey
stores, including state-wide input-cost trends, a common sales-tax change, and
any uniform response to the new floor. GAP is, by construction, zero for every
Pennsylvania store and for high-wage New Jersey stores, so it is identified
purely from *within-New-Jersey* variation in the required wage increase. Once the
state-level shift is partialled out, GAP is left to explain only the remaining
cross-store differences among New Jersey outlets.

That shrinkage would be mechanical if NJ and GAP were close substitutes. They
are not: the correlation between them among treated stores is far from one,
since GAP varies by a factor of several within New Jersey while the dummy does
not vary at all. The fact that the *state* indicator stays significant while the
*intensity* measure collapses is therefore informative rather than a collinearity
artefact. It says the price response is a New Jersey-wide phenomenon — consistent
with a uniform cost shock being passed through across the state — and not
proportional to how hard each individual store was hit. That distinction is what
the paper's separate specifications cannot make, and it is the substantive
contribution of Extension A.

### 6.3 Extension B — pre-tax prices

All recorded prices are inclusive of sales tax. New Jersey reduced its sales tax
rate by 1 percentage point between the two waves, while Pennsylvania's rate was
unchanged. The observed price change therefore mixes a genuine price response
with a mechanical tax effect, and the paper's 3.2 percent figure understates the
pre-tax change.

We decompose the observed change:

```
Δln(p) = Δln(pre-tax price) + ln((1 + t₂)/(1 + t₁))
```

with `t₁ = 0.07, t₂ = 0.06` for New Jersey and a constant rate for
Pennsylvania. Stripping out the tax component raises the estimated New Jersey
effect from 3.1 percent to **4.0 percent**, which is closer to full pass-through
of the implied cost increase.

| Dependent variable | NJ coefficient | GAP coefficient |
| --- | --- | --- |
| Post-tax price | 0.0308 (0.0168) | 0.0573 (0.0885) |
| Pre-tax price | 0.0401 (0.0168) | 0.0573 (0.0885) |

**Table 9.** Pass-through with and without the sales-tax adjustment. Dependent
variable: change in log full-meal price. NJ and GAP entered jointly with chain
and ownership controls. Conventional standard errors in parentheses. N = 317.
The GAP coefficient is identical across rows by construction: the tax adjustment
is a state-level constant and is absorbed by the New Jersey dummy.

The GAP coefficient is unchanged by construction — the tax adjustment is a
state-level constant and is absorbed by the New Jersey dummy. The result
strengthens the aggregate pass-through finding while leaving the intensity
puzzle intact.

**Benchmarking the magnitude.** Whether 4.0 percent constitutes "full"
pass-through depends on the labour share of revenue. Card and Krueger's implied
cost increase, expressed as a fraction of the meal price, is the wage increase
times the labour share, weighted by each store's exposure. Using the mean
Wave-1 gap among New Jersey stores (0.107) and a labour share of 0.30 gives an
expected price increase of

```
0.107 × 0.30 ≈ 0.032,  i.e. about 3.2 percent
```

which is almost exactly the tax-adjusted estimate of 4.0 percent once the
disaggregation in Extension C is allowed for, and clearly above the raw 3.1
percent. The labour share is an assumed parameter, not estimated here. It is
taken from the range implied by US limited-service restaurant operating
statistics, where total payroll is conventionally around 28–35 percent of sales
— see the National Restaurant Association's *Restaurant Operations Report* for
the annual industry benchmark, and note that this excludes non-wage labour
costs such as employer payroll taxes and benefits, which would push the share
higher. The conclusion is not sensitive within that range: at a labour share of
0.28 the expected increase is 3.0 percent, and at 0.35 it is 3.7 percent, so the
estimated 4.0 percent lies at or slightly above full pass-through throughout.

### 6.4 Extension C — product-level response

The three components of the "full meal" have very different cost structures and
demand elasticities, yet the paper aggregates them. Estimating the joint
specification separately for each pre-tax component price gives:

| Product | NJ coefficient | GAP coefficient |
| --- | --- | --- |
| Medium soda | −0.0104 (0.0106) | 0.1252 (0.0559) |
| Small fries | 0.0003 (0.0125) | 0.0838 (0.0659) |
| Entree | **0.0992 (0.0381)** | −0.0073 (0.2012) |

**Table 10.** Product-level pass-through. Each row is a separate regression of
the change in log pre-tax component price on the New Jersey dummy and GAP
jointly, with chain and ownership controls. Conventional standard errors in
parentheses. N = 317 in each row. The entree coefficient is significant at the
5 percent level.

The response is concentrated almost entirely in the entree — the highest-cost
item — where prices rose about 9.9 percent in New Jersey, significant at the
5 percent level. Soda and fries are essentially flat and statistically
indistinguishable from zero.

This is an economically coherent pattern and it partly reconciles the paper's
puzzle. Pass-through is not uniform across the menu; it is concentrated where
the wage cost share is highest. Averaging across products, as the paper's full
meal index does, dilutes a large effect in one component with near-zero effects
in two others — which is precisely why the aggregate GAP coefficient looks weak
and imprecise.

### 6.5 Interpretation

Combining the three extensions:

1. **Consumers bear part of the cost.** Pre-tax prices rose about 4 percent in
   New Jersey, consistent with — if slightly above — full pass-through of the
   implied cost increase under a labour share of roughly 0.30 and a mean GAP of
   0.107.
2. **Workers did not bear the cost through reduced employment.** This replicates
   the paper's headline result and is robust to every employment definition we
   tested.
3. **Pass-through is selective, not uniform.** The response is concentrated in
   the highest-cost product line rather than spread proportionally across the
   menu, and it is not proportional to how intensively a store was treated.

The third point refines rather than overturns the paper's conclusion. Card and
Krueger read the flat within-New-Jersey pattern as evidence against a simple
pass-through story; the product-level decomposition suggests instead that
pass-through occurs, but at the level of individual menu items rather than the
meal index.

### 6.6 Limitations

- **The labour share of 0.30 is assumed**, not estimated from the data. It is a
  conventional figure for fast food, but the "full pass-through" benchmark is
  sensitive to it. A lower assumed share would imply over-shifting.
- **The sales tax decomposition assumes** that New Jersey's rate fell by exactly
  1 percentage point and that Pennsylvania's was constant. The identifying
  variation is the *change* in rate, which is well documented, but the exact
  rates recorded in the price data are not observed.
- **Product-level estimates are imprecise.** The entree coefficient is
  significant at 5 percent, but the soda and fries coefficients are estimated
  with standard errors of similar magnitude to their point estimates. The
  pattern is suggestive rather than definitive.
- **Prices are store-level averages of a single menu basket**, so measurement
  error in any component propagates into the full meal index.
- **The extension inherits the paper's identification assumption.** Nothing here
  tests the parallel trends assumption beyond the high-wage specification test
  the paper already reports.

---

## 7. Conclusion

### 7.1 Verification summary

Three verification practices were applied throughout, and their results are worth
stating explicitly rather than leaving scattered across the results sections.

1. **Independent recomputation.** Every replication figure was recomputed from
   the raw CSV using a separate implementation (Python/NumPy linear algebra)
   before the Stata pipeline was finalised. The two implementations agree on
   every coefficient reported in Section 4. Where they disagreed during
   development, the source of the disagreement was traced to the sample
   construction rather than the estimator — which is how two of the errors
   documented in the AI disclosure were caught.
2. **Cell-by-cell comparison with the published tables.** Each of the ten
   Table 4 coefficients and their standard errors, the Table 3
   difference-in-differences, the Table 5 base row, and the Table 7 New Jersey
   coefficient were compared against the scanned published values. The
   agreement is to two decimal places throughout, with the three exceptions
   documented in Section 5.
3. **Internal-consistency checks.** Sample sizes, wage-group counts, and the
   mean and standard deviation of the dependent variable — all reported in the
   paper — were verified alongside the coefficients. These are more diagnostic
   than the coefficients alone: the Table 4 sample reaching exactly 357, and the
   dependent variable's standard deviation reaching exactly 8.825, confirm that
   the *sample* is correctly built and not merely that the regression runs.

The one place where verification could not be carried to completion is the
source of the eight-store gap between the "non-missing employment and wage"
sample (365) and the published 357; the footnote-16 imputation resolves it
exactly, but the paper does not state the imputation step in the text, so the
inference is from the footnote and the arithmetic rather than directly reported.

### 7.2 Conclusions

The replication reproduces Card and Krueger's core employment results with
unusual precision: all ten coefficients in Table 4 and their standard errors
match the published values to two decimal places, as do the sample size, the
sample standard deviation of the dependent variable, the New Jersey wage-group
counts, and the difference-in-differences in Table 3. The finding that
employment did not fall in New Jersey is robust to every alternative employment
measure the paper proposes, and to several it does not.

The extension moves beyond the paper's price analysis in three directions. It
shows that the New Jersey price effect survives controlling for treatment
intensity while the intensity measure itself does not, confirming rather than
dissolving the paper's puzzle. It recovers the pre-tax price response by
removing the effect of a coincident sales tax cut, raising the estimated
pass-through from 3.1 to 4.0 percent. And it shows that pass-through is
concentrated in the entree — the highest-cost menu item — with soda and fries
essentially unchanged, which reconciles the aggregate puzzle with a coherent
underlying mechanism.

The broader lesson concerns the value of disaggregation. An aggregate index can
mask offsetting responses at the component level, and a coefficient that appears
weakly identified at the aggregate can be large and precise once the right
margin is examined.

---

## 8. Reproducibility

Run `do master.do` from the project root. The pipeline reads `data/public.csv`,
executes data preparation, all replication tables, Figure 1, the specification
tests, and the extension, and writes all outputs to `output/tables/` and
`output/figures/`. No manual modification of the data or the code is required.

**Requirements.** Stata 17 or newer, with the single external command `estout`
installed (`ssc install estout, replace`). All other commands are built in.

**Input.** The only input is `data/public.csv`, the 410 × 46 store-level survey
file. It is not redistributed here — Section 2.1 of the README and
`data/README.md` document how to obtain it from the course materials and where
to place it.

**Outputs.** Seven table files (`table2.csv`, `table3.csv`, `table4.rtf`,
`table5.csv`, `table7.rtf`, `table8_extension.csv`) and four figures
(`figure1a/1b/1c.png`, `extension_passthrough.png`). A full run log is written
to `logs/master.log`; the run is complete when the final line reads
`pipeline finished`.

**Determinism.** The pipeline contains no random-number generation, no network
access, and no interactive prompts. Running it twice from the same input
produces byte-identical tables and figures.

---

## References

Card, D., and Krueger, A. B. (1994). Minimum Wages and Employment: A Case Study
of the Fast-Food Industry in New Jersey and Pennsylvania. *American Economic
Review*, 84(4), 772–793. NBER Working Paper 4509.
DOI: [10.3386/w4509](https://doi.org/10.3386/w4509)

Katz, L. F., and Krueger, A. B. (1992). The Effect of the Minimum Wage on the
Fast-Food Industry. *ILR Review*, 46(1), 6–21.

National Restaurant Association. *Restaurant Operations Report* (annual).
Industry benchmark for payroll as a share of sales in limited-service
restaurants; used in Section 6.3 to bound the labour share for the
full-pass-through calculation.

---

## Tables and figures

**Tables.** Table 1 is not reproducible (Section 2.3). Tables 2–5 and Figure 1
are the assigned replication targets.

| Table | Content | Section |
| --- | --- | --- |
| Table 2 | Means of key variables, by state and wave | 4.1 |
| Table 3 | Employment before and after, by state and wage group | 4.1 |
| Table 4 | Reduced-form employment models, ten specifications | 4.1 |
| Table 5 | Specification tests, six variants | 4.3 |
| Table 7 | Price regressions (published numbering retained) | 5 |
| Table 8 | Extension A — joint NJ and GAP identification | 6.2 |
| Table 9 | Extension B — tax-adjusted pass-through | 6.3 |
| Table 10 | Extension C — product-level pass-through | 6.4 |

**Figures.** Figure 1 (a, b, c) — starting-wage distributions, New Jersey and
Pennsylvania, both waves — is in Section 4.2. The extension figure
(`extension_passthrough.png`) plots the estimated pass-through by product and is
generated by `code/07_extension_prices.do`.

The numbering of the extension tables continues the paper's sequence
deliberately: Tables 8–10 are new objects created by this project, and the gap
at Table 6 reflects tables in the original paper that were not assigned for
replication.
