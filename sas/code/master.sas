*KEEP THIS STATEMENT FIRST TO REDIRECT LENGTHY LOG TO A FILE;
/*proc printto log='/home/maguirejonathan/physician_supply/code/master.log'; run;*/

* Program:    master.sas                                        ;
* Programmer: Jon Maguire                                       ;
* Purpose:    This program calls each sas code unit in sequence ;
*             to produce analytic data sets and outputs for the ;
*             Physicians Per 1,000 Population analysis.         ;
* Revisions:  Tracked in GitHub                                 ;

***NOTE: Search this file for %let statements to set parameters.;

*Set any options here if needed.;  
*options;

*Wipe any temp datasets from last execution.;
proc datasets library=work kill nolist; run;

*Using SAS On-Demand for Academics (ODA) environment. File locations are set to that environment.;
libname sas  '/home/maguirejonathan/physician_supply/data'; *main project folder;
libname ahrf '/home/maguirejonathan/physician_supply/ahrf'; *AHRF data folder;


*Section 0: AHRF file processing;

*Program 0.1: Load the AHRF raw data using SAS code supplied by AHRF.;
*             Customize AHRF's code using the SAS-ODA file locations ;
*             and set the &ahrf_out macro variable to the resulting  ;
*             SAS dataset. Direct the out dataset using &ahrf_out.   ;
*             Creates ahrf2022.sas7bdat                              ;
%let ahrf_out=ahrf.ahrf2022;
*%include '/home/maguirejonathan/physician_supply/code/p01_AHRF2021-2022.sas';

*Program 0.2: Create a file with selected county attributes. Review  ;
*             AHRF's file to check for any adjustments that may need ;
*             to be made in this code. Consider adding new variables.;
*             Creates cnty_geog_hdr.sas7bdat                         ;
%include '/home/maguirejonathan/physician_supply/code/p02_ahrf_cnty_geog_hdr.sas';

*Program 0.3: Create a county level file with selected analytic      ;
*             variables and classification attributes. Review        ;
*             AHRF's file to check for any adjustments that may need ;
*             to be made in this code. Consider adding new variables.;
*             Creates ahrf_cnty_tbl.sas7bdat                         ;
%include '/home/maguirejonathan/physician_supply/code/p03_ahrf_cnty_tbl.sas';

*Program 0.4: Create a state level file with selected analytic       ;
*             variables and classification attributes. Review        ;
*             AHRF's file to check for any adjustments that may need ;
*             to be made in this code. Consider adding new variables.;
*             Creates ahrf_state_tbl.sas7bdat                        ;
%include '/home/maguirejonathan/physician_supply/code/p04_ahrf_state_tbl.sas';

*Program 0.5: Create a US level file with selected analytic          ;
*             variables and classification attributes. Review        ;
*             AHRF's file to check for any adjustments that may need ;
*             to be made in this code. Consider adding new variables.;
*             Creates ahrf_usa_tbl.sas7bdat                          ;
%include '/home/maguirejonathan/physician_supply/code/p05_ahrf_usa_tbl.sas';


*Section 1: Select variables and apply county inclusion-exclusion;

*Program 1.1: Create a county level file keeping selected counties   ;
*             after applyinf exclusions and the key variables to be  ;
*             used in the analysis                                   ;
*             Creates excluded_counties_smry.sas7bdat                ;
*                     excluded_counties_dtl.sas7bdat                 ;
*                     selected_counties.sas7bdat                     ;
*                     excluded_counties_dtl.txt                      ;
*                     selected_counties.txt                          ;
*                     p11_excl_smry.html                             ;
*                     p11_incl_desc.html                             ;
%include '/home/maguirejonathan/physician_supply/code/p11_selected_counties.sas';



*KEEP THIS STATEMENT LAST TO RESTORE NORMAL LOGGING;
/*proc printto log=log; run;*/
