/* Adapted from sas/code/p03_ahrf_cnty_tbl.sas (magsj/sbar_ca_physicians_per_100k)
   The original macro %ctabler transposes a single AHRF variable (one column per
   historical year, e.g. F1121522, F1121521, ... F1121505) into a long "tidy"
   table with one row per county+metric and columns y22..y00 for each year that
   variable was collected. It is called once per AHRF field the analysis needs
   (physician counts, demographics, etc.) and proc-appends each result onto a
   single permanent table (ahrf.ahrf_cnty_tbl in the original).

   Substitution applied: &ahrf_out now points at a small mock county-level
   dataset (5 CA/NV counties) shaped like the real AHRF extract -- same field
   naming convention (F11215xx = "MDs Total Ptn Care Non-Fed" for two-digit
   year xx) -- instead of the full 14,753-column AHRF2021-2022.sas load. The
   macro body, the Y/N year-availability flags, and the transpose logic are
   unmodified from the source. Output goes to WORK instead of a permanent
   ahrf libname. */

data work.ahrf_mock;
   length fips_st_cnty $5 fips_st $2 fips_cnty $3 st_cnty_nm $30 st_abbr $2 cnty_nm $25;
   input fips_st_cnty $ st_abbr $ cnty_nm $ F1121520 F1121519 F1121518 F1121517 F1121516 F1121515;
   fips_st = substr(fips_st_cnty,1,2);
   fips_cnty = substr(fips_st_cnty,3,3);
   st_cnty_nm = strip(cnty_nm) || ', ' || st_abbr;
   datalines;
06083 CA Santa_Barbara_County 410 402 395 388 379 371
06073 CA San_Diego_County 5120 5001 4890 4780 4655 4530
06037 CA Los_Angeles_County 12840 12650 12410 12190 11980 11750
32003 NV Clark_County 3210 3105 3010 2920 2830 2745
06001 CA Alameda_County 2670 2601 2545 2490 2430 2375
;
run;

%let ahrf_out = work.ahrf_mock;

*macro to transpose selected metrics so that each year's value appears in a column named for that year
 and the rows are unique per county and metric.;
%macro ctabler(varname,y22,y21,y20,y19,y18,y17,y16,y15,y14,y13,y12,y11,y10,y05,y00,varlbl);
 proc sql;

  /*create a temporary dataset for each selected variable*/
  create table cnty_hlth_tmp as

  select

   fips_st_cnty, /*Header - FIPS St & Cty Code*/
   fips_st,      /*FIPS State Code*/
   fips_cnty,    /*FIPS County Code*/
   st_cnty_nm,   /*County Name w/State Abbrev*/
   st_abbr,      /*State Name Abbreviation*/
   cnty_nm,      /*County Name*/

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

 ;quit;run;

 *append the dataset for each selected variable to the permanent dataset;
 proc append base=work.ahrf_cnty_tbl data=work.cnty_hlth_tmp force; run;

 *delete the temporary dataset;
 proc delete data=work.cnty_hlth_tmp; run;

%mend ctabler;

*using proc append in the macro so before executing the macro, delete the permanent file if it already exists
 (guarded here since WORK is freshly cleared each run, unlike the original script's persistent ahrf libname);
%if %sysfunc(exist(work.ahrf_cnty_tbl)) %then %do;
 proc delete data=work.ahrf_cnty_tbl; run;
%end;

*selected AHRF variable, block 1: healthcare resources (mirrors p03's F11215 call);
%ctabler(F11215,N,N,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,N,MDs Total Ptn Care Non-Fd);

proc print data=work.ahrf_cnty_tbl noobs;
   title "Physicians per county, transposed by year (mock AHRF extract)";
   format y22 y21 y20 y19 y18 y17 y16 y15 y14 y13 y12 y11 y10 y05 y00 6.;
run;
