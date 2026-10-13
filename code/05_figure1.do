*==============================================================================
* 05_figure1.do
* ECO6067 - Card & Krueger (1994) replication
*
* Purpose: reproduce Figure 1 - the distributions of STARTING WAGES in New
*          Jersey and Pennsylvania across the two survey waves.
*
* IMPORTANT: Figure 1 plots starting wages, NOT employment. (Paper, section
* III: "we have plotted the overall distributions of starting wages in the two
* states from the two waves of the survey.")
*
* The purpose of the figure is to show that:
*   - in Wave 1 the two states' wage distributions were very similar;
*   - after the increase, virtually all New Jersey stores previously paying
*     below $5.05 reported a starting wage exactly equal to the new rate;
*   - there was no spillover to higher-wage New Jersey stores.
*
* Output: $figures/figure1a_wave1.png, figure1b_wave2.png,
*         figure1c_nj_compare.png
*==============================================================================

do "$code/00_settings.do"
use "$analysisdata", clear

*------------------------------------------------------------------------------
* 1. BUILD A LONG PANEL OF WAGE OBSERVATIONS
*------------------------------------------------------------------------------
* One observation per store-wave. Stores with no reported wage are dropped.

* storeid is a unique row key created in 01_clean.do. SHEET is NOT unique in the
* raw file, so using it as the reshape index fails with r(9).
keep storeid SHEET STATE nj pa WAGE_ST WAGE_ST2 CHAIN

* reshape long expects a stub plus a numeric suffix (stub1, stub2, ...).
* The raw file names the two waves WAGE_ST and WAGE_ST2, i.e. wave 1 carries NO
* suffix, so "reshape long WAGE_ST" would look for WAGE_ST1 and fail with r(110).
rename WAGE_ST  wst1
rename WAGE_ST2 wst2
reshape long wst, i(storeid) j(wave)
rename wst wage
drop if missing(wage)

label define wave_lbl 1 "Wave 1 (Feb-Mar 1992)" 2 "Wave 2 (Nov-Dec 1992)"
label values wave wave_lbl

* Discrete 25-cent bins, so the pile-up at exactly $5.05 is visible.
gen double bin = floor(wage / 0.25) * 0.25

*------------------------------------------------------------------------------
* 2. FIGURE 1a - both states, Wave 1
*------------------------------------------------------------------------------
* hist() inside twoway accepts width() and start(), NOT binwidth()/start().
* The percentile scale is requested with percent.
*
* NOTE: every graph is given an explicit -name()- and NO -nodraw- option. The
* graph is drawn into a Graph window (and stays in memory under that name), so
* -graph export- always has a rendered current graph to write. Do NOT add
* -nodraw- here: a nodraw graph is never rendered and graph export fails with
* r(693), "could not find Graph window", in both GUI and batch mode.
graph twoway ///
    (histogram wage if nj == 1 & wave == 1, ///
        width(0.25) start(3.75) percent ///
        fcolor(navy%40) lcolor(navy) lwidth(thin)) ///
    (histogram wage if pa == 1 & wave == 1, ///
        width(0.25) start(3.75) percent ///
        fcolor(maroon%40) lcolor(maroon) lwidth(thin)), ///
    legend(order(1 "New Jersey" 2 "Pennsylvania") rows(1) size(small)) ///
    title("Figure 1a. Distribution of starting wages, wave 1") ///
    subtitle("New Jersey and Pennsylvania, February-March 1992") ///
    xtitle("Starting wage (USD per hour)") ytitle("Percent of stores") ///
    xlabel(4(0.25)6.5, angle(45) labsize(small)) ///
    note("Minimum wage: $4.25 in both states in wave 1.") ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(fig1a, replace)
graph export "$figures/figure1a_wave1.$figfmt", replace width(2000) name(fig1a)

*------------------------------------------------------------------------------
* 3. FIGURE 1b - both states, Wave 2
*------------------------------------------------------------------------------
graph twoway ///
    (histogram wage if nj == 1 & wave == 2, ///
        width(0.25) start(3.75) percent ///
        fcolor(navy%40) lcolor(navy) lwidth(thin)) ///
    (histogram wage if pa == 1 & wave == 2, ///
        width(0.25) start(3.75) percent ///
        fcolor(maroon%40) lcolor(maroon) lwidth(thin)), ///
    legend(order(1 "New Jersey" 2 "Pennsylvania") rows(1) size(small)) ///
    title("Figure 1b. Distribution of starting wages, wave 2") ///
    subtitle("New Jersey and Pennsylvania, November-December 1992") ///
    xtitle("Starting wage (USD per hour)") ytitle("Percent of stores") ///
    xlabel(4(0.25)6.5, angle(45) labsize(small)) ///
    note("NJ minimum wage rose to $5.05 on 1 April 1992; PA unchanged at $4.25.") ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(fig1b, replace)
graph export "$figures/figure1b_wave2.$figfmt", replace width(2000) name(fig1b)

*------------------------------------------------------------------------------
* 4. FIGURE 1c - New Jersey before and after
*------------------------------------------------------------------------------
* Overlaying the two waves makes the shift of mass to exactly $5.05 visible.
graph twoway ///
    (histogram wage if nj == 1 & wave == 1, ///
        width(0.25) start(3.75) percent ///
        fcolor(navy%50) lcolor(navy) lwidth(thin)) ///
    (histogram wage if nj == 1 & wave == 2, ///
        width(0.25) start(3.75) percent ///
        fcolor(maroon%50) lcolor(maroon) lwidth(thin)), ///
    legend(order(1 "Wave 1 (Feb-Mar 1992)" 2 "Wave 2 (Nov-Dec 1992)") ///
           rows(1) size(small)) ///
    title("Figure 1c. New Jersey starting wages before and after the increase") ///
    xtitle("Starting wage (USD per hour)") ytitle("Percent of stores") ///
    xlabel(4(0.25)6.5, angle(45) labsize(small)) ///
    note("The mass of stores moves to exactly the new minimum wage of $5.05.") ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(fig1c, replace)
graph export "$figures/figure1c_nj_compare.$figfmt", replace width(2000) name(fig1c)

*------------------------------------------------------------------------------
* 5. NUMERICAL SUMMARY
*------------------------------------------------------------------------------
* Computed on the LONG panel built above, which is still in memory here.
* (An earlier draft ran this section after a -restore-, where the long-format
*  variables wage and wave no longer exist.)
display as text _n "{hline 82}"
display as text "Figure 1 - supporting statistics: starting wage distributions"
display as text "{hline 82}"
display as text "%-26s %10s %10s %10s %10s %10s %10s" "" "mean" "sd" "p25" "p50" "p75" "N"
display as text "{hline 82}"

foreach w in 1 2 {
    foreach st in 1 0 {
        * Locals are defined directly in the loop body: a -quietly { }- block
        * would destroy them on exit and every number would print as missing.
        quietly summarize wage if wave == `w' & STATE == `st', detail
        local mu  = r(mean)
        local sd  = r(sd)
        local p25 = r(p25)
        local p50 = r(p50)
        local p75 = r(p75)
        local n   = r(N)
        local sl = cond(`st' == 1, "New Jersey", "Pennsylvania")
        display as text %-26s "`sl', wave `w'" ///
            as result %10.2f `mu' %10.2f `sd' %10.2f `p25' ///
                      %10.2f `p50' %10.2f `p75' %10.0f `n'
    }
}
display as text "{hline 82}"

* Share of New Jersey stores that were paying BELOW the new minimum in Wave 1
* and had moved to exactly $5.05 by Wave 2. This is the comparison the paper
* reports (85.2 percent).
*
* NOTE: the comparison uses a 0.001 tolerance, not an exact equality test.
* Prices are read from a CSV, so $5.05 arrives as the nearest double to 5.05,
* which need not be bit-identical to the literal 5.05 stored in $mw_new. A test
* such as abs(wage - $mw_new) < 1e-8 silently matches nothing and reports 0.0%.
* Wages are recorded in whole cents, so 0.001 is far smaller than any gap
* between two distinct wage rates.
quietly count if nj == 1 & wave == 2
local n_nj2 = r(N)

* Wave-2 NJ stores at exactly the new minimum
quietly count if nj == 1 & wave == 2 & abs(wage - $mw_new) < 0.001
local n_at505 = r(N)

* NJ stores that started below the new minimum in wave 1
quietly count if nj == 1 & wave == 1 & wage < $mw_new
local n_below1 = r(N)

display as text _n "=== NJ wage adjustment (paper, section III) ==="
display as text "  NJ stores with a Wave-2 wage                  : " ///
    as result %4.0f `n_nj2'
display as text "  of which paying exactly $5.05                 : " ///
    as result %4.0f `n_at505' as text "  (" ///
    as result %4.1f 100*`n_at505'/`n_nj2' as text "%)"
display as text "  NJ stores below $5.05 in Wave 1               : " ///
    as result %4.0f `n_below1'
display as text "  ... that moved to exactly $5.05 by Wave 2     : " ///
    as result %4.1f 100*`n_at505'/`n_below1' as text "%" ///
    as text "  (paper reports 85.2%)"

* Stores still below the new minimum in Wave 2.
quietly count if nj == 1 & wave == 2 & wage < $mw_new
display as text "NJ stores still paying below $5.05 in wave 2: " ///
    as result %4.0f r(N) as text "  (paper: essentially none)"

display as text "{hline 82}"
display as text _n "[ok] Figure 1 exported to $figures"
