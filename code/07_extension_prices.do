*==============================================================================
* 07_extension_prices.do
* ECO6067 - INDEPENDENT EXTENSION
*
* Research question:
*   Card and Krueger (1994) find that employment did not fall in New Jersey
*   after the 1992 minimum wage increase, and that after-tax meal prices rose
*   about 3.2 percent faster in New Jersey than in Pennsylvania. They then note
*   that this NJ-PA price effect is consistent with full pass-through of the
*   cost increase, BUT that within New Jersey prices rose at approximately the
*   same rate at stores with very different initial wages - a pattern they
*   describe as inconsistent with a simple pass-through story.
*
*   This extension asks: WHO BEARS THE COST OF A MINIMUM WAGE INCREASE?
*   Specifically, is the observed price increase concentrated among the stores
*   that were most intensively treated?
*
* Why this is a genuine extension rather than a repetition:
*   - The paper aggregates the three meal components into a single "full meal"
*     index. We separate them, because pass-through need not be uniform across
*     products with different cost structures and demand elasticities.
*   - The paper reports the NJ-PA contrast and the GAP coefficient but never
*     asks whether the two are mutually consistent. We build a specification
*     that nests both and tests whether the GAP channel survives.
*   - The paper does not exploit the New Jersey sales tax cut that coincided
*     with the minimum wage increase. We use it to separate pre-tax price
*     changes (a real pass-through response) from tax-inclusive changes.
*
* Output: $tables/table7.rtf, $tables/table8_extension.csv, and a figure.
*==============================================================================

do "$code/00_settings.do"
use "$analysisdata", clear

*------------------------------------------------------------------------------
* 1. SAMPLE
*------------------------------------------------------------------------------
* Paper Table 7 note: "The sample contains 315 stores with valid data on
* prices, wages, and employment for Waves 1 and 2."
* We apply the same rule, with the closed-store Wave-2 wage imputed at the
* state mean (footnote 16), and report the resulting N.

gen byte priceok = !missing(PSODA) & !missing(PSODA2) & ///
                   !missing(PFRY)  & !missing(PFRY2)  & ///
                   !missing(PENTREE) & !missing(PENTREE2)

keep if priceok == 1
keep if !missing(fte1) & !missing(fte2) & !missing(WAGE_ST) & !missing(wage_st2_imp)
keep if !missing(dlnmeal)

display as text _n "[i] Extension estimation sample: " _N " stores " ///
    "(paper reports 315 for the analogous Table 7 sample)."

*------------------------------------------------------------------------------
* 2. THE NEW JERSEY SALES TAX CHANGE
*------------------------------------------------------------------------------
* New Jersey reduced its sales tax rate by 1 percentage point effective
* 1 July 1992, i.e. between the two survey waves. Pennsylvania's rate was
* unchanged. All prices in the survey are recorded INCLUSIVE of tax.
*
* If t1 and t2 are the tax-inclusive rates in the two waves, then
*   ln(p2) - ln(p1) = [ln(p2/(1+t2)) - ln(p1/(1+t1))] + ln((1+t2)/(1+t1))
* so the pre-tax price change is the observed change minus the tax component.
*
* We take NJ: t1 = 0.07, t2 = 0.06;  PA: t1 = t2 = 0.06 (Philadelphia 6%,
* no change). The precise PA rate affects only the level of the PA series,
* which is differenced away; what identifies the adjustment is the CHANGE in
* the NJ rate. Alternative PA rates leave the NJ-PA contrast unchanged.

gen double tax1 = cond(nj == 1, 0.07, 0.06)
gen double tax2 = cond(nj == 1, 0.06, 0.06)

* Pre-tax full meal price
gen double meal1_pre = meal1 / (1 + tax1)
gen double meal2_pre = meal2 / (1 + tax2)
gen double dlnmeal_pre = ln(meal2_pre) - ln(meal1_pre)
label var dlnmeal_pre "Change in log PRE-TAX price of full meal"

* Component prices, tax-inclusive and pre-tax
foreach v in PSODA PFRY PENTREE {
    local v2 = "`v'2"
    gen double dln_`v'     = ln(`v2') - ln(`v')
    gen double dln_`v'_pre = ln(`v2'/(1+tax2)) - ln(`v'/(1+tax1))
    label var dln_`v' "Change in log price: `v'"
}

*------------------------------------------------------------------------------
* 3. REGRESSION FRAMEWORK
*------------------------------------------------------------------------------
gen byte ch2 = (CHAIN == 2)
gen byte ch3 = (CHAIN == 3)
gen byte ch4 = (CHAIN == 4)
global ctrl_basic "ch2 ch3 ch4 comp"

* --- 3.1 Replicate the paper's Table 7 (columns 1-3) --------------------------
eststo clear
eststo t7c1: regress dlnmeal nj
eststo t7c2: regress dlnmeal nj $ctrl_basic
eststo t7c3: regress dlnmeal gap
eststo t7c4: regress dlnmeal gap $ctrl_basic

* --- 3.2 EXTENSION A: does the GAP channel survive the NJ contrast? ----------
* If the minimum wage is the mechanism, the NJ dummy should lose explanatory
* power once the treatment intensity (GAP) is controlled for.
eststo extA: regress dlnmeal nj gap $ctrl_basic

* --- 3.3 EXTENSION B: pre-tax prices ----------------------------------------
* Strips out the mechanical effect of the New Jersey tax cut.
eststo extB1: regress dlnmeal_pre nj $ctrl_basic
eststo extB2: regress dlnmeal_pre gap $ctrl_basic
eststo extB3: regress dlnmeal_pre nj gap $ctrl_basic

* --- 3.4 EXTENSION C: by product --------------------------------------------
eststo extC1: regress dln_PSODA_pre  nj gap $ctrl_basic
eststo extC2: regress dln_PFRY_pre   nj gap $ctrl_basic
eststo extC3: regress dln_PENTREE_pre nj gap $ctrl_basic

*------------------------------------------------------------------------------
* 4. IMPLIED PASS-THROUGH RATE
*------------------------------------------------------------------------------
* The cost increase caused by the minimum wage, as a share of the meal price,
* is approximately (wage bill share) * GAP. With a labour share of roughly 0.30
* in fast food and a mean GAP of 0.11 among New Jersey stores, the predicted
* price increase is about 3.3 percent - coincidentally close to the estimated
* NJ coefficient, which is exactly the "consistent with full pass-through"
* observation the paper makes.

quietly summ gap if nj == 1
local mgap = r(mean)
display as text _n "{hline 78}"
display as text "Implied pass-through arithmetic"
display as text "{hline 78}"
display as text "Mean GAP among New Jersey stores          : " as result %6.4f `mgap'
display as text "Assumed labour share of revenue           : " as result %6.2f 0.30
display as text "Predicted proportional price rise          : " as result %6.4f 0.30*`mgap'

* Read the two headline coefficients by re-estimating, so that the numbers
* printed here cannot be affected by whatever estimate happens to be active.
quietly regress dlnmeal nj $ctrl_basic
display as text "Estimated NJ coefficient on post-tax price : " as result %6.4f _b[nj]

quietly regress dlnmeal_pre nj $ctrl_basic
display as text "Estimated NJ coefficient on PRE-tax price  : " as result %6.4f _b[nj]

display as text "{hline 78}"
display as text "Reference: Card & Krueger (1994), pp. 780-782."

*------------------------------------------------------------------------------
* 5. EXPORT
*------------------------------------------------------------------------------
esttab t7c1 t7c2 t7c3 t7c4 extA extB1 extB2 extB3 using "$tables/table7.$tabfmt", replace ///
    cells(b(star fmt(4)) se(par fmt(4))) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-squared")) ///
    mtitles("(1)" "(2)" "(3)" "(4)" "(5)" "(6)" "(7)" "(8)") ///
    coeflabels(nj "New Jersey dummy" gap "Initial wage gap" ///
               ch2 "KFC" ch3 "Roy Rogers" ch4 "Wendy's" comp "Company-owned") ///
    title("Table 7. Price effects: replication and extension") ///
    mgroups("Replication (change in log post-tax full meal price)" ///
            "Extension", pattern(1 0 0 0 1 1 0 0)) ///
    addnotes("Columns (1)-(4) replicate Card & Krueger (1994), Table 7." ///
             "Column (5) nests the NJ dummy and the wage gap jointly." ///
             "Columns (6)-(8) use the PRE-TAX price, removing the effect of the" ///
             "New Jersey sales tax cut of 1 percentage point between the waves.") ///
    label

* Product-level extension table
esttab extC1 extC2 extC3 using "$tables/table8_extension.csv", replace ///
    cells(b(star fmt(4)) se(par fmt(4))) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-squared")) ///
    mtitles("Medium soda" "Small fries" "Entree") ///
    coeflabels(nj "New Jersey dummy" gap "Initial wage gap" ///
               ch2 "KFC" ch3 "Roy Rogers" ch4 "Wendy's" comp "Company-owned") ///
    title("Extension: pre-tax price response by product") ///
    label

display as text _n "[ok] Extension tables written to $tables"

*------------------------------------------------------------------------------
* 6. FIGURE: pass-through by treatment intensity
*------------------------------------------------------------------------------
preserve
    * Bin New Jersey stores by initial wage gap and plot mean price change.
    * Pennsylvania is shown separately as the comparison group.
    gen double gapbin = .
    replace gapbin = 0            if pa == 1
    replace gapbin = 1            if nj == 1 & !missing(gap) & gap == 0
    replace gapbin = 2            if nj == 1 & !missing(gap) & gap > 0     & gap <= 0.10
    replace gapbin = 3            if nj == 1 & !missing(gap) & gap > 0.10  & gap <= 0.20
    replace gapbin = 4            if nj == 1 & !missing(gap) & gap > 0.20
    label define gapbin_lbl 0 "PA" 1 "NJ, gap=0" 2 "NJ, 0-10%" ///
                           3 "NJ, 10-20%" 4 "NJ, >20%"
    label values gapbin gapbin_lbl

    collapse (mean) dlnmeal dlnmeal_pre (semean) se_meal=dlnmeal (count) n=dlnmeal, by(gapbin)
    drop if missing(gapbin)

    * name() keeps the graph in memory so -graph export- works even in Stata's
    * windowless batch mode (/e), where there is no Graph window (r(693)).
    graph twoway ///
        (bar dlnmeal gapbin, barwidth(0.55) fcolor(navy%55) lcolor(navy)) ///
        (scatter dlnmeal_pre gapbin, msymbol(D) mcolor(maroon) msize(medium)), ///
        xlabel(0(1)4, valuelabel labsize(small) angle(20)) ///
        ytitle("Mean change in log meal price") ///
        title("Extension: price response by treatment intensity") ///
        subtitle("New Jersey stores grouped by initial wage gap; Pennsylvania as comparison") ///
        note("Navy bars: post-tax price change. Maroon markers: pre-tax price change.") ///
        graphregion(color(white)) plotregion(color(white)) ///
        name(extension, replace)
    graph export "$figures/extension_passthrough.$figfmt", replace width(2000) name(extension)
restore

display as text _n "[ok] Extension complete."
