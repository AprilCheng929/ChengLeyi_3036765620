*==============================================================================
* 03_table3.do
* ECO6067 - Card & Krueger (1994) replication
*
* Purpose: reproduce Table 3, "Average Employment Per Store Before and After
*          the Rise in the New Jersey Minimum Wage".
*
* Structure of the paper's Table 3:
*   Row 1  FTE employment before, all available observations
*   Row 2  FTE employment after,  all available observations
*   Row 3  Change in mean FTE employment, ALL AVAILABLE OBSERVATIONS
*          -> constructed as (row 2 mean) - (row 1 mean), i.e. the two waves
*             need NOT come from the same set of stores.
*   Row 4  Change in mean FTE employment, BALANCED sample of stores
*          -> constructed from dfte = fte2 - fte1, so both waves must be
*             observed for the same store.
*   Row 5  Change in mean FTE employment, temporarily closed stores set to 0
*          -> balanced sample, but Wave-2 employment at temp closures = 0.
*
*   Columns: All | PA | NJ | Diff (NJ-PA) |
*            NJ split by Wave-1 wage: $4.25 | $4.26-4.99 | $5.00+ |
*            Diff low-high | Diff midrange-high
*
* NOTE ON ROWS 3 AND 4 -- this distinction is easy to get wrong:
*   The two rows are numerically very close (2.76 vs 2.75 in the paper) but are
*   NOT the same object. Row 3 differences two separately-estimated means and
*   therefore allows the Wave-1 and Wave-2 samples to differ. Row 4 differences
*   within-store changes and forces a common sample. Reporting the balanced
*   figure in both rows happens to be nearly harmless here (2.75 either way),
*   but the standard errors differ and the row-3 construction is what the paper
*   actually reports.
*==============================================================================

do "$code/00_settings.do"
use "$analysisdata", clear

* Wave-2 employment used in the baseline: temporarily closed stores are treated
* as MISSING (paper, Table 3 note d/). Only row 5 sets them to zero.
gen double fte2_base = fte2
replace fte2_base = . if closed_temp == 1
label var fte2_base "FTE employment Wave 2, temp closures treated as missing"

*------------------------------------------------------------------------------
* Helper: mean and standard error of the mean
*------------------------------------------------------------------------------
capture program drop mse
program define mse, rclass
    syntax varname [if]
    quietly summ `varlist' `if', meanonly
    if r(N) == 0 {
        return scalar m  = .
        return scalar se = .
        return scalar n  = 0
    }
    return scalar m  = r(mean)
    return scalar se = r(sd) / sqrt(r(N))
    return scalar n  = r(N)
end

*------------------------------------------------------------------------------
* Build all nine columns for one variable
*------------------------------------------------------------------------------
* Fills locals: c_all c_pa c_nj c_d, c_lo c_md c_hi c_dl c_dm and *_se
capture program drop t3cols
program define t3cols
    syntax varname
    local v `varlist'

    mse `v'
    local c_all = r(m)
    local s_all = r(se)
    mse `v' if pa == 1
    local c_pa = r(m)
    local s_pa = r(se)
    mse `v' if nj == 1
    local c_nj = r(m)
    local s_nj = r(se)
    local c_d  = `c_nj' - `c_pa'
    local s_d  = sqrt(`s_nj'^2 + `s_pa'^2)

    foreach g in 1 2 3 {
        mse `v' if wagegrp == `g'
        local c_g`g' = r(m)
        local s_g`g' = r(se)
    }
    local c_dl = `c_g1' - `c_g3'
    local s_dl = sqrt(`s_g1'^2 + `s_g3'^2)
    local c_dm = `c_g2' - `c_g3'
    local s_dm = sqrt(`s_g2'^2 + `s_g3'^2)

    c_local c_all `c_all'
    c_local c_pa  `c_pa'
    c_local c_nj  `c_nj'
    c_local c_d   `c_d'
    c_local c_lo  `c_g1'
    c_local c_md  `c_g2'
    c_local c_hi  `c_g3'
    c_local c_dl  `c_dl'
    c_local c_dm  `c_dm'
    c_local s_all `s_all'
    c_local s_pa  `s_pa'
    c_local s_nj  `s_nj'
    c_local s_d   `s_d'
    c_local s_lo  `s_g1'
    c_local s_md  `s_g2'
    c_local s_hi  `s_g3'
    c_local s_dl  `s_dl'
    c_local s_dm  `s_dm'
end

*------------------------------------------------------------------------------
* Collect the five rows
*------------------------------------------------------------------------------
tempname pf
postfile `pf' str26 rowname double( ///
    all_m all_se pa_m pa_se nj_m nj_se d_m d_se ///
    lo_m lo_se md_m md_se hi_m hi_se dl_m dl_se dm_m dm_se) ///
    using "$tables/table3.dta", replace

* --- Row 1: FTE employment before (all available) -----------------------------
t3cols fte1
post `pf' ("FTE before (all avail.)") ///
    (`c_all') (`s_all') (`c_pa') (`s_pa') (`c_nj') (`s_nj') (`c_d') (`s_d') ///
    (`c_lo') (`s_lo') (`c_md') (`s_md') (`c_hi') (`s_hi') (`c_dl') (`s_dl') (`c_dm') (`s_dm')

* --- Row 2: FTE employment after (all available, temp closures missing) ------
t3cols fte2_base
post `pf' ("FTE after (all avail.)") ///
    (`c_all') (`s_all') (`c_pa') (`s_pa') (`c_nj') (`s_nj') (`c_d') (`s_d') ///
    (`c_lo') (`s_lo') (`c_md') (`s_md') (`c_hi') (`s_hi') (`c_dl') (`s_dl') (`c_dm') (`s_dm')

* --- Row 3: change, all available observations --------------------------------
* Difference of the two independently estimated means (row 2 - row 1).
* Standard error of the difference between two independent means; the wave-1
* and wave-2 samples are not forced to coincide.
mse fte1
local b_all = r(m)
local bs_all = r(se)
mse fte2_base
local a_all = r(m)
local as_all = r(se)
mse fte1 if pa == 1
local b_pa = r(m)
local bs_pa = r(se)
mse fte2_base if pa == 1
local a_pa = r(m)
local as_pa = r(se)
mse fte1 if nj == 1
local b_nj = r(m)
local bs_nj = r(se)
mse fte2_base if nj == 1
local a_nj = r(m)
local as_nj = r(se)
foreach g in 1 2 3 {
    mse fte1 if wagegrp == `g'
    local b_g`g' = r(m)
    local bs_g`g' = r(se)
    mse fte2_base if wagegrp == `g'
    local a_g`g' = r(m)
    local as_g`g' = r(se)
}

* Differences and their standard errors (difference of independent means)
local r3_all = `a_all' - `b_all'
local r3s_all = sqrt(`as_all'^2 + `bs_all'^2)
local r3_pa  = `a_pa' - `b_pa'
local r3s_pa = sqrt(`as_pa'^2 + `bs_pa'^2)
local r3_nj  = `a_nj' - `b_nj'
local r3s_nj = sqrt(`as_nj'^2 + `bs_nj'^2)
* NJ - PA contrast: difference of the NJ change and the PA change
local r3_d  = `r3_nj' - `r3_pa'
local r3s_d = sqrt(`r3s_nj'^2 + `r3s_pa'^2)
foreach g in 1 2 3 {
    local r3_g`g'  = `a_g`g'' - `b_g`g''
    local r3s_g`g' = sqrt(`as_g`g''^2 + `bs_g`g''^2)
}
local r3_dl  = `r3_g1' - `r3_g3'
local r3s_dl = sqrt(`r3s_g1'^2 + `r3s_g3'^2)
local r3_dm  = `r3_g2' - `r3_g3'
local r3s_dm = sqrt(`r3s_g2'^2 + `r3s_g3'^2)

post `pf' ("Change (all avail.)") ///
    (`r3_all') (`r3s_all') (`r3_pa') (`r3s_pa') (`r3_nj') (`r3s_nj') (`r3_d') (`r3s_d') ///
    (`r3_g1') (`r3s_g1') (`r3_g2') (`r3s_g2') (`r3_g3') (`r3s_g3') (`r3_dl') (`r3s_dl') (`r3_dm') (`r3s_dm')

* --- Row 4: change, balanced sample of stores ---------------------------------
t3cols dfte
post `pf' ("Change (balanced sample)") ///
    (`c_all') (`s_all') (`c_pa') (`s_pa') (`c_nj') (`s_nj') (`c_d') (`s_d') ///
    (`c_lo') (`s_lo') (`c_md') (`s_md') (`c_hi') (`s_hi') (`c_dl') (`s_dl') (`c_dm') (`s_dm')

* --- Row 5: change, temporarily closed stores set to zero ---------------------
t3cols dfte_0
post `pf' ("Change (temp. closed = 0)") ///
    (`c_all') (`s_all') (`c_pa') (`s_pa') (`c_nj') (`s_nj') (`c_d') (`s_d') ///
    (`c_lo') (`s_lo') (`c_md') (`s_md') (`c_hi') (`s_hi') (`c_dl') (`s_dl') (`c_dm') (`s_dm')

postclose `pf'

*------------------------------------------------------------------------------
* Display
*------------------------------------------------------------------------------
use "$tables/table3.dta", clear

display as text _n "{hline 108}"
display as text "Table 3: Average employment per store before and after the NJ minimum wage"
display as text "{hline 108}"
display as text %-26s "Row" %10s "All" %10s "PA" %10s "NJ" %10s "NJ-PA" ///
                    %10s "w=4.25" %10s "4.26-4.99" %10s "5.00+" %10s "lo-hi" %10s "mid-hi"
display as text "{hline 108}"

forvalues i = 1/`=_N' {
    display as text %-26s "`=rowname[`i']'" ///
        as result %10.2f all_m[`i'] %10.2f pa_m[`i'] %10.2f nj_m[`i'] %10.2f d_m[`i'] ///
                   %10.2f lo_m[`i'] %10.2f md_m[`i'] %10.2f hi_m[`i'] %10.2f dl_m[`i'] %10.2f dm_m[`i']
    display as text %-26s "" ///
        as result %10s "(" as result %8.2f all_se[`i'] as result ")" ///
        as result "(" %8.2f pa_se[`i'] ")" "(" %8.2f nj_se[`i'] ")" "(" %8.2f d_se[`i'] ")" ///
        as result "(" %8.2f lo_se[`i'] ")" "(" %8.2f md_se[`i'] ")" "(" %8.2f hi_se[`i'] ")" ///
        as result "(" %8.2f dl_se[`i'] ")" "(" %8.2f dm_se[`i'] ")"
}
display as text "{hline 108}"
display as text "Standard errors in parentheses. FTE counts each part-time worker as 1/2."
display as text "Column 'NJ-PA' is the difference-in-differences of the changes (row 3-5)."

export delimited using "$tables/table3.csv", replace
display as text _n "[ok] Table 3 written to $tables/table3.csv"
