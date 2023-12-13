*KEEP THIS STATEMENT FIRST TO REDIRECT LENGTHY LOG TO A FILE;
/*proc printto log='/home/maguirejonathan/physician_supply/code/master.log'; run; resetline;*/

* Program:    master.sas                                        ;
* Programmer: Jon Maguire                                       ;
* Purpose:    This program calls each sas code unit in sequence ;
*             to produce analytic data sets and outputs for the ;
*             Physicians Per 1,000 Population analysis.         ;
* Revisions:  Tracked in GitHub                                 ;

***NOTE: Search this file for %let statements to set parameters.;

*Set any options here if needed.;  
ods noproctitle;
options nolabel;

*Wipe any temp datasets from last execution.;
proc datasets library=work kill nolist; run;

*Using SAS On-Demand for Academics (ODA) environment. File locations are set to that environment.;
libname sas  '/home/maguirejonathan/physician_supply/data'; *main project folder;
libname ahrf '/home/maguirejonathan/physician_supply/ahrf'; *AHRF data folder;


*Section 0: AHRF file processing;

*Program 0.1: Load the AHRF raw data using SAS code supplied by AHRF.;
*             Customize AHRFs code using the SAS-ODA file locations  ;
*             and set the &ahrf_out macro variable to the resulting  ;
*             SAS dataset. Direct the out dataset using &ahrf_out.   ;
*             Creates ahrf2022.sas7bdat                              ;
%let ahrf_out=ahrf.ahrf2022;
*%include '/home/maguirejonathan/physician_supply/code/p01_AHRF2021-2022.sas';

*Program 0.2: Create a file with selected county attributes. Review  ;
*             AHRFs file to check for any adjustments that may need  ;
*             to be made in this code. Consider adding new variables.;
*             Creates cnty_geog_hdr.sas7bdat                         ;
%include '/home/maguirejonathan/physician_supply/code/p02_ahrf_cnty_geog_hdr.sas';

*Program 0.3: Create a county level file with selected analytic      ;
*             variables and classification attributes. Review        ;
*             AHRFs file to check for any adjustments that may need  ;
*             to be made in this code. Consider adding new variables.;
*             Creates ahrf_cnty_tbl.sas7bdat                         ;
%include '/home/maguirejonathan/physician_supply/code/p03_ahrf_cnty_tbl.sas';

*Program 0.4: Create a state level file with selected analytic       ;
*             variables and classification attributes. Review        ;
*             AHRFs file to check for any adjustments that may need  ;
*             to be made in this code. Consider adding new variables.;
*             Creates ahrf_state_tbl.sas7bdat                        ;
%include '/home/maguirejonathan/physician_supply/code/p04_ahrf_state_tbl.sas';

*Program 0.5: Create a US level file with selected analytic          ;
*             variables and classification attributes. Review        ;
*             AHRFs file to check for any adjustments that may need  ;
*             to be made in this code. Consider adding new variables.;
*             Creates ahrf_usa_tbl.sas7bdat                          ;
%include '/home/maguirejonathan/physician_supply/code/p05_ahrf_usa_tbl.sas';


*Section 1: Select variables and apply county inclusion-exclusion;

*Program 1.1: Create a county level file keeping selected counties   ;
*             after applying exclusions and the key variables to be  ;
*             used in the analysis                                   ;
*             Creates excluded_counties_smry.sas7bdat                ;
*                     excluded_counties_dtl.sas7bdat                 ;
*                     selected_counties.sas7bdat                     ;
*                     excluded_counties_dtl.txt                      ;
*                     selected_counties.txt                          ;
*                     p11_excl_smry.html                             ;
*                     p11_incl_desc.html                             ;
%include '/home/maguirejonathan/physician_supply/code/p11_selected_counties.sas';


*Section 2: Create groups of counties that are similar to santa barbara;

*Program 2.1: Check for correlations between variables to be used to ;
*             identify counties that are similar to santa barbara.   ;
*             Mannually review correlation matrix and remove highly  ;
*             correlated variables. Use the macro variable &init_vars;
*             to set the initial list of variables and use the macro ;
*             variable &fnl_vars to set the final list after checking;
*             for correlations.                                      ;
*             Creates p21_init_corr.html                             ;
%let init_vars =
  popn 
  cbsa_ind_cd_msa cbsa_status_central rur_urb_cntm_cd_02 urb_infl_cd_2 
  pct_wht_non_hisp pct_ovr64 pct_female 
  pct_cvln_lbr_frc_ovr15 prsnl_income pct_in_pvrty 
  hsptl_beds_per_1k ;
%include '/home/maguirejonathan/physician_supply/code/p21_check_init_corr.sas';

*Program 2.2: After reviewing P21 we find that Cbsa_ind_cd_msa,      ; 
*             cbsa_status_central, rur_urb_cntm_cd_02, and           ;
*             urb_infl_cd_2 are highly correlated. Rur_urb_cntm_cd_02;
*             indicates counties in metro areas of 250k-1M and       ;
*             urb_infl_cd_2 indicates counties in a small metro area ;
*             of less than 1M. These are very similar and            ;
*             rur_urb_cntm_cd_02 is more specific so urb_infl_cd_2   ;
*             was removed. Pct_cvln_lbr_frc_ovr15, prsnl_income, and ;
*             pct_in_pvrty are highly correlated. Income and labor   ;
*             force participation might account for more variability ;
*             in demand for healthcare so pct_in_pvrty was removed.  ;
*             In the resulting correlation matrix no two variables   ;
*             had a correlation coefficient of .6 or more.           ;
*             Creates p22_fnl_corr.html                              ;
%let fnl_vars = 
  popn 
  cbsa_ind_cd_msa cbsa_status_central rur_urb_cntm_cd_02 
  pct_wht_non_hisp pct_ovr64 pct_female 
  pct_cvln_lbr_frc_ovr15 prsnl_income 
  hsptl_beds_per_1k ;
*stop exection of master.sas if fnl_vars is empty; 
%if %symexist(fnl_vars)=0 %then %do;
 %put NOTE: Ending SAS session since manual selection of county demographic variables base on correlations is not complete.;
 endsas;
%end;
%include '/home/maguirejonathan/physician_supply/code/p22_check_fnl_corr.sas';

*Program 2.3: Find possible groupings of counties that have appealing;
*             size in terms of number of counties and are similar to ;
*             santa barbara according to the variables found in P22. ;
*             Mannually review correlation matrix and remove highly  ;
*             correlated variables. Use the macro variable &init_vars;
*             to set the initial list of variables and use the macro ;
*             variable &fnl_vars to set the final list after checking;
*             for correlations.                                      ;
*             Creates county_similarity.sas7bdat                     ;
*                     p23_sb_similar_counties.html                   ;
%include '/home/maguirejonathan/physician_supply/code/p23_create_like_cnty_grps.sas';


*Section 3: Calculate summary statistics and prepare data for Tableau;

*Program 3.1: Calculate means and percentiles and summarize to state ;
*             and national levels for the latest year (2020).        ;
*             Creates physicians_per_1k_smry.sas7bdat                ;
*                     physicians_per_1k_sb.sas7bdat                  ;
*                     p31_y20_stats.html                             ;
%include '/home/maguirejonathan/physician_supply/code/p31_create_y20_stats.sas';

*Program 3.2: Format data for tableau.                               ;
*             Creates physicians_per_1k_tblo.sas7bdat                ;
*                     physicians_per_1k_tblo.txt                     ;
%include '/home/maguirejonathan/physician_supply/code/p32_data_for_tblo.sas';

*KEEP THIS STATEMENT LAST TO RESTORE NORMAL LOGGING;
/*proc printto log=log; run;*/
