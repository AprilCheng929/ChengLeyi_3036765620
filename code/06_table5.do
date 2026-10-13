*==============================================================================
* 06_table5.do
* ECO6067 - Card & Krueger (1994) replication
*
* Purpose: reproduce Table 5, "Specification Tests of Reduced Form Employment
*          Models", and extend it with additional robustness checks.
*
* Table 5 structure (paper, pp. 787):
*   Columns (1)-(2): dependent variable = CHANGE in FTE employment
*                    (1) coefficient on the New Jersey dummy
*                    (2) coefficient on the initial wage GAP
*   Columns (3)-(4): dependent variable = PROPORTIONAL change in FTE employment
*                    (3) coefficient on the New Jersey dummy
*                    (4) coefficient on the initial wage GAP
*
* CRITICAL: the base row reproduces Table 4 columns (2), (4), (7) and (9).
* Every row includes chain dummies and a company-ownership indicator, as stated
* in the Table 5 note: "All models also include chain dummies and an indicator
* for company-owned stores."
*
* Note that row 12 (Pennsylvania stores only) reports only the GAP coefficient:
* the New Jersey dummy is identically zero within Pennsylvania.
*==============================================================================

do "$code/00_settings.do"
use "$analysisdata", clear

*------------------------------------------------------------------------------
* 0. CONTROLS (chain + ownership, present in EVERY specification)
*------------------------------------------------------------------------------
gen byte ch2 = (CHAIN == 2)
gen byte ch3 = (CHAIN == 3)
gen byte ch4 = (CHAIN == 4)
label var ch2 "KFC"
label var ch3 "Roy Rogers"
label var ch4 "Wendy's"
global ctrl_basic "ch2 ch3 ch4 comp"

*------------------------------------------------------------------------------
* 1. ALTERNATIVE EMPLOYMENT MEASURES
*------------------------------------------------------------------------------
* Base: FTE = full-time (incl. managers) + 0.5 * part-time.
* Alternatives follow the Table 5 notes:
*   b/ exclude managers and assistant managers
*   c/ part-time weighted 0.4
*   d/ part-time weighted 0.6

* --- exclude managers --------------------------------------------------------
gen double dfte_nm  = fteemp2 - fteemp1
gen double pdfte_nm = dfte_nm / ((fteemp1 + fteemp2) / 2)
replace pdfte_nm = -1 if closed_any == 1 & !missing(dfte_nm)

* --- part-time weight 0.4 ----------------------------------------------------
gen double dfte_w40  = fte402 - fte401
gen double pdfte_w40 = dfte_w40 / ((fte401 + fte402) / 2)
replace pdfte_w40 = -1 if closed_any == 1 & !missing(dfte_w40)

* --- part-time weight 0.6 ----------------------------------------------------
gen double dfte_w60  = fte602 - fte601
gen double pdfte_w60 = dfte_w60 / ((fte601 + fte602) / 2)
replace pdfte_w60 = -1 if closed_any == 1 & !missing(dfte_w60)

* --- treat temporarily closed stores as permanently closed -------------------
gen double fte2_pc  = fte2
replace fte2_pc = fte2_0 if closed_temp == 1
gen double dfte_pc  = fte2_pc - fte1
gen double pdfte_pc = dfte_pc / ((fte1 + fte2_pc) / 2)
replace pdfte_pc = -1 if closed_any == 1 & !missing(dfte_pc)

* --- sample flag for the "closures treated as permanent" variant -------------
* The four temporarily closed stores re-enter once their Wave-2 employment is
* defined.
gen byte insample_pc = !missing(fte1) & !missing(fte2_pc) & ///
                       !missing(WAGE_ST) & !missing(wage_st2_imp) & !missing(dfte_pc)

*------------------------------------------------------------------------------
* 2. TABLE BUILDER
*------------------------------------------------------------------------------
* The postfile handle is a plain name, NOT a -tempname-. buildone is a separate
* program, so a local macro created out here does not exist inside it: -post
* `pf' ...- would expand to -post ("...") (...)- and Stata would abort with
* "( invalid name r(198)". Using a fixed handle name avoids that entirely.
capture postclose t5out
postfile t5out str52 spec double( ///
    lvl_nj lvl_nj_se lvl_gap lvl_gap_se ///
    prp_nj prp_nj_se prp_gap prp_gap_se N) ///
    using "$tables/table5.dta", replace

* Runs the four models for one specification.
*   mask     : sample restriction expression
*   lv / pv  : dependent variables (level, proportional)
*   njonly   : 1 if the New Jersey dummy is collinear and must be omitted
*
* IMPORTANT: the New Jersey dummy and the wage gap are entered in SEPARATE
* regressions, not jointly. Entering both at once changes the estimates
* substantially (the base row would read 1.06 / 11.92 instead of 2.30 / 14.92)
* and does not reproduce the published table.
* --- 1. Build a row of Table 5 -------------------------------------------------
* Positional arguments are used instead of the -syntax- command. -syntax- has to
* parse named options, and any clash between an option name and a Stata reserved
* word or command name (for example "if") aborts the call with "invalid name
* r(198)". Positional arguments involve no option parsing at all, so this cannot
* happen.
*
*   args: 1 = row label
*         2 = sample-restriction expression ("" for the full sample)
*         3 = level dependent variable   ("" -> dfte)
*         4 = proportional dependent var ("" -> pdfte)
*         5 = 1 to omit the New Jersey dummy (collinear), else 0
* --- 1. Build a row of Table 5 -------------------------------------------------
* Positional arguments are used instead of the -syntax- command. -syntax- must
* parse named options, and a clash between an option name and a Stata reserved
* word or command name (for example "if") aborts the call with "invalid name
* r(198)". Positional arguments involve no option parsing, so that cannot happen.
*
* NOTE: -args- splits its input on blanks and does NOT honour quotes, so a label
* containing spaces would be torn into several arguments. The first argument is
* therefore a short one-word KEY, which is expanded to the full row label below.
*
*   args: 1 = key (one word)
*         2 = sample-restriction expression, quoted (may be "")
*         3 = level dependent variable   ("" -> dfte)
*         4 = proportional dependent var ("" -> pdfte)
*         5 = 1 to omit the New Jersey dummy (collinear), else 0
capture program drop buildone
program define buildone
    args key restr lvlv prpv skip

    * Expand the short key into the full Table 5 row label.
    if      "`key'" == "base"       local lbl "1. Base specification"
    else if "`key'" == "tempclosed" local lbl "2. Temp. closed treated as permanent"
    else if "`key'" == "nomanager"  local lbl "3. Exclude managers from FTE"
    else if "`key'" == "w40"        local lbl "4. Part-time weight 0.40"
    else if "`key'" == "w60"        local lbl "5. Part-time weight 0.60"
    else if "`key'" == "noshore"    local lbl "6. Exclude NJ shore stores"
    else if "`key'" == "nosouth"    local lbl "8. Exclude southern NJ"
    else if "`key'" == "noclose"    local lbl "9. Exclude all closures"
    else if "`key'" == "placebo"    local lbl "10. Pennsylvania only (placebo)"
    else if "`key'" == "njonly"     local lbl "11. New Jersey only"
    else if "`key'" == "company"    local lbl "12. Company-owned stores only"
    else if "`key'" == "franchise"  local lbl "13. Franchise stores only"
    else                            local lbl "`key'"

    if "`lvlv'" == "" local lvlv "dfte"
    if "`prpv'" == "" local prpv "pdfte"
    if "`skip'" == "" local skip 0

    * Build the "if ..." fragment once. Locals stay at program level: a
    * -quietly { }- block would discard them when it closes.
    if "`restr'" == "" local cd ""
    else               local cd "if `restr'"

    * --- level model, New Jersey dummy -----------------------------------------
    if `skip' == 0 {
        quietly regress `lvlv' nj $ctrl_basic `cd'
        local lnj   = _b[nj]
        local lnjse = _se[nj]
    }
    else {
        local lnj   = .
        local lnjse = .
    }

    * --- level model, GAP ------------------------------------------------------
    quietly regress `lvlv' gap $ctrl_basic `cd'
    local lgap   = _b[gap]
    local lgapse = _se[gap]

    * --- proportional model, New Jersey dummy ----------------------------------
    if `skip' == 0 {
        quietly regress `prpv' nj $ctrl_basic `cd'
        local pnj   = _b[nj]
        local pnjse = _se[nj]
    }
    else {
        local pnj   = .
        local pnjse = .
    }

    * --- proportional model, GAP -----------------------------------------------
    quietly regress `prpv' gap $ctrl_basic `cd'
    local pgap   = _b[gap]
    local pgapse = _se[gap]

    quietly count `cd'
    local n = r(N)

    post t5out ("`lbl'") (`lnj') (`lnjse') (`lgap') (`lgapse') ///
        (`pnj') (`pnjse') (`pgap') (`pgapse') (`n')
end

*------------------------------------------------------------------------------
* 3. THE SPECIFICATIONS
*------------------------------------------------------------------------------
* --- 1. base: reproduces Table 4, columns (2), (4), (7), (9) ------------------
buildone base "insample == 1"

* --- 2. temporarily closed stores treated as permanently closed --------------
buildone tempclosed "insample_pc == 1" "dfte_pc" "pdfte_pc"

* --- 3. exclude managers and assistant managers ------------------------------
buildone nomanager "insample == 1" "dfte_nm" "pdfte_nm"

* --- 4. part-time workers weighted 0.4 ---------------------------------------
buildone w40 "insample == 1" "dfte_w40" "pdfte_w40"

* --- 5. part-time workers weighted 0.6 ---------------------------------------
buildone w60 "insample == 1" "dfte_w60" "pdfte_w60"

* --- 6. exclude the 35 New Jersey shore stores -------------------------------
buildone noshore "insample == 1 & shore == 0"

* --- 7. weight by Wave-1 employment (weighted least squares) -----------------
* Extends the paper's row 9 to the level model as well.
*
* NOTE: the four weighted regressions are run with -quietly- individually rather
* than inside a single -quietly { ... }- block. Locals created inside such a
* block go out of scope when the block closes, so the values would arrive empty
* at the -post- statement below.
quietly regress dfte  nj  $ctrl_basic if insample == 1 [aw = fte1]
local lnj    = _b[nj]
local lnjse  = _se[nj]

quietly regress dfte  gap $ctrl_basic if insample == 1 [aw = fte1]
local lgap   = _b[gap]
local lgapse = _se[gap]

quietly regress pdfte nj  $ctrl_basic if insample == 1 [aw = fte1]
local pnj    = _b[nj]
local pnjse  = _se[nj]

quietly regress pdfte gap $ctrl_basic if insample == 1 [aw = fte1]
local pgap   = _b[gap]
local pgapse = _se[gap]

quietly count if insample == 1
local n = r(N)

post t5out ("7. Weight by Wave-1 employment") (`lnj') (`lnjse') ///
    (`lgap') (`lgapse') (`pnj') (`pnjse') (`pgap') (`pgapse') (`n')

* --- 8. exclude stores located in southern New Jersey ------------------------
buildone nosouth "insample == 1 & SOUTHJ != 1"

* --- 9. exclude all stores closed in either wave -----------------------------
buildone noclose "insample == 1 & closed_any == 0"

* --- 10. Pennsylvania stores only (placebo) ----------------------------------
* The New Jersey dummy is identically zero here, so only GAP is reported.
buildone placebo "insample == 1 & pa == 1" "" "" 1

* --- 11. New Jersey stores only, GAP only ------------------------------------
buildone njonly "insample == 1 & nj == 1" "" "" 1

* --- 12. company-owned stores only -------------------------------------------
buildone company "insample == 1 & comp == 1"

* --- 13. franchise stores only -----------------------------------------------
buildone franchise "insample == 1 & comp == 0"

postclose t5out

*------------------------------------------------------------------------------
* 4. DISPLAY
*------------------------------------------------------------------------------
use "$tables/table5.dta", clear

display as text _n "{hline 100}"
display as text "Table 5: Specification tests of reduced form employment models"
display as text "{hline 100}"
display as text %-42s %11s %11s %11s %11s %6s
display as text %-42s "Level NJ" "Level GAP" "Prop NJ" "Prop GAP" "N"
display as text "{hline 100}"

forvalues i = 1/`=_N' {
    display as text %-42s "`=spec[`i']'" ///
        as result %11.2f lvl_nj[`i'] %11.2f lvl_gap[`i'] %11.2f prp_nj[`i'] %11.2f prp_gap[`i'] %6.0f N[`i']
    display as text %-42s "" ///
        as result %11s "(" %9.2f lvl_nj_se[`i'] ")" ///
                   %11s "(" %9.2f lvl_gap_se[`i'] ")" ///
                   %11s "(" %9.2f prp_nj_se[`i'] ")" ///
                   %11s "(" %9.2f prp_gap_se[`i'] ")"
}
display as text "{hline 100}"
display as text "Standard errors in parentheses. All models include chain dummies and a"
display as text "company-owned indicator, following the note to Table 5 in the paper."
display as text "Rows 1-6 correspond to rows 1, 2, 3, 4, 5 and 6 of Card & Krueger (1994)."

export delimited using "$tables/table5.csv", replace
display as text _n "[ok] Table 5 written to $tables/table5.csv"

*------------------------------------------------------------------------------
* 5. CHECKPOINT AGAINST THE PUBLISHED TABLE
*------------------------------------------------------------------------------
* Published values for rows 1-6, columns (1)-(4).
display as text _n "{hline 92}"
display as text "Checkpoint: own estimates vs. published Table 5 (rows 1-6)"
display as text "{hline 92}"
display as text %-38s %10s %10s %10s %10s
display as text %-38s "--- published ---" "" "" "" ""

local pub_lvl_nj  "2.30 2.20 2.34 2.34 2.27 2.58"
local pub_lvl_gap "14.92 14.42 14.69 15.23 14.60 16.88"
local pub_prp_nj  "0.05 0.04 0.05 0.06 0.04 0.06"
local pub_prp_gap "0.34 0.34 0.28 0.30 0.17 0.42"

forvalues i = 1/6 {
    local rn = spec[`i']
    display as text %-38s "`rn'" ///
        as result %10.2f lvl_nj[`i']  %10.2f lvl_gap[`i'] ///
                   %10.2f prp_nj[`i']  %10.2f prp_gap[`i']
    display as text %-38s "  published:" ///
        as result %10.2f `: word `i' of `pub_lvl_nj'' ///
                   %10.2f `: word `i' of `pub_lvl_gap'' ///
                   %10.2f `: word `i' of `pub_prp_nj'' ///
                   %10.2f `: word `i' of `pub_prp_gap''
}
display as text "{hline 92}"
