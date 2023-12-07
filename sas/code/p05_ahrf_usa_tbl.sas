*macro to transpose selected metrics so that each year's value appears in a column named for that year 
 and the metrics are aggregated up to national level so just one rows per metric.; 
%macro ntabler(varname,y22,y21,y20,y19,y18,y17,y16,y15,y14,y13,y12,y11,y10,y05,y00,varlbl);
 proc sql;
 
  /*create a temporary dataset for each selected variable*/
  create table us_hlth_tmp as
  
  select distinct
  
   '00000' as fips_st_cnty,    /*Header - FIPS St & Cty Code, set to 0 for nation*/
   '00' as fips_st,            /*FIPS State Code, set to 0 for nation*/
   '000' as fips_cnty,         /*FIPS County Code, set to 0 for nation*/
   'US' as st_abbr,            /*State Name Abbreviation, set to US for nation*/
   'USA 50 +DC' as st_cnty_nm, /*State Name, set to national label*/
   
   "&varname &varlbl" as metric length=256,
   
   %if &y22=Y %then %do;  sum(&varname.22) as y22 %end; %else %do;  . as y22 %end;
   %if &y21=Y %then %do; ,sum(&varname.21) as y21 %end; %else %do; ,. as y21 %end;
   %if &y20=Y %then %do; ,sum(&varname.20) as y20 %end; %else %do; ,. as y20 %end;
   %if &y19=Y %then %do; ,sum(&varname.19) as y19 %end; %else %do; ,. as y19 %end;
   %if &y18=Y %then %do; ,sum(&varname.18) as y18 %end; %else %do; ,. as y18 %end;
   %if &y17=Y %then %do; ,sum(&varname.17) as y17 %end; %else %do; ,. as y17 %end;
   %if &y16=Y %then %do; ,sum(&varname.16) as y16 %end; %else %do; ,. as y16 %end;
   %if &y15=Y %then %do; ,sum(&varname.15) as y15 %end; %else %do; ,. as y15 %end;
   %if &y14=Y %then %do; ,sum(&varname.14) as y14 %end; %else %do; ,. as y14 %end;
   %if &y13=Y %then %do; ,sum(&varname.13) as y13 %end; %else %do; ,. as y13 %end;
   %if &y12=Y %then %do; ,sum(&varname.12) as y12 %end; %else %do; ,. as y12 %end;
   %if &y11=Y %then %do; ,sum(&varname.11) as y11 %end; %else %do; ,. as y11 %end;
   %if &y10=Y %then %do; ,sum(&varname.10) as y10 %end; %else %do; ,. as y10 %end;
   %if &y05=Y %then %do; ,sum(&varname.05) as y05 %end; %else %do; ,. as y05 %end;
   %if &y00=Y %then %do; ,sum(&varname.00) as y00 %end; %else %do; ,. as y00 %end;
   
  from &ahrf_out
  
  where F12424 not in ('GU','PR','VI') /*keep only 50 states plus DC*/
 
 ;quit;run;

 *append the dataset for each selected variable to the permanent dataset;
 proc append base=ahrf.ahrf_usa_tbl data=work.us_hlth_tmp force; run;

 *delete the temporary dataset;
 proc delete data=work.us_hlth_tmp; run;

%mend ntabler;

*using proc append in the macro so before executing the macro, delete the permanent file if it already exists; 
proc delete data=ahrf.ahrf_usa_tbl; run;

*selected AHRF variables, block 1: healthcare resources;
*review the AHRF data dictionary and use the Y/N flags to set the indicator for presence of the variable in each year.;
*        1st 6  2 2 2 1 1 1 1 1 1 1 1 1 1 0 0 variable                X;
*        var_nm 2 1 0 9 8 7 6 5 4 3 2 1 0 5 0 label (max 25)          X;
%ntabler(F11215,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,MDs Total Ptn Care Non-Fd);
%ntabler(F04603,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,MDs PtnCr Ofc Basd Non-Fd);
%ntabler(F11216,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,MDs PtnCr Hsp Basd Non-Fd);
%ntabler(F12499,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,MDs PtnCr Hsp Res Non-Fed);
%ntabler(F04605,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,MDs PtnCr Hsp FT Non-Fed);
%ntabler(F08860,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,MDs PtnCrOfcBsd GP Non-Fd);
%ntabler(F08861,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,MDs PtnCrOfcBsdMSpc Nn-Fd);
%ntabler(F08863,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,MDs PtnCrOfcBsdOSpc Nn-Fd);
%ntabler(F14693,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,DOs Total Ptn Care Non-Fd);
%ntabler(F14694,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,DOs PtnCr Ofc Basd Non-Fd);
%ntabler(F14695,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,DOs PtnCr Hsp Res Non-Fed);
%ntabler(F14696,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,DOs PtnCr Hsp FT Non-Fed);
%ntabler(F14697,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,DOs PtnCr Oth Prof Non-Fd);
%ntabler(F14641,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,Phys Assistants with NPI);
%ntabler(F13219,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,Ambulatory Surgery Centrs);
%ntabler(F08909,N,N,Y,N,N,N,N,N,N,N,N,N,Y,N,N,Hospital Admissions);
%ntabler(F08921,N,N,Y,N,N,N,N,N,N,N,N,N,Y,N,N,Hospital Beds);
%ntabler(F09545,N,N,Y,N,N,N,N,N,N,N,N,N,Y,N,N,Inpatient Days);
%ntabler(F09572,N,N,Y,N,N,N,N,N,N,N,N,N,Y,N,N,ST Hsp Emrgncy Dept Vsts);
%ntabler(F09574,N,N,Y,N,N,N,N,N,N,N,N,N,Y,N,N,ST+LT Hsp EmrgncyDpt Vsts);

*selected AHRF variables, block 2: demographics;
*review the AHRF data dictionary and use the Y/N flags to set the indicator for presence of the variable in each year.;
*        1st 6  2 2 2 1 1 1 1 1 1 1 1 1 1 0 0 variable                X;
*        var_nm 2 1 0 9 8 7 6 5 4 3 2 1 0 5 0 label (max 25)          X;
%ntabler(F11984,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,Y,N,Population Estimate);
%ntabler(F04530,N,N,Y,N,N,N,N,N,N,N,N,N,Y,N,Y,Census Population);
%ntabler(F13906,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Total Male);
%ntabler(F13907,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Total Female);
%ntabler(F13908,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Total White Male);
%ntabler(F13909,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Total White Female);
%ntabler(F13926,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,White Non-Hisp Male);
%ntabler(F13927,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,White Non-Hisp Female);
%ntabler(F13924,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,White Hisp Male);
%ntabler(F13925,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,White Hisp Female);
%ntabler(F13910,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Black Male);
%ntabler(F13911,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Black Female);
%ntabler(F13979,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Black Non-Hisp Male);
%ntabler(F13980,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Black Non-Hisp Female);
%ntabler(F13981,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Black Hisp Male);
%ntabler(F13982,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Black Hisp Female);
%ntabler(F13912,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Native Male);
%ntabler(F13913,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Native Female);
%ntabler(F13914,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Asian Male);
%ntabler(F13915,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Asian Female);
%ntabler(F13916,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Islander Male);
%ntabler(F13917,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Islander Female);
%ntabler(F13918,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Two+ Races Male);
%ntabler(F13919,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Two+ Races Female);
%ntabler(F13920,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Hisp Male);
%ntabler(F13921,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Hisp Female);
%ntabler(F13922,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Non-Hisp Male);
%ntabler(F13923,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Non-Hisp Female);

*selected AHRF variables, block 3: income, housing and insurance;
*review the AHRF data dictionary and use the Y/N flags to set the indicator for presence of the variable in each year.;
*        1st 6  2 2 2 1 1 1 1 1 1 1 1 1 1 0 0 variable                X;
*        var_nm 2 1 0 9 8 7 6 5 4 3 2 1 0 5 0 label (max 25)          X;
%ntabler(F14083,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Pop Est 65+);
%ntabler(F11396,Y,Y,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Pop Est Veterans);
%ntabler(F15550,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,N,Medicare Enrollment Aged);
%ntabler(F15551,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,N,Medicare Enrollment Dsbld);
%ntabler(F13191,N,Y,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Eligible for Medicare);
%ntabler(F09781,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Per Capita Prsnl Income);
%ntabler(F13226,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Median Household Income);
%ntabler(F13223,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Persons in Poverty);
%ntabler(F06792,N,Y,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Civilian Labor Force 16+);
%ntabler(F06793,N,Y,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Number Employed 16+);
%ntabler(F06794,N,Y,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Number Unemployed 16+);
%ntabler(F06795,N,Y,Y,Y,Y,Y,Y,Y,N,N,N,N,Y,N,N,Unemployment Rate 16+);
%ntabler(F13515,N,N,Y,N,N,N,N,N,N,N,N,N,Y,N,N,Housing Units);
%ntabler(F14091,N,N,N,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,Housing Units Estimates);
