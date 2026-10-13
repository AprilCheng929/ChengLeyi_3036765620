*==============================================================================
* 01_clean.do
* ECO6067 - Card & Krueger (1994) replication
*
* Purpose: load the raw store-level survey, construct the analysis variables
*          used in Tables 2-4 and Figure 1, and save an analysis dataset.
*
* Variable definitions follow the paper exactly:
*   FTE   = EMPFT + NMGRS + 0.5 * EMPPT
*           (footnote 8: full-time workers INCLUDING MANAGERS plus one half
*            of the number of part-time workers)
*   GAP   = 0                                  if PA
*         = 0                                  if NJ and W1 >= 5.05
*         = (5.05 - W1) / W1                   otherwise
*           (text p.13: proportional increase in the starting wage required
*            to reach the new minimum rate)
*
* Output: $analysisdata
*==============================================================================

do "$code/00_settings.do"

*==============================================================================
* 1. LOAD RAW DATA
*==============================================================================
import delimited using "$rawdata", clear case(preserve) varnames(1)

* The pipeline never writes back to the raw file; assert the expected shape.
assert _N == 410
assert c(k) >= 46

* Defensive cleanup of any fully empty columns or rows.
* Implemented with base commands so that no user-written package is required.
* (An earlier draft used the user-written -dropmiss-, which is not part of
* base Stata and would fail on a clean installation.)
capture drop _emptycols
quietly ds, has(type numeric)
foreach v of varlist `r(varlist)' {
    quietly count if missing(`v')
    if r(N) == _N {
        quietly drop `v'
    }
}
foreach v of varlist _all {
    if "`: type `v''" == "string" {
        quietly count if `v' == "" | missing(`v')
        if r(N) == _N {
            quietly drop `v'
        }
    }
}

*==============================================================================
* 2. BASIC RECODING
*==============================================================================
* The CSV uses blank cells for missing; import delimited already maps those to
* numeric missing for numeric columns. Verify the key ones are numeric.
foreach v in EMPFT EMPPT NMGRS WAGE_ST PSODA PFRY PENTREE ///
             STATUS2 EMPFT2 EMPPT2 NMGRS2 WAGE_ST2 PSODA2 PFRY2 PENTREE2 {
    capture confirm numeric variable `v'
    if _rc {
        destring `v', replace force
    }
}

* STATE: 1 = New Jersey, 0 = Pennsylvania
label define state_lbl 1 "New Jersey" 0 "Pennsylvania"
label values STATE state_lbl

label define chain_lbl 1 "Burger King" 2 "KFC" 3 "Roy Rogers" 4 "Wendy's"
label values CHAIN chain_lbl

* Company ownership indicator (already 0/1)
label define coown_lbl 0 "Franchise" 1 "Company-owned"
label values CO_OWNED coown_lbl

* Wave-2 response status
label define status2_lbl 0 "Refused" 1 "Answered" 2 "Renovation closure" ///
                        3 "Permanent closure" 4 "Highway closure" 5 "Mall fire closure"
label values STATUS2 status2_lbl

* Convenience flags
gen byte nj     = (STATE == 1)
gen byte pa     = (STATE == 0)
gen byte comp   = (CO_OWNED == 1)

label var nj   "=1 if New Jersey"
label var pa   "=1 if Pennsylvania"
label var comp "=1 if company-owned store"

*==============================================================================
* 3. FTE EMPLOYMENT (paper, footnote 8)
*==============================================================================
* Full-time EQUIVALENT employment = full-time workers (incl. managers)
*                                   + 0.5 * part-time workers
gen double fte1 = EMPFT  + NMGRS  + 0.5 * EMPPT
gen double fte2 = EMPFT2 + NMGRS2 + 0.5 * EMPPT2

label var fte1 "FTE employment, Wave 1"
label var fte2 "FTE employment, Wave 2"

* Alternative FTE definitions used later for specification tests (Table 5):
*   weights on part-time workers of 0.4 and 0.6, and an employees-only measure
foreach w in 40 60 {
    gen double fte`w'1 = EMPFT  + NMGRS  + (`w'/100) * EMPPT
    gen double fte`w'2 = EMPFT2 + NMGRS2 + (`w'/100) * EMPPT2
    label var fte`w'1 "FTE employment (PT weight = 0.`w'), Wave 1"
    label var fte`w'2 "FTE employment (PT weight = 0.`w'), Wave 2"
}
gen double fteemp1 = EMPFT  + 0.5 * EMPPT     /* exclude managers */
gen double fteemp2 = EMPFT2 + 0.5 * EMPPT2
label var fteemp1 "FTE employment excluding managers, Wave 1"
label var fteemp2 "FTE employment excluding managers, Wave 2"

* Percent of full-time among FTE employment (Table 2, row 2b / 3b)
gen double pctft1 = 100 * (EMPFT  + NMGRS)  / fte1 if fte1 > 0 & !missing(fte1)
gen double pctft2 = 100 * (EMPFT2 + NMGRS2) / fte2 if fte2 > 0 & !missing(fte2)
label var pctft1 "Percent full-time employees, Wave 1"
label var pctft2 "Percent full-time employees, Wave 2"

*==============================================================================
* 4. WAGE GAP VARIABLE (paper, text p.13-14)
*==============================================================================
* Proportional increase in the Wave-1 starting wage needed to reach $5.05.
* NOTE: the wage comparisons test for non-missing WAGE_ST explicitly. In Stata a
* missing value counts as arbitrarily large, so without the guard the 17 New
* Jersey stores with an unrecorded Wave-1 wage would be assigned a gap of zero
* ("already above the new minimum") instead of being flagged as missing.
gen double gap = .
replace gap = 0                              if pa == 1
replace gap = 0                              if nj == 1 & !missing(WAGE_ST) & WAGE_ST >= $mw_new
replace gap = ($mw_new - WAGE_ST) / WAGE_ST  if nj == 1 & !missing(WAGE_ST) & WAGE_ST <  $mw_new
label var gap "Initial wage gap: proportional rise in W1 wage to reach $5.05"

* Sites in Pennsylvania have a zero gap by construction (see Table 7 note a/).
assert gap == 0 if pa == 1 & !missing(WAGE_ST)

* Every New Jersey store with a recorded wage must have a gap; missing only when
* the wage itself is missing.
assert !missing(gap) if nj == 1 & !missing(WAGE_ST)
quietly count if nj == 1 & missing(gap)
display as text "[i] NJ stores with missing gap (no Wave-1 wage): " as result r(N)

*==============================================================================
* 5. WAVE-2 CLAIMS HANDLING (paper, Table 3 notes)
*==============================================================================
* STATUS2 == 3 : permanently closed (6 stores) -> Wave-2 employment = 0
* STATUS2 == 2|4|5 : temporarily closed (4 stores) -> missing in the baseline,
*                    set to zero only in the dedicated specification test.
gen byte closed_perm = (STATUS2 == 3)
gen byte closed_temp = inlist(STATUS2, 2, 4, 5)
gen byte closed_any  = closed_perm == 1 | closed_temp == 1

label var closed_perm "=1 if permanently closed before Wave 2"
label var closed_temp "=1 if temporarily closed in Wave 2"
label var closed_any  "=1 if closed in Wave 2 (permanent or temporary)"

* Wave-2 employment with closures set to zero
gen double fte2_0 = fte2
replace fte2_0 = 0 if closed_any == 1 & missing(fte2)
label var fte2_0 "FTE employment Wave 2, closed stores set to 0"

* Note (paper, footnote 16): "Stores that closed are assigned a wage rate in
* Wave 2 equal to the average for their state." This is REQUIRED to reproduce
* the paper's estimation samples: the six permanently closed stores have no
* Wave-2 wage of their own, and imputing at the state mean is what brings the
* Table 4 sample from 365 to the published 357.
bysort STATE: egen double wage2_stateavg = mean(WAGE_ST2)
gen double wage_st2_imp = WAGE_ST2
replace wage_st2_imp = wage2_stateavg if missing(wage_st2_imp) & closed_any == 1
label var wage_st2_imp "Wave-2 starting wage, closed stores imputed at state mean"

* Sample flag matching the paper's Table 4 / Table 6 rule:
* "non-missing employment and starting wage data in both waves", where the
* Wave-2 wage of closed stores is the imputed state mean.
* NOTE: this is defined in section 6, after dfte is constructed, because the
* rule also requires the employment change to be defined.

*==============================================================================
* 6. OUTCOME VARIABLES: CHANGES BETWEEN WAVES
*==============================================================================
* Level change in FTE employment (Table 3 and Table 4 columns 1-2/3-5)
gen double dfte = fte2 - fte1
label var dfte "Change in FTE employment, Wave 2 - Wave 1"

* Level change with temporarily closed stores set to zero (Table 3, row 5)
gen double dfte_0 = fte2_0 - fte1
label var dfte_0 "Change in FTE employment, temporary closures set to 0"

* Proportional change (Table 4, columns 6-10 and footnote 18):
*   change divided by AVERAGE employment in the two waves,
*   set to -1 for closed stores.
gen double ftebar = (fte1 + fte2) / 2
gen double pdfte  = dfte / ftebar
replace pdfte = -1 if closed_any == 1 & !missing(dfte)
label var pdfte "Proportional change in FTE employment"

* Same, with temporary closures set to zero
gen double ftebar_0 = (fte1 + fte2_0) / 2
gen double pdfte_0  = dfte_0 / ftebar_0
replace pdfte_0 = -1 if closed_any == 1 & !missing(dfte_0)
label var pdfte_0 "Proportional change in FTE employment, temp closures at 0"

*------------------------------------------------------------------------------
* Sample flag for the Table 4 / Table 6 regressions
*------------------------------------------------------------------------------
* Paper: "the set of stores with non-missing employment and wage data in both
* waves of the survey", where the Wave-2 wage of closed stores is the imputed
* state mean (footnote 16). Defined here rather than in section 5 because the
* rule also requires the employment CHANGE to be well defined.

gen byte insample = !missing(fte1) & !missing(fte2) & ///
                    !missing(WAGE_ST) & !missing(wage_st2_imp)
replace insample = 0 if missing(dfte)
label var insample "=1 if in the Table 4/6 regression sample"

* Sanity check: the paper's Table 4 sample is exactly 357 stores.
quietly count if insample == 1
display as text "[i] Table 4 / Table 6 regression sample: " as result r(N) ///
    as text " stores (paper reports 357)"

*==============================================================================
* 7. PRICES: FULL MEAL (paper, section on prices and Table 7)
*==============================================================================
* "full meal" = after-tax price of a medium soda, a small order of fries,
*               and a main course.
gen double meal1 = PSODA  + PFRY  + PENTREE
gen double meal2 = PSODA2 + PFRY2 + PENTREE2
label var meal1 "Price of full meal, Wave 1"
label var meal2 "Price of full meal, Wave 2"

gen double dlnmeal = ln(meal2) - ln(meal1)
label var dlnmeal "Change in log price of full meal"

*==============================================================================
* 8. EMPLOYMENT GROUPS WITHIN NEW JERSEY (paper, Table 3 columns 6-10)
*==============================================================================
* NJ stores split by Wave-1 starting wage:
*   low      : exactly $4.25           (N = 101)
*   midrange : $4.26 - $4.99           (N = 140)
*   high     : $5.00 or above          (N = 73)
*
* IMPORTANT: every condition must exclude missing WAGE_ST explicitly. In Stata
* a missing value is treated as arbitrarily large, so a bare "WAGE_ST >= 5.00"
* would sweep the 17 New Jersey stores with unrecorded Wave-1 wages into the
* high-wage group (yielding 90 instead of the published 73).

gen byte wagegrp = .
replace wagegrp = 1 if nj == 1 & !missing(WAGE_ST) & WAGE_ST == 4.25
replace wagegrp = 2 if nj == 1 & !missing(WAGE_ST) & WAGE_ST >  4.25 & WAGE_ST < 5.00
replace wagegrp = 3 if nj == 1 & !missing(WAGE_ST) & WAGE_ST >= 5.00

label define wagegrp_lbl 1 "NJ: W1 wage = $4.25" 2 "NJ: W1 wage $4.26-4.99" ///
                        3 "NJ: W1 wage >= $5.00"
label values wagegrp wagegrp_lbl
label var wagegrp "New Jersey stores by Wave-1 starting wage"

* Verify the group sizes against the paper's footnote to Table 3 (101/140/73).
foreach g in 1 2 3 {
    quietly count if wagegrp == `g'
    display as text "[i] NJ wage group `g': " as result r(N) as text " stores"
}
quietly count if nj == 1 & missing(WAGE_ST)
display as text "[i] NJ stores with missing Wave-1 wage (ungrouped): " as result r(N)

* Four geographic regions of the sample (Table 4 columns 5/10 control set)
gen byte region = .
replace region = 1 if SOUTHJ   == 1
replace region = 2 if CENTRALJ == 1
replace region = 3 if PA1      == 1
replace region = 4 if PA2      == 1
label define region_lbl 1 "Southern NJ" 2 "Central NJ" ///
                       3 "NE Philadelphia suburbs (PA)" 4 "Easton area (PA)"
label values region region_lbl
label var region "Geographic region"

gen byte shore = (SHORE == 1)
label var shore "=1 if store located along the New Jersey shore"

*==============================================================================
* 9. NOTE: DATA LIMITATIONS RELATIVE TO THE PUBLISHED PAPER
*==============================================================================
* The public release supports the reproduction of Tables 2-4 and Figure 1.
* Table 1 (sample design and response rates) is NOT reproducible: it requires
* the original sampling frame, refusal counts, and interviewing mode, none of
* which are contained in public.csv. This is stated in the course materials.

*==============================================================================
* 10. SAVE
*==============================================================================
compress

* Unique row identifier. SHEET is NOT unique in the raw file, so downstream
* operations that need a key (notably -reshape long- in 05_figure1.do) must use
* this instead. Created here once, from the physical row order of the raw file.
* _n is unique by construction on a loaded dataset, so no further check is needed.
gen long storeid = _n
label var storeid "Unique store identifier (row order of raw file)"
order storeid SHEET CHAIN nj pa comp fte1 fte2 dfte pdfte gap WAGE_ST WAGE_ST2 ///
      EMPFT EMPPT NMGRS EMPFT2 EMPPT2 NMGRS2 meal1 meal2 dlnmeal ///
      wagegrp region shore closed_perm closed_temp insample

save "$analysisdata", replace

display as text _n "[ok] analysis dataset written to $analysisdata"
display as text "[ok] observations: " _N
