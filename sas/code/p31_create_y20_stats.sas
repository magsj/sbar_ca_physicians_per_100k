*Create temp dataset with county classifications and physicians per 1k measures; 
proc sql;
 create table physicians_per_1k_cnty as
 select 
  fips_st_cnty, st_abbr, st_cnty_nm, 
  cbsa_ind_cd_msa, cbsa_status_central, rur_urb_cntm_cd_02, urb_infl_cd_2,
  popn, mds_dos_per_1k, mds_gp_per_1k, mds_spec_per_1k
 from sas.selected_counties
;quit;run;

* The CBSA Indicator Code field defines the county’s type.  It is defined as follows:
0 = Not a Statistical Area
1 = Metropolitan Statistical Area
2 = Micropolitan Statistical Area;
* The CBSA Indicator Code for SB = 1 Metropolitan Statistical Area;

* CBSA County Status field identifies a county of a Metropolitan or Micropolitan Statistical Area 
as either central or outlying.  Under the standards, the county (or counties) in which at least 
50 percent of the population resides within urban areas of 10,000 or more population, or contain 
at least 5,000 people residing within a single urban area of 10,000 or more population, is 
identified as a “central county” (counties).;
* CBSA County Status for SB = Central;

* The 2013 Rural/Urban Continuum Codes are defined as follows:
CODE				METROPOLITAN COUNTIES (1-3)
01		Counties in metro areas of 1 million population or more
02		Counties in metro areas of 250,000 – 1,000,000 population
03		Counties in metro areas of fewer than 250,000 population;
* The 2013 Rural/Urban Continuum Code for SB = 02 Counties in metro areas of 250,000 – 1,000,000 population

* The 2013 Urban Influence Codes form a classification scheme that distinguishes metropolitan 
(metro) counties by population size of their metro area, and nonmetropolitan (nonmetro) counties 
by size of the largest city or town and proximity to metropolitan and micropolitan areas. 
CODE		METROPOLITAN
1		In a large metro area of 1 million residents or more 
2		In a small metro area of less than 1 million residents ;
* The 2013 Urban Influence Code = 2 In a small metro area of less than 1 million residents ;

*This macro will create summary stats for different subsets of counties;
%macro top(suffix,criteria);
 /*creates a subset of counties based on &criteria named with &suffix*/
 proc sql;
  create table 
   cnty_smlr_&suffix
  as
  select *, case when st_abbr='CA' then 'Y' else 'N' end as ca_cnty
  from physicians_per_1k_cnty 
  where ( &criteria )
 ;quit;run;

 /*find the percentiles of counties within the subset for the US*/
 proc rank data=cnty_smlr_&suffix out=cnty_smlr_&suffix ties=high groups=100;
  var mds_dos_per_1k mds_gp_per_1k mds_spec_per_1k;
  ranks mds_dos_per_1k_us_ptile mds_gp_per_1k_us_ptile mds_spec_per_1k_us_ptile;
 run;

 /*find the percentiles of counties within the subset for CA*/
 proc sort data=cnty_smlr_&suffix ; by ca_cnty; run;
 proc rank data=cnty_smlr_&suffix out=cnty_smlr_&suffix ties=high groups=100;
  by ca_cnty;
  var mds_dos_per_1k mds_gp_per_1k mds_spec_per_1k;
  ranks mds_dos_per_1k_st_ptile mds_gp_per_1k_st_ptile mds_spec_per_1k_st_ptile;
 run;

 /*produces a dataset with the summary stats for the subset of counties*/
 title"Summary Stats for Similar Counties by &suffix.";
 proc means data=cnty_smlr_&suffix n nmiss mean std min p1 p5 p10 p25 p40 p50 p60 p75 p90 p95 p99 max;
  class ca_cnty;
  var mds_dos_per_1k mds_gp_per_1k mds_spec_per_1k;
  output out=cnty_smlr_&suffix._smry
   n(mds_dos_per_1k)= mean(mds_dos_per_1k)= std(mds_dos_per_1k)= min(mds_dos_per_1k)=
   p1(mds_dos_per_1k)= p5(mds_dos_per_1k)= p10(mds_dos_per_1k)= p25(mds_dos_per_1k)= 
   p40(mds_dos_per_1k)= p50(mds_dos_per_1k)= p60(mds_dos_per_1k)= p75(mds_dos_per_1k)= 
   p90(mds_dos_per_1k)= p95(mds_dos_per_1k)= p99(mds_dos_per_1k)= max(mds_dos_per_1k)= 
 
   n(mds_gp_per_1k)= mean(mds_gp_per_1k)= std(mds_gp_per_1k)= min(mds_gp_per_1k)=
   p1(mds_gp_per_1k)= p5(mds_gp_per_1k)= p10(mds_gp_per_1k)= p25(mds_gp_per_1k)= 
   p40(mds_gp_per_1k)= p50(mds_gp_per_1k)= p60(mds_gp_per_1k)= p75(mds_gp_per_1k)= 
   p90(mds_gp_per_1k)= p95(mds_gp_per_1k)= p99(mds_gp_per_1k)= max(mds_gp_per_1k)= 
  
   n(mds_spec_per_1k)= mean(mds_spec_per_1k)= std(mds_spec_per_1k)= min(mds_spec_per_1k)= 
   p1(mds_spec_per_1k)= p5(mds_spec_per_1k)= p10(mds_spec_per_1k)= p25(mds_spec_per_1k)= 
   p40(mds_spec_per_1k)= p50(mds_spec_per_1k)= p60(mds_spec_per_1k)= p75(mds_spec_per_1k)= 
   p90(mds_spec_per_1k)= p95(mds_spec_per_1k)= p99(mds_spec_per_1k)= max(mds_spec_per_1k)= 
  / autoname;
 run;
 title;
 
 /*clean up proc means output dataset*/
 data cnty_smlr_&suffix._smry;
  set cnty_smlr_&suffix._smry;
  if _type_=0 then st_abbr='US';
  if ca_cnty='Y' then st_abbr='CA';
  if ca_cnty='N' then delete;
  rename _freq_=st_county_ct;
  drop _type_ ca_cnty;
 run;
%mend;

ods html body='/home/maguirejonathan/physician_supply/output/p31_y20_stats.html' style=HTMLBlue;
/*all counties*/            %top(all_,%str(1=1));
/*same type counties as SB*/%top(type,%str(cbsa_ind_cd_msa=1 and cbsa_status_central=1 and rur_urb_cntm_cd_02=1 and urb_infl_cd_2=1));
/*top 25 similar counties */%top(t_25,%str(fips_st_cnty in (select distinct fips_st_cnty from sas.county_similarity where sb_similar_rank le 26)));
/*top 50 similar counties */%top(t_50,%str(fips_st_cnty in (select distinct fips_st_cnty from sas.county_similarity where sb_similar_rank le 51)));
/*top 100 similar counties*/%top(t100,%str(fips_st_cnty in (select distinct fips_st_cnty from sas.county_similarity where sb_similar_rank le 101)));
ods html close;

*set all the summary datasets together in one permanent dataset;
data sas.physicians_per_1k_smry;
 set cnty_smlr_all__smry(in=a) 
     cnty_smlr_type_smry(in=b) 
     cnty_smlr_t_25_smry(in=c)
     cnty_smlr_t_50_smry(in=d)
     cnty_smlr_t100_smry(in=e);
 if a then sb_similar_ind='ALL_';
 if b then sb_similar_ind='TYPE';
 if c then sb_similar_ind='T_25';
 if d then sb_similar_ind='T_50';
 if e then sb_similar_ind='T100';
run; 

proc sort data=sas.physicians_per_1k_smry;
 by st_abbr sb_similar_ind;
run;

*set all the datasets with SB's percentiles within each subset together in one permanent dataset;
data sas.physicians_per_1k_sb;
 set cnty_smlr_all_(in=a) 
     cnty_smlr_type(in=b) 
     cnty_smlr_t_25(in=c)
     cnty_smlr_t_50(in=d)
     cnty_smlr_t100(in=e);
 if a then sb_similar_ind='ALL_';
 if b then sb_similar_ind='TYPE';
 if c then sb_similar_ind='T_25';
 if d then sb_similar_ind='T_50';
 if e then sb_similar_ind='T100';
 
 if st_cnty_nm='Santa Barbara, CA';
run; 

proc sort data=sas.physicians_per_1k_sb;
 by st_abbr sb_similar_ind;
run;
