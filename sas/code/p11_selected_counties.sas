*create a dataset with AHRF fields selected for this analysis for 2020 ;
proc sql;
 create table counties as
 select a.fips_st_cnty, a.st_cnty_nm, a.st_abbr, a.metric, a.y20 
  
 from ahrf.ahrf_cnty_tbl a
 
 where a.metric in (
 
  /*selected physician count variables*/
  'F08860 MDs PtnCrOfcBsd GP Non-Fd',
  'F08861 MDs PtnCrOfcBsdMSpc Nn-Fd',
  'F04603 MDs PtnCr Ofc Basd Non-Fd',
  'F14694 DOs PtnCr Ofc Basd Non-Fd',
  
  /*selected county characteristics*/
  'F11984 Population Estimate',
  'F06792 Civilian Labor Force 16+',
  'F14083 Pop Est 65+',
  'F13907 Total Female',
  'F13926 White Non-Hisp Male',
  'F13927 White Non-Hisp Female',
  'F09781 Per Capita Prsnl Income',
  'F08921 Hospital Beds', 
  'F13223 Persons in Poverty')
  
 order by a.fips_st_cnty, a.st_cnty_nm, a.st_abbr
 
;quit;run;

*transpose dataset so that there is one row per county and the fields are arrayed on that row;
proc transpose data=counties out=counties(drop=_name_ _label_) ;
 id metric;
 by fips_st_cnty st_cnty_nm st_abbr;
run;  

*bring in additional county status fields from the geography header dataset,
 rename fields for ease of use, and create percents and rates for direct comparisons;
proc sql;
 create table counties as 
 
 select a.fips_st_cnty, a.st_cnty_nm, a.st_abbr,  
 
  /*selected county status and type variables*/
  case when b.cbsa_ind_cd='1' then 1 else 0 end        as cbsa_ind_cd_msa,    /*1 = Metropolitan Statistical Area (eg Santa Barbara)*/
  case when b.cbsa_status='Central' then 1 else 0 end  as cbsa_status_central,/*county w/>50% residing in urban areas of 10,000 or more population, or contain at least 5,000 people residing within a single urban area of 10,000+*/
  case when b.rur_urb_cntm_cd='02' then 1 else 0 end   as rur_urb_cntm_cd_02, /*02 = Counties in metro areas of 250,000 – 1,000,000 population (eg Santa Barabra)*/
  case when b.urb_infl_cd='2' then 1 else 0 end        as urb_infl_cd_2,      /*2 = In a small metro area of less than 1 million residents */
 
  /*selected physician count variables*/
  a.'F04603 MDs PtnCr Ofc Basd Non-Fd'n as mds_y20,
  a.'F14694 DOs PtnCr Ofc Basd Non-Fd'n as dos_y20,
  (a.'F04603 MDs PtnCr Ofc Basd Non-Fd'n+a.'F14694 DOs PtnCr Ofc Basd Non-Fd'n) as mds_dos_y20,
  a.'F08860 MDs PtnCrOfcBsd GP Non-Fd'n as mds_gp_y20,
  a.'F08861 MDs PtnCrOfcBsdMSpc Nn-Fd'n as mds_spec_y20,
  
  /*selected county characteristics*/
  a.'F11984 Population Estimate'n                                      as popn,
  a.'F06792 Civilian Labor Force 16+'n                                 as cvln_lbr_frc_ovr15,
  a.'F06792 Civilian Labor Force 16+'n/a.'F11984 Population Estimate'n as pct_cvln_lbr_frc_ovr15,
  a.'F14083 Pop Est 65+'n                                              as pop_ovr64,
  a.'F14083 Pop Est 65+'n/a.'F11984 Population Estimate'n              as pct_ovr64,
  a.'F13907 Total Female'n                                             as pop_female,
  a.'F13907 Total Female'n/a.'F11984 Population Estimate'n             as pct_female,
  a.'F13926 White Non-Hisp Male'n+a.'F13927 White Non-Hisp Female'n    as pop_wht_non_hisp,
  (a.'F13926 White Non-Hisp Male'n+a.'F13927 White Non-Hisp Female'n)/a.'F11984 Population Estimate'n as pct_wht_non_hisp,
  a.'F09781 Per Capita Prsnl Income'n                                  as prsnl_income,
  a.'F13223 Persons in Poverty'n                                       as pop_in_pvrty,
  a.'F13223 Persons in Poverty'n/a.'F11984 Population Estimate'n       as pct_in_pvrty,
  a.'F08921 Hospital Beds'n                                            as hsptl_beds,
  a.'F08921 Hospital Beds'n/a.'F11984 Population Estimate'n*1000       as hsptl_beds_per_1k
  
 from counties a 
 
 left outer join ahrf.cnty_geog_hdr b
 on a.fips_st_cnty=b.fips_st_cnty

;quit;run; 

*create output summarizing county exclusions;
ods html body='/home/maguirejonathan/physician_supply/output/p11_excl_smry.html' style=HTMLBlue;
proc sql;

 create table sas.excluded_counties_smry as
 
 select distinct '1. Total Counties Before Exclusions' as info format=$55., 
        count(distinct fips_st_cnty) as n_counties
 from counties
 
 union
 select distinct '2. Less: County has no MDs/DOs' as info format=$55., 
        count(distinct fips_st_cnty) as n_counties
 from counties
 where mds_dos_y20=. or mds_dos_y20=0

 union
 select distinct '3. Less: County has mising attributes' as info format=$55., 
        count(distinct fips_st_cnty) as n_counties
 from counties
 where mds_dos_y20>0 
 and popn +pct_cvln_lbr_frc_ovr15 +pct_ovr64 +pct_female 
     +pct_wht_non_hisp +prsnl_income +pct_in_pvrty +hsptl_beds_per_1k = .
 
 union
 select distinct '4. Remaining Counties After Exclusions' as info format=$55., 
        count(distinct fips_st_cnty) as n_counties
 from counties
 where mds_dos_y20>0
 and popn +pct_cvln_lbr_frc_ovr15 +pct_ovr64 +pct_female 
     +pct_wht_non_hisp +prsnl_income +pct_in_pvrty +hsptl_beds_per_1k ne .;
 
 select * from sas.excluded_counties_smry;

;quit;run;
ods html close;
 
*create permanent listing of each excluded county in SAS and pipe delimited formats;
proc sql;

 create table sas.excluded_counties_dtl as
 
 select 'County has no MDs/DOs' as exclude_reason format=$30., a.*
 from counties a
 where mds_dos_y20=. or mds_dos_y20=0

 union
 select 'County has mising attributes' as exclude_reason format=$30., b.*
 from counties b
 where mds_dos_y20>0 
 and popn +pct_cvln_lbr_frc_ovr15 +pct_ovr64 +pct_female 
     +pct_wht_non_hisp +prsnl_income +pct_in_pvrty +hsptl_beds_per_1k = .;

;quit;run;

proc export 
 data=sas.excluded_counties_dtl 
 outfile='/home/maguirejonathan/physician_supply/output/p11_excluded_counties_dtl.txt'
 dbms=dlm replace;
 delimiter='|';
run;
 
*create a permanent file containing the included counties in SAS and pipe delimited formats;
proc sql;

 create table sas.selected_counties as
 
 select * from counties 
 where mds_dos_y20>0
 and popn +pct_cvln_lbr_frc_ovr15 +pct_ovr64 +pct_female 
     +pct_wht_non_hisp +prsnl_income +pct_in_pvrty +hsptl_beds_per_1k ne .;

;quit;run;

proc export 
 data=sas.selected_counties 
 outfile='/home/maguirejonathan/physician_supply/output/p11_selected_counties.txt'
 dbms=dlm replace;
 delimiter='|';
run;

*descriptive output on the included counties;
ods html body='/home/maguirejonathan/physician_supply/output/p11_incl_desc.html' style=HTMLBlue;
proc means data=sas.selected_counties n nmiss mean stddev min p1 p5 p10 p25 median p75 p90 p95 p99 max;
 var popn
  cbsa_ind_cd_msa cbsa_status_central rur_urb_cntm_cd_02 urb_infl_cd_2
  pct_cvln_lbr_frc_ovr15 pct_ovr64 pct_female 
  pct_wht_non_hisp prsnl_income pct_in_pvrty hsptl_beds_per_1k;
run;
ods html close;