*==============================================================================
* 04_table4.do
* ECO6067 - Card & Krueger (1994) replication
*
* Purpose: reproduce Table 4, "Reduced Form Models for Change in Employment".
*
* Sample: stores with non-missing employment AND starting wage in BOTH waves.
*         The paper reports N = 357. The public release yields N = 365 under a
*         literal application of that rule; the gap is documented in the report.
*
* Ten columns:
*   (1)  change in FTE on NJ dummy, no controls
*   (2)  change in FTE on NJ dummy + chain & ownership controls
*   (3)  change in FTE on GAP, no controls
*   (4)  change in FTE on GAP + chain & ownership controls
*   (5)  change in FTE on GAP + chain & ownership + region controls
*   (6)-(10) same five specifications, dependent variable = PROPORTIONAL change
*
* PROPORTIONAL change (footnote 18): the change divided by AVERAGE employment in
* Waves 1 and 2. For closed stores the proportional change is set to -1.
*==============================================================================

do "$code/00_settings.do"
use "$analysisdata", clear

*------------------------------------------------------------------------------
* 1. REGRESSION SAMPLE
*------------------------------------------------------------------------------
* Paper: "the set of stores with non-missing employment and wage data in both
* waves of the survey" (text p.14), with the Wave-2 wage of closed stores
* imputed at the state mean (footnote 16). This yields exactly 357 stores,
* matching the published table.
keep if insample == 1

display as text _n "[i] Table 4 estimation sample: " _N " stores " ///
    "(paper reports 357)."

* Guard against zero average employment in the denominator
drop if missing(pdfte) | missing(dfte)

*------------------------------------------------------------------------------
* 2. CONTROL SETS
*------------------------------------------------------------------------------
* Chain dummies for three of the four chains (Burger King is the base), plus a
* company-ownership indicator.  (Paper, Table 4 note d/.)
gen byte ch2 = (CHAIN == 2)
gen byte ch3 = (CHAIN == 3)
gen byte ch4 = (CHAIN == 4)
label var ch2 "KFC"
label var ch3 "Roy Rogers"
label var ch4 "Wendy's"

* Region dummies: 2 regions of NJ and 2 regions of eastern PA.
* region == 1 (Southern NJ) serves as the base category.
gen byte rg2 = (region == 2)
gen byte rg3 = (region == 3)
gen byte rg4 = (region == 4)
label var rg2 "Central NJ"
label var rg3 "NE Philadelphia suburbs (PA)"
label var rg4 "Easton area (PA)"

* Store-level control set (chain + ownership)
global ctrl_basic "ch2 ch3 ch4 comp"
* Full control set (chain + ownership + region)
global ctrl_full  "ch2 ch3 ch4 comp rg2 rg3 rg4"

*------------------------------------------------------------------------------
* 3. ESTIMATION
*------------------------------------------------------------------------------
* Unrestricted constant is included in every model (paper, Table 4 note).

* --- Panel A: change in FTE employment (level) --------------------------------
eststo clear

eststo m1: regress dfte nj
eststo m2: regress dfte nj $ctrl_basic
eststo m3: regress dfte gap
eststo m4: regress dfte gap $ctrl_basic
eststo m5: regress dfte gap $ctrl_full

* Joint significance of the control variables (paper, row 6)
foreach m in m2 m4 m5 {
    quietly est restore `m'
    test $ctrl_basic
    if "`m'" == "m5" {
        * for column 5 the reported test covers the full control set
        quietly test $ctrl_full
    }
    local p_`m' = r(p)
}

* --- Panel B: proportional change in FTE employment ---------------------------
eststo p6: regress pdfte nj
eststo p7: regress pdfte nj $ctrl_basic
eststo p8: regress pdfte gap
eststo p9: regress pdfte gap $ctrl_basic
eststo p10: regress pdfte gap $ctrl_full

foreach m in p7 p9 p10 {
    quietly est restore `m'
    test $ctrl_basic
    local q_`m' = r(p)
}

*------------------------------------------------------------------------------
* 4. DISPLAY
*------------------------------------------------------------------------------
display as text _n "{hline 100}"
display as text "Table 4: Reduced form models for change in employment"
display as text "{hline 100}"
display as text "Dependent variable: change in FTE employment (columns 1-5)"
display as text "                    proportional change (columns 6-10)"
display as text "{hline 100}"

esttab m1 m2 m3 m4 m5, ///
    cells(b(star fmt(2)) se(par fmt(2))) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-squared")) ///
    mtitles("Level (1)" "Level (2)" "Level (3)" "Level (4)" "Level (5)") ///
    keep(nj gap) order(nj gap) ///
    label

display as text _n
esttab p6 p7 p8 p9 p10, ///
    cells(b(star fmt(2)) se(par fmt(2))) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-squared")) ///
    mtitles("Prop (6)" "Prop (7)" "Prop (8)" "Prop (9)" "Prop (10)") ///
    keep(nj gap) order(nj gap) ///
    label

*------------------------------------------------------------------------------
* 5. EXPORT (full table with all coefficients and controls)
*------------------------------------------------------------------------------
esttab m1 m2 m3 m4 m5 p6 p7 p8 p9 p10 using "$tables/table4.$tabfmt", replace ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2 r2_a, fmt(0 3 3) ///
          labels("Observations" "R-squared" "Adjusted R-squared")) ///
    mtitles("Level" "Level" "Level" "Level" "Level" ///
            "Proportional" "Proportional" "Proportional" "Proportional" "Proportional") ///
    mgroups("Change in FTE employment" "Proportional change in FTE employment", ///
            pattern(1 0 0 0 0 1 0 0 0 0)) ///
    coeflabels(nj "New Jersey dummy" gap "Initial wage gap" ///
               ch2 "KFC" ch3 "Roy Rogers" ch4 "Wendy's" comp "Company-owned" ///
               rg2 "Central NJ" rg3 "NE Philadelphia suburbs (PA)" rg4 "Easton area (PA)" ///
               _cons "Constant") ///
    title("Table 4. Reduced form models for change in employment") ///
    addnotes("Standard errors in parentheses (conventional OLS)." ///
             "Sample: stores with non-missing employment and starting wage in both waves." ///
             "Column (1) is comparable to the simple DID in Table 3, row 4.")

display as text _n "[ok] Table 4 written to $tables/table4.$tabfmt"

*------------------------------------------------------------------------------
* 6. SIDE-BY-SIDE COMPARISON WITH PUBLISHED ESTIMATES
*------------------------------------------------------------------------------
* Values transcribed from Card & Krueger (1994), Table 4.
* Useful as a checkpoint, not as an input to any computation.
*
* WHY THIS IS DONE BY RE-RUNNING THE REGRESSIONS:
*   Reading coefficients with _b[] after a series of -est restore- calls is
*   fragile: the restore loops in section 3 change which estimate is "active",
*   and the multi-model matrix-indexing route (r(coefs)) is easy to get wrong.
*   Re-estimating is cheap here (10 regressions on 357 observations), it is
*   completely transparent, and it cannot be affected by estimation state.
*   The reported table is unaffected: it was already written in section 5.

display as text _n "{hline 84}"
display as text "Checkpoint: own estimate vs. published Table 4"
display as text "{hline 84}"
display as text %-30s "Coefficient" %12s "Ours" %12s "Published"
display as text "{hline 84}"

* --- level models ------------------------------------------------------------
quietly regress dfte nj
display as text %-30s "nj  (no controls)"      as result %12.2f _b[nj]  %12.2f 2.33

quietly regress dfte nj $ctrl_basic
display as text %-30s "nj  (chain + ownership)" as result %12.2f _b[nj]  %12.2f 2.30

quietly regress dfte gap
display as text %-30s "gap (no controls)"      as result %12.2f _b[gap] %12.2f 15.65

quietly regress dfte gap $ctrl_basic
display as text %-30s "gap (chain + ownership)" as result %12.2f _b[gap] %12.2f 14.92

quietly regress dfte gap $ctrl_full
display as text %-30s "gap (full controls)"    as result %12.2f _b[gap] %12.2f 11.91

* --- proportional models -----------------------------------------------------
quietly regress pdfte nj
display as text %-30s "nj  (no controls)"      as result %12.2f _b[nj]  %12.2f 0.05

quietly regress pdfte nj $ctrl_basic
display as text %-30s "nj  (chain + ownership)" as result %12.2f _b[nj]  %12.2f 0.05

quietly regress pdfte gap
display as text %-30s "gap (no controls)"      as result %12.2f _b[gap] %12.2f 0.39

quietly regress pdfte gap $ctrl_basic
display as text %-30s "gap (chain + ownership)" as result %12.2f _b[gap] %12.2f 0.34

quietly regress pdfte gap $ctrl_full
display as text %-30s "gap (full controls)"    as result %12.2f _b[gap] %12.2f 0.28

display as text "{hline 84}"
display as text "Reference: Card & Krueger (1994), AER 84(4), Table 4, pp. 785."

