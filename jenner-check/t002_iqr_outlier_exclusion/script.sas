/* Adapted from sas/code/p11_selected_counties.sas (magsj/sbar_ca_physicians_per_100k)
   The original builds a county-level analysis table from two upstream AHRF
   extracts (a county x metric x year long table, and a county geography
   header table), then computes physicians-per-100k rates and excludes
   extreme-outlier counties using a semi-interquartile-range (SIQR) fence
   (Kimber 1990; Aucremanne et al. 2004) -- a nice touch of the author citing
   the statistical literature for their fence choice rather than using the
   textbook 1.5*IQR rule uncritically.

   Substitution applied: the two PROC SQL steps that assemble `counties` from
   ahrf.ahrf_cnty_tbl / ahrf.cnty_geog_hdr are replaced by one small mock
   dataset built directly in the shape the original code consumes downstream
   (post-transpose, already carrying mds_dos_per_100k etc.) -- 12 CA/NV/OR
   counties with realistic rates and a couple of deliberately planted
   extremes to exercise the fence. The IQR fence, the exclusion-summary
   table, and the descriptive PROC MEANS are the repo's own logic, unedited
   except for redirecting ODS output to the listing instead of a home-dir
   HTML file path. */

data counties;
   length fips_st_cnty $5 st_cnty_nm $30 st_abbr $2;
   input fips_st_cnty $ st_abbr $ st_cnty_nm $ mds_dos_y20 popn pct_cvln_lbr_frc_ovr15
         pct_ovr64 pct_female pct_wht_non_hisp prsnl_income pct_in_pvrty hsptl_beds_per_100k
         cbsa_ind_cd_msa cbsa_status_central rur_urb_cntm_cd_02;
   mds_dos_per_100k = mds_dos_y20 / popn * 100000;
   datalines;
06083 CA Santa_Barbara_County 410 448229 0.63 0.16 0.51 0.44 34200 0.18 210 1 1 1
06073 CA San_Diego_County 5120 3298634 0.65 0.15 0.44 0.40 38900 0.14 195 1 1 1
06037 CA Los_Angeles_County 12840 10014009 0.62 0.14 0.27 0.28 35600 0.19 180 1 1 0
32003 NV Clark_County 3210 2265461 0.66 0.15 0.48 0.32 33100 0.15 165 1 1 0
06001 CA Alameda_County 2670 1682353 0.68 0.14 0.32 0.30 47800 0.11 175 1 1 0
41051 OR Multnomah_County 1980 815428 0.67 0.14 0.65 0.28 44200 0.13 240 1 1 0
06111 CA Ventura_County 890 843843 0.62 0.16 0.42 0.29 36900 0.09 155 1 1 1
06079 CA San_Luis_Obispo_County 520 283111 0.60 0.19 0.62 0.44 33800 0.11 220 1 1 1
06029 CA Kern_County 940 909235 0.59 0.10 0.34 0.30 24700 0.20 145 1 1 0
06053 CA Monterey_County 610 439035 0.63 0.13 0.28 0.29 30500 0.15 130 1 1 1
32031 NV Washoe_County 1150 486492 0.64 0.14 0.55 0.29 35200 0.13 185 1 1 1
06025 CA Imperial_County 900 18121 0.55 0.11 0.15 0.44 19800 0.22 50 1 1 0
;
run;

*after other exclusions, find upper and lower bounds to exclude extreme outliers.
 Some authors (Kimber, 1990, Aucremanne et al., 2004) have adjusted the fence towards
 skewed data by use of the lower and upper semi-interquartile range SIQR{L}=Q2-Q1
 and SIQR{U}=Q3-Q2, i.e. they define the fence as [Q1-1.5*2*SIQR{L}, Q3+1.5*2*SIQR{U}] or
 [Q1-3*2*SIQR{L}, Q3+3*2*SIQR{U}] for extreme outliers.
 https://www.sciencedirect.com/science/article/abs/pii/S0167947307004434;
proc means data=counties median q1 q3 noprint;
 where mds_dos_y20>0
 and popn +pct_cvln_lbr_frc_ovr15 +pct_ovr64 +pct_female
     +pct_wht_non_hisp +prsnl_income +pct_in_pvrty +hsptl_beds_per_100k ne .;
 var mds_dos_per_100k;
 output out=counties_iqr
  median(mds_dos_per_100k)= q1(mds_dos_per_100k)= q3(mds_dos_per_100k)=
 / autoname;
run;

*put thresholds into macro variables;
proc sql noprint;
 select
  mds_dos_per_100k_q1 - (3*2*(mds_dos_per_100k_median-mds_dos_per_100k_q1)),
  mds_dos_per_100k_q3 + (3*2*(mds_dos_per_100k_q3-mds_dos_per_100k_median))
 into
  :md_lowerb, :md_upperb
 from counties_iqr
;quit;run;

%put md_lowerb= &md_lowerb ;
%put md_upperb= &md_upperb ;

*create output summarizing county exclusions;
proc sql;

 create table excluded_counties_smry as

 select distinct '1. Total Counties Before Exclusions' as Step format=$65.,
        count(distinct fips_st_cnty) as 'N Counties'n
 from counties

 union
 select distinct '2. Less: County has no MDs/DOs' as Step format=$65.,
        count(distinct fips_st_cnty) as n_counties
 from counties
 where mds_dos_y20=. or mds_dos_y20=0

 union
 select distinct '3. Less: Extreme outliers (<Q1-3*2*SIQR{L} or >Q3+3*2*SIQR{U})' as Step format=$65.,
        count(distinct fips_st_cnty) as 'N Counties'n
 from counties
 where mds_dos_y20>0
 and (mds_dos_per_100k le &md_lowerb or mds_dos_per_100k ge &md_upperb)

 union
 select distinct '4. Remaining Counties After Exclusions' as Step format=$65.,
        count(distinct fips_st_cnty) as 'N Counties'n
 from counties
 where mds_dos_y20>0
 and mds_dos_per_100k gt &md_lowerb
 and mds_dos_per_100k lt &md_upperb;

 select * from excluded_counties_smry;

;quit;run;

*descriptive output on the included counties;
proc sql;
 create table selected_counties as
 select * from counties
 where mds_dos_y20>0
 and mds_dos_per_100k gt &md_lowerb
 and mds_dos_per_100k lt &md_upperb
;quit;run;

proc means data=selected_counties n mean stddev min p25 median p75 max;
 var popn mds_dos_per_100k prsnl_income hsptl_beds_per_100k;
run;
