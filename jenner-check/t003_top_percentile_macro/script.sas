/* Adapted from sas/code/p31_create_y20_stats.sas (magsj/sbar_ca_physicians_per_100k)
   The original %top macro takes a subsetting criteria (e.g. "all counties",
   "counties of the same CBSA type as Santa Barbara", "the 25/50/100 counties
   most similar to Santa Barbara" from an earlier clustering step), computes
   national percentile ranks with PROC RANK, re-sorts and re-ranks within
   California alone, then produces a wide summary-stats table (N, mean,
   percentiles 1-99) per subset via PROC MEANS with CLASS ca_cnty. It's
   called five times in the original, once per subset, and the results are
   stacked into one permanent comparison table.

   Substitution applied: physicians_per_100k_cnty is a 14-county mock table
   (10 US counties incl. 4 CA) built in the shape p31 expects (post-p11
   output), instead of reading sas.selected_counties. The %top macro body is
   unedited; it's called twice here (all counties, and counties sharing
   Santa Barbara's CBSA/metro classification) instead of five times, and
   output goes to WORK/the listing instead of a permanent sas.* library and
   home-dir ODS HTML path. */

data physicians_per_100k_cnty;
   length fips_st_cnty $5 st_abbr $2 st_cnty_nm $30;
   input fips_st_cnty $ st_abbr $ st_cnty_nm $ cbsa_ind_cd_msa cbsa_status_central
         rur_urb_cntm_cd_02 urb_infl_cd_2 popn mds_dos_per_100k mds_gp_per_100k mds_spec_per_100k;
   datalines;
06083 CA Santa_Barbara_County 1 1 1 0 448229 91.4 45.6 66.9
06073 CA San_Diego_County 1 1 0 0 3298634 155.2 60.1 121.4
06037 CA Los_Angeles_County 1 1 0 0 10014009 128.3 55.4 98.7
06001 CA Alameda_County 1 1 0 0 1682353 158.6 62.0 134.5
41051 OR Multnomah_County 1 1 1 0 815428 242.8 71.3 155.9
32003 NV Clark_County 1 1 0 0 2265461 141.7 58.9 105.3
06111 CA Ventura_County 1 1 1 0 843843 105.5 48.2 71.0
06079 CA San_Luis_Obispo_County 1 1 1 0 283111 183.7 66.5 140.1
06029 CA Kern_County 1 1 0 0 909235 103.4 46.8 68.3
06053 CA Monterey_County 1 1 1 0 439035 138.9 57.7 99.4
17031 IL Cook_County 1 1 0 0 5150233 176.2 63.4 128.0
48201 TX Harris_County 1 1 0 0 4731145 121.5 52.9 85.6
53033 WA King_County 1 1 0 0 2252782 210.9 68.8 148.7
12086 FL Miami_Dade_County 1 1 0 0 2701767 133.6 54.1 91.2
;
run;

*This macro will create summary stats for different subsets of counties;
%macro top(title,suffix,criteria);
 /*creates a subset of counties based on &criteria named with &suffix*/
 proc sql;
  create table
   cnty_smlr_&suffix
  as
  select *, case when st_abbr='CA' then 'Y' else 'N' end as ca_cnty
  from physicians_per_100k_cnty
  where ( &criteria )
 ;quit;run;

 /*find the percentiles of counties within the subset for the US*/
 proc rank data=cnty_smlr_&suffix out=cnty_smlr_&suffix ties=high groups=100;
  var mds_dos_per_100k mds_gp_per_100k mds_spec_per_100k;
  ranks mds_dos_per_100k_us_ptile mds_gp_per_100k_us_ptile mds_spec_per_100k_us_ptile;
 run;

 /*find the percentiles of counties within the subset for CA*/
 proc sort data=cnty_smlr_&suffix ; by ca_cnty; run;
 proc rank data=cnty_smlr_&suffix out=cnty_smlr_&suffix ties=high groups=100;
  by ca_cnty;
  var mds_dos_per_100k mds_gp_per_100k mds_spec_per_100k;
  ranks mds_dos_per_100k_st_ptile mds_gp_per_100k_st_ptile mds_spec_per_100k_st_ptile;
 run;

 /*produces a dataset with the summary stats for the subset of counties*/
 title "Summary Stats for &title.";
 proc means data=cnty_smlr_&suffix n mean std min p25 p50 p75 max;
  class ca_cnty;
  var mds_dos_per_100k mds_gp_per_100k mds_spec_per_100k;
 run;
 title;
%mend;

%top(All Counties,all_,%str(1=1));
%top(Same Type Counties as Santa Barbara,type,%str(cbsa_ind_cd_msa=1 and cbsa_status_central=1 and rur_urb_cntm_cd_02=1));

proc print data=cnty_smlr_all_(obs=5) noobs;
 var fips_st_cnty st_cnty_nm mds_dos_per_100k mds_dos_per_100k_us_ptile mds_dos_per_100k_st_ptile;
 title "Sample of national + CA-state percentile ranks (all-counties subset)";
run;
