*==============================================================================
* 02_table2.do
* ECO6067 - Card & Krueger (1994) replication
*
* Purpose: reproduce Table 2, "Means of Key Variables".
*          Reported for All stores / New Jersey / Pennsylvania, with a
*          t-test for equality of means between NJ and PA.
*
* Note on the t-test: the paper reports a t-statistic for the NJ-PA
* difference. We use -ttest- which assumes equal variances within groups,
* matching the paper's presentation. The unbalanced NJ/PA split (331 vs 79)
* makes the equal-variance assumption the closer analogue here.
*==============================================================================

do "$code/00_settings.do"
use "$analysisdata", clear

* Stores with non-missing data on the relevant variable, per the paper's
* Table 2 note: "Stores with working phone numbers only."
* The public release already reflects this; no further filtering is needed.

*------------------------------------------------------------------------------
* Helper: build one block of Table 2 (Wave 1 or Wave 2)
*------------------------------------------------------------------------------
capture program drop t2block
program define t2block
    * args: varname  label  multiplier(1 or 100)  pctflag
    args v lbl mult pct

    * NOTE: no -quietly { }- wrapper here. Locals created inside a braced block
    * are discarded when the block closes, so the means and standard errors
    * defined below would all be empty by the time they are displayed a few
    * lines further down. Each command suppresses its own output instead.
    tempvar x
    quietly gen double `x' = `v' * `mult'

    * Overall mean and standard error of the mean
    quietly summ `x', meanonly
    local m_all  = r(mean)
    local se_all = r(sd) / sqrt(r(N))

    * New Jersey
    quietly summ `x' if nj == 1, meanonly
    local m_nj  = r(mean)
    local se_nj = r(sd) / sqrt(r(N))

    * Pennsylvania
    quietly summ `x' if pa == 1, meanonly
    local m_pa  = r(mean)
    local se_pa = r(sd) / sqrt(r(N))

    * t-test for equality of means
    capture ttest `x', by(nj)
    if _rc == 0 {
        local tstat = r(t)
    }
    else {
        local tstat = .
    }

    if "`pct'" == "pct" {
        display as text %-38s "`lbl'" ///
            as result %8.1f `m_all' " " %8.1f `m_nj' " " %8.1f `m_pa' " " %8.1f `tstat'
        display as text %-38s "" ///
            as result %8s " " %8.2f `se_all' " " %8.2f `se_nj' " " %8.2f `se_pa'
    }
    else {
        display as text %-38s "`lbl'" ///
            as result %8.2f `m_all' " " %8.2f `m_nj' " " %8.2f `m_pa' " " %8.1f `tstat'
        display as text %-38s "" ///
            as result %8s " " %8.2f `se_all' " " %8.2f `se_nj' " " %8.2f `se_pa'
    }
end

*------------------------------------------------------------------------------
* Display Table 2 in the results window
*------------------------------------------------------------------------------
display as text _n "{hline 79}"
display as text "Table 2: Means of Key Variables"
display as text "{hline 79}"
display as text %-38s "" "     All" "      NJ" "      PA" "  t(NJ-PA)"
display as text "{hline 79}"

display as text _n "1. Distribution of store types (%)"
t2block CHAIN==1 "  a. Burger King"              100 pct
t2block CHAIN==2 "  b. KFC"                      100 pct
t2block CHAIN==3 "  c. Roy Rogers"               100 pct
t2block CHAIN==4 "  d. Wendy's"                  100 pct
t2block CO_OWNED "  e. Company owned"            100 pct

display as text _n "2. Means in $wave1lbl"
t2block fte1   "  a. FTE employment"             1   num
t2block pctft1 "  b. Percent full-time employees" 1 num
t2block WAGE_ST "  c. Starting wage (USD/hour)"  1   num
t2block BONUS  "  g. Recruiting bonus (%)"       100 pct
t2block HRSOPEN "  f. Hours open (weekday)"      1   num
t2block meal1  "  e. Price of full meal (USD)"   1   num

display as text _n "3. Means in $wave2lbl"
t2block fte2   "  a. FTE employment"             1   num
t2block pctft2 "  b. Percent full-time employees" 1 num
t2block WAGE_ST2 "  c. Starting wage (USD/hour)" 1   num
t2block HRSOPEN2 "  f. Hours open (weekday)"     1   num
t2block meal2  "  e. Price of full meal (USD)"   1   num

display as text _n "{hline 79}"
display as text "Note: standard errors of the mean in the row below each mean."
display as text "{hline 79}"

*------------------------------------------------------------------------------
* Export a machine-readable version
*------------------------------------------------------------------------------
preserve
    tempname pf
    postfile `pf' str40 item double all nj pa tstat ///
        using "$tables/table2.dta", replace

    * --- store type distribution -------------------------------------------------
    * NOTE: every block below uses individually -quietly- prefixed commands rather
    * than a single -quietly { ... }- wrapper. Locals defined inside a braced
    * block are destroyed when the block closes, so values created there would
    * arrive empty at the -post- statement that follows.
    foreach c in 1 2 3 4 {
        quietly gen byte ind = (CHAIN == `c')
        quietly summ ind, meanonly
        local a = 100*r(mean)
        quietly summ ind if nj==1, meanonly
        local n = 100*r(mean)
        quietly summ ind if pa==1, meanonly
        local p = 100*r(mean)
        capture ttest ind, by(nj)
        local t = r(t)
        local nm : label chain_lbl `c'
        post `pf' ("`nm' (%)") (`a') (`n') (`p') (`t')
        drop ind
    }
    quietly summ comp, meanonly
    local a = 100*r(mean)
    quietly summ comp if nj==1, meanonly
    local n = 100*r(mean)
    quietly summ comp if pa==1, meanonly
    local p = 100*r(mean)
    capture ttest comp, by(nj)
    local t = r(t)
    post `pf' ("Company owned (%)") (`a') (`n') (`p') (`t')

    * --- continuous outcome blocks ------------------------------------------------
    local rowlab  "FTE employment@Percent full-time@Starting wage@Hours open@Price of full meal"
    local rowvars "fte@ pctft@ WAGE_ST@HRSOPEN@meal"
    * Wave 1
    local i = 1
    foreach spec in "fte1" "pctft1" "WAGE_ST" "HRSOPEN" "meal1" {
        local lbl : word `i' of "`rowlab'"
        local lbl = subinstr("`lbl'", "@", " ", .)
        quietly summ `spec', meanonly
        local a = r(mean)
        quietly summ `spec' if nj==1, meanonly
        local n = r(mean)
        quietly summ `spec' if pa==1, meanonly
        local p = r(mean)
        capture ttest `spec', by(nj)
        local t = r(t)
        post `pf' ("`lbl', Wave 1") (`a') (`n') (`p') (`t')
        local i = `i' + 1
    }
    * Wave 2
    local i = 1
    foreach spec in "fte2" "pctft2" "WAGE_ST2" "HRSOPEN2" "meal2" {
        local lbl : word `i' of "`rowlab'"
        local lbl = subinstr("`lbl'", "@", " ", .)
        quietly summ `spec', meanonly
        local a = r(mean)
        quietly summ `spec' if nj==1, meanonly
        local n = r(mean)
        quietly summ `spec' if pa==1, meanonly
        local p = r(mean)
        capture ttest `spec', by(nj)
        local t = r(t)
        post `pf' ("`lbl', Wave 2") (`a') (`n') (`p') (`t')
        local i = `i' + 1
    }
    postclose `pf'
restore

use "$tables/table2.dta", clear
export delimited using "$tables/table2.csv", replace
display as text _n "[ok] Table 2 written to $tables/table2.csv"
