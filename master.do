*==============================================================================
* master.do
* ECO6067 - Individual Project
* Replication and Extension of Card & Krueger (1994)
*
* ONE-CLICK REPLICATION.
*
* Usage:  Place the raw file data/public.csv in the project, open Stata in the
*         project root, and run this do-file. No manual edits to the data or
*         to any do-file are required. All tables and figures are regenerated.
*
*         Stata:  do master.do
*
* Outputs:
*         output/tables/table2.csv, table3.csv, table4.rtf, table5.csv,
*                        table7.rtf, tableA1.csv
*         output/figures/figure1a_wave1.png, figure1b_wave2.png,
*                        figure1c_nj_compare.png
*         logs/master.log
*==============================================================================

version 17
clear all
set more off
set linesize 200

*------------------------------------------------------------------------------
* Log the whole run
*------------------------------------------------------------------------------
global root : env ECO6067_ROOT
if "$root" == "" {
    global root = subinstr("`c(pwd)'", "\", "/", .)
    if regexm("$root", "/code$") global root = regexr("$root", "/code$", "")
}
capture mkdir "$root/logs"
capture log close _all
log using "$root/logs/master.log", replace text

display as text _n "{hline 79}"
display as text "ECO6067 project pipeline - Card & Krueger (1994)"
display as text "started: `c(current_date)' `c(current_time)'"
display as text "{hline 79}"

*------------------------------------------------------------------------------
* Stage 0 - configuration & raw data check
*------------------------------------------------------------------------------
do "$root/code/00_settings.do"

*------------------------------------------------------------------------------
* Stage 1 - data preparation
*------------------------------------------------------------------------------
do "$root/code/01_clean.do"

*------------------------------------------------------------------------------
* Stage 2 - replication of the published tables and figure
*------------------------------------------------------------------------------
do "$root/code/02_table2.do"     /* Table 2: means of key variables            */
do "$root/code/03_table3.do"     /* Table 3: employment before and after       */
do "$root/code/04_table4.do"     /* Table 4: reduced-form employment models    */
do "$root/code/05_figure1.do"    /* Figure 1: wage distributions               */
do "$root/code/06_table5.do"     /* Table 5: specification tests               */

*------------------------------------------------------------------------------
* Stage 3 - independent extension
*------------------------------------------------------------------------------
do "$root/code/07_extension_prices.do"   /* extension: price pass-through      */

display as text _n "{hline 79}"
display as text "pipeline finished: `c(current_date)' `c(current_time)'"
display as text "see $tables and $figures for outputs"
display as text "{hline 79}"

log close
