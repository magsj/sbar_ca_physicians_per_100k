*macro to transpose selected metrics so that each year's value appears in a column named for that year 
 and the rows are unique per county and metric.; 
%macro ctabler(varname,y22,y21,y20,y19,y18,y17,y16,y15,y14,y13,y12,y11,y10,y05,y00,varlbl);
 proc sql;
 
  /*create a temporary dataset for each selected variable*/
  create table cnty_hlth_tmp as 
  
  select
  
   F00002 as fips_st_cnty, /*Header - FIPS St & Cty Code*/
   F00011 as fips_st,      /*FIPS State Code*/
   F00012 as fips_cnty,    /*FIPS County Code*/
   F04437 as st_cnty_nm,   /*County Name w/State Abbrev*/
   F12424 as st_abbr,      /*State Name Abbreviation*/
   F00010 as cnty_nm,      /*County Name*/
   
   "&varname &varlbl" as metric length=256,
   
   %if &y22=Y %then %do;  &varname.22 as y22 %end; %else %do;  . as y22 %end;
   %if &y21=Y %then %do; ,&varname.21 as y21 %end; %else %do; ,. as y21 %end;
   %if &y20=Y %then %do; ,&varname.20 as y20 %end; %else %do; ,. as y20 %end;
   %if &y19=Y %then %do; ,&varname.19 as y19 %end; %else %do; ,. as y19 %end;
   %if &y18=Y %then %do; ,&varname.18 as y18 %end; %else %do; ,. as y18 %end;
   %if &y17=Y %then %do; ,&varname.17 as y17 %end; %else %do; ,. as y17 %end;
   %if &y16=Y %then %do; ,&varname.16 as y16 %end; %else %do; ,. as y16 %end;
   %if &y15=Y %then %do; ,&varname.15 as y15 %end; %else %do; ,. as y15 %end;
   %if &y14=Y %then %do; ,&varname.14 as y14 %end; %else %do; ,. as y14 %end;
   %if &y13=Y %then %do; ,&varname.13 as y13 %end; %else %do; ,. as y13 %end;
   %if &y12=Y %then %do; ,&varname.12 as y12 %end; %else %do; ,. as y12 %end;
   %if &y11=Y %then %do; ,&varname.11 as y11 %end; %else %do; ,. as y11 %end;
   %if &y10=Y %then %do; ,&varname.10 as y10 %end; %else %do; ,. as y10 %end;
   %if &y05=Y %then %do; ,&varname.05 as y05 %end; %else %do; ,. as y05 %end;
   %if &y00=Y %then %do; ,&varname.00 as y00 %end; %else %do; ,. as y00 %end;
   
  from &ahrf_out
 
  where F12424 not in ('GU','PR','VI') /*keep only 50 states plus DC*/

 ;quit;run;

 *append the dataset for each selected variable to the permanent dataset;
 proc append base=ahrf.ahrf_cnty_tbl data=work.cnty_hlth_tmp force; run; 
 
 *delete the temporary dataset;
 proc delete data=work.cnty_hlth_tmp; run; 

%mend ctabler;

*using proc append in the macro so before executing the macro, delete the permanent file if it already exists; 
proc delete data=ahrf.ahrf_cnty_tbl; run;

*selected AHRF variables, block 1: healthcare resources;
*review the AHRF data dictionary and use the Y/N flags to set the indicator for presence of the variable in each year.;
*        1st 6  2 2 2 1 1 1 1 1 1 1 1 1 1 0 0 variable                X;
*        var_nm 2 1 0 9 8 7 6 5 4 3 2 1 0 5 0 label (max 25)          X;
%ctabler(F11215,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,MDs Total Ptn Care Non-Fd);
%ctabler(F04603,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,MDs PtnCr Ofc Basd Non-Fd);
%ctabler(F11216,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,MDs PtnCr Hsp Basd Non-Fd);
%ctabler(F12499,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,MDs PtnCr Hsp Res Non-Fed);
%ctabler(F04605,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,MDs PtnCr Hsp FT Non-Fed);
%ctabler(F08860,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,MDs PtnCrOfcBsd GP Non-Fd);
%ctabler(F08861,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,MDs PtnCrOfcBsdMSpc Nn-Fd);
%ctabler(F08863,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,MDs PtnCrOfcBsdOSpc Nn-Fd);
%ctabler(F14693,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,DOs Total Ptn Care Non-Fd);
%ctabler(F14694,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,DOs PtnCr Ofc Basd Non-Fd);
%ctabler(F14695,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,DOs PtnCr Hsp Res Non-Fed);
%ctabler(F14696,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,DOs PtnCr Hsp FT Non-Fed);
%ctabler(F14697,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,DOs PtnCr Oth Prof Non-Fd);
%ctabler(F14641,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,Phys Assistants with NPI);
%ctabler(F13219,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,Ambulatory Surgery Centrs);
%ctabler(F08909,N,N,Y,N,N,N,N,N,N,N,N,N,Y,N,N,Hospital Admissions);
%ctabler(F08921,N,N,Y,N,N,N,N,N,N,N,N,N,Y,N,N,Hospital Beds);
%ctabler(F09545,N,N,Y,N,N,N,N,N,N,N,N,N,Y,N,N,Inpatient Days);
%ctabler(F09572,N,N,Y,N,N,N,N,N,N,N,N,N,Y,N,N,ST Hsp Emrgncy Dept Vsts);
%ctabler(F09574,N,N,Y,N,N,N,N,N,N,N,N,N,Y,N,N,ST+LT Hsp EmrgncyDpt Vsts);

*selected AHRF variables, block 2: demographics;
*review the AHRF data dictionary and use the Y/N flags to set the indicator for presence of the variable in each year.;
*        1st 6  2 2 2 1 1 1 1 1 1 1 1 1 1 0 0 variable                X;
*        var_nm 2 1 0 9 8 7 6 5 4 3 2 1 0 5 0 label (max 25)          X;
%ctabler(F11984,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,Y,N,Population Estimate);
%ctabler(F04530,N,N,Y,N,N,N,N,N,N,N,N,N,Y,N,Y,Census Population);
%ctabler(F13906,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Total Male);
%ctabler(F13907,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Total Female);
%ctabler(F13908,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Total White Male);
%ctabler(F13909,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Total White Female);
%ctabler(F13926,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,White Non-Hisp Male);
%ctabler(F13927,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,White Non-Hisp Female);
%ctabler(F13924,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,White Hisp Male);
%ctabler(F13925,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,White Hisp Female);
%ctabler(F13910,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Black Male);
%ctabler(F13911,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Black Female);
%ctabler(F13979,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Black Non-Hisp Male);
%ctabler(F13980,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Black Non-Hisp Female);
%ctabler(F13981,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Black Hisp Male);
%ctabler(F13982,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Black Hisp Female);
%ctabler(F13912,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Native Male);
%ctabler(F13913,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Native Female);
%ctabler(F13914,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Asian Male);
%ctabler(F13915,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Asian Female);
%ctabler(F13916,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Islander Male);
%ctabler(F13917,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Islander Female);
%ctabler(F13918,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Two+ Races Male);
%ctabler(F13919,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Two+ Races Female);
%ctabler(F13920,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Hisp Male);
%ctabler(F13921,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Hisp Female);
%ctabler(F13922,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Non-Hisp Male);
%ctabler(F13923,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Non-Hisp Female);

*selected AHRF variables, block 3: income, housing and insurance;
*review the AHRF data dictionary and use the Y/N flags to set the indicator for presence of the variable in each year.;
*        1st 6  2 2 2 1 1 1 1 1 1 1 1 1 1 0 0 variable                X;
*        var_nm 2 1 0 9 8 7 6 5 4 3 2 1 0 5 0 label (max 25)          X;
%ctabler(F14083,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Pop Est 65+);
%ctabler(F11396,Y,Y,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Pop Est Veterans);
%ctabler(F15550,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,N,Medicare Enrollment Aged);
%ctabler(F15551,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,N,Medicare Enrollment Dsbld);
%ctabler(F13191,N,Y,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Eligible for Medicare);
%ctabler(F09781,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Per Capita Prsnl Income);
%ctabler(F13226,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Median Household Income);
%ctabler(F13223,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Persons in Poverty);
%ctabler(F06792,N,Y,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Civilian Labor Force 16+);
%ctabler(F06793,N,Y,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Number Employed 16+);
%ctabler(F06794,N,Y,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Number Unemployed 16+);
%ctabler(F06795,N,Y,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Unemployment Rate 16+);
%ctabler(F13515,N,N,Y,N,N,N,N,N,N,N,N,N,Y,N,N,Housing Units);
%ctabler(F14091,N,N,N,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Housing Units Estimates);
