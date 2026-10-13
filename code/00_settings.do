*==============================================================================
* 00_settings.do
* ECO6067 - Replication and Extension of Card & Krueger (1994)
* "Minimum Wages and Employment: A Case Study of the Fast-Food Industry
*  in New Jersey and Pennsylvania", AER 84(4), 772-793.
*
* Purpose: central path configuration and directory setup.
*          All other do-files include this file. Edit ONLY this file if your
*          folder layout differs from the template.
*==============================================================================

version 17
clear all
set more off
set varabbrev off

*------------------------------------------------------------------------------
* 1. ROOT PATH
*------------------------------------------------------------------------------
* By default this resolves to the folder containing this do-file's parent
* directory (i.e. the project root), so the pipeline works after cloning
* without editing any absolute path.
*
* If you need to override it, simply set it manually, e.g.:
*   global root "C:/Users/yourname/Documents/econ6067-ck1994-minwage"

global root : env ECO6067_ROOT
if "$root" == "" {
    * Fall back to the location of this do-file: <root>/code/00_settings.do
    global root = subinstr("`c(pwd)'", "\", "/", .)
    * Only strip a trailing /code if we were indeed run from inside code/
    if regexm("$root", "/code$") {
        global root = regexr("$root", "/code$", "")
    }
}

*------------------------------------------------------------------------------
* 2. SUB-DIRECTORIES
*------------------------------------------------------------------------------
global code    "$root/code"
global data    "$root/data"
global out     "$root/output"
global tables  "$root/output/tables"
global figures "$root/output/figures"
global logs    "$root/logs"
global report  "$root/report"

foreach dir in "$data" "$out" "$tables" "$figures" "$logs" "$report" {
    capture mkdir "`dir'"
}

* Input file (raw, never modified by the pipeline)
global rawdata "$data/public.csv"

* Intermediate analysis file produced by 01_clean.do
global analysisdata "$data/analysis.dta"

*------------------------------------------------------------------------------
* 3. GLOBAL PARAMETERS
*------------------------------------------------------------------------------
* Minimum wage rates at the time of the New Jersey increase (1 April 1992)
global mw_new  5.05   /* new NJ minimum wage, USD/hour        */
global mw_old  4.25   /* old NJ / unchanged PA rate, USD/hour */

* Reference period label used in outputs
global wave1lbl "Wave 1 (Feb-Mar 1992)"
global wave2lbl "Wave 2 (Nov-Dec 1992)"

*------------------------------------------------------------------------------
* 4. OUTPUT CONVENTIONS
*------------------------------------------------------------------------------
global tabfmt "rtf"          /* rtf | tex | csv  - table file format   */
global figfmt "png"          /* png | pdf        - figure file format  */

set scheme s2color

*------------------------------------------------------------------------------
* 5. SANITY CHECK
*------------------------------------------------------------------------------
display as text _n "{hline 79}"
display as text "ECO6067 / Card & Krueger (1994) replication pipeline"
display as text "{hline 79}"
display as text "project root : $root"
display as text "raw data     : $rawdata"

capture confirm file "$rawdata"
if _rc {
    display as error _n "[!] Raw data not found at: $rawdata"
    display as error "    Place public.csv in the data/ folder, or set ECO6067_ROOT."
    exit 601
}
display as text "raw data     : found"
display as text "{hline 79}"
