*Create temp dataset with county classifications and physicians per 100k measures by year; 
proc sql;
 create table phys_per100k_yrs as
 select 
  a.fips_st_cnty, a.st_abbr, a.st_cnty_nm, b.metric,
  a.cbsa_ind_cd_msa, a.cbsa_status_central, a.rur_urb_cntm_cd_02, a.urb_infl_cd_2,
  b.y20, b.y19, b.y18, b.y17, b.y16, b.y15, b.y14, b.y13, b.y12, b.y11, b.y10
 from sas.selected_counties a
 left join ahrf.ahrf_cnty_tbl b
 on a.fips_st_cnty=b.fips_st_cnty
 where b.metric in (
  'F08860 MDs PtnCrOfcBsd GP Non-Fd',
  'F08861 MDs PtnCrOfcBsdMSpc Nn-Fd',
  'F04603 MDs PtnCr Ofc Basd Non-Fd',
  'F14694 DOs PtnCr Ofc Basd Non-Fd',
  'F11984 Population Estimate',
  'F04530 Census Population') 
 order by a.fips_st_cnty, a.st_abbr, a.st_cnty_nm, b.metric 
;quit;run;

*check summary stats;
proc means data=phys_per100k_yrs n nmiss mean std min p1 p10 p25 median p75 p90 p99 max;
 class metric;
 var y20 y19 y18 y17 y16 y15 y14 y13 y12 y11 y10;
run;

*transpose dataset so there is one observation per county and year;
proc transpose data=phys_per100k_yrs out=phys_per100k_yrs name=year;
 by fips_st_cnty st_abbr st_cnty_nm 
    cbsa_ind_cd_msa cbsa_status_central rur_urb_cntm_cd_02 urb_infl_cd_2;
 var y20 y19 y18 y17 y16 y15 y14 y13 y12 y11 y10;
 id metric;
run;

*calclate rates per 100000;
proc sql;
 create table phys_per100k_yrs as
 select 
  fips_st_cnty, st_abbr, st_cnty_nm, input('20'||substr(year,2,2),4.0) as year,  
  cbsa_ind_cd_msa, cbsa_status_central, rur_urb_cntm_cd_02, urb_infl_cd_2,
  coalesce('F11984 Population Estimate'n,'F04530 Census Population'n) as popn, 
  
  'F04603 MDs PtnCr Ofc Basd Non-Fd'n+'F14694 DOs PtnCr Ofc Basd Non-Fd'n as mds_dos,
  ('F04603 MDs PtnCr Ofc Basd Non-Fd'n+'F14694 DOs PtnCr Ofc Basd Non-Fd'n) /
  coalesce('F11984 Population Estimate'n,'F04530 Census Population'n)*100000 as mds_dos_per100k,
  
  'F08860 MDs PtnCrOfcBsd GP Non-Fd'n as mds_gp,
  'F08860 MDs PtnCrOfcBsd GP Non-Fd'n /
  coalesce('F11984 Population Estimate'n,'F04530 Census Population'n)*100000 as mds_gp_per100k,
  
  'F08861 MDs PtnCrOfcBsdMSpc Nn-Fd'n as mds_spec,
  'F08861 MDs PtnCrOfcBsdMSpc Nn-Fd'n /
  coalesce('F11984 Population Estimate'n,'F04530 Census Population'n)*100000 as mds_spec_per100k

 from phys_per100k_yrs 
;quit;run;

*This macro will create yearly stats for different subsets of counties;
%macro top(title,suffix,criteria);
 /*creates a subset of counties based on &criteria named with &suffix*/
 proc sql;
  create table yrs_subs_&suffix as
  select * from phys_per100k_yrs 
  where ( &criteria )
 ;quit;run;

 /*produces a dataset with the summary stats for the subset of counties*/
 title"Summary Stats for &title.";
 proc means data=yrs_subs_&suffix mean ;
  class year;
  var mds_dos_per100k mds_gp_per100k mds_spec_per100k;
  output out=yrs_subs_&suffix._smry 
  mean(mds_dos_per100k)= mean(mds_gp_per100k)= mean(mds_spec_per100k)= / autoname;
 run;
 title;
 
 /*clean up proc means output dataset*/
 data yrs_subs_&suffix._smry (drop=_type_ );
  set yrs_subs_&suffix._smry (where=(_type_=1));
  rename _freq_=st_county_ct;
 run;
%mend;

ods html body='/home/maguirejonathan/physician_supply/output/p35_yrs_stats.html' style=HTMLBlue;
%top(All US Counties,alus,%str(1=1));
%top(All CA Counties,alca,%str(st_abbr='CA'));
%top(Same Type Counties,type,%str(cbsa_ind_cd_msa=1 and cbsa_status_central=1 and rur_urb_cntm_cd_02=1 and urb_infl_cd_2=1));
%top(Top 25 Similar Counties,t_25,%str(fips_st_cnty in (select distinct fips_st_cnty from sas.county_similarity where sb_similar_rank le 26)));
%top(Top 50 Similar Counties,t_50,%str(fips_st_cnty in (select distinct fips_st_cnty from sas.county_similarity where sb_similar_rank le 51)));
%top(Top 100 Similar Counties,t100,%str(fips_st_cnty in (select distinct fips_st_cnty from sas.county_similarity where sb_similar_rank le 101)));
ods html close;

*set all the summary datasets together in one permanent dataset. 
 include the data for SB as a separate group.;
data sas.phys_per100k_yrs (drop=st_cnty_nm);
 set yrs_subs_alus_smry(in=a) 
     yrs_subs_alca_smry(in=b) 
     yrs_subs_type_smry(in=c) 
     yrs_subs_t_25_smry(in=d)
     yrs_subs_t_50_smry(in=e)
     yrs_subs_t100_smry(in=f)
     phys_per100k_yrs    (in=g
       where=(st_cnty_nm='Santa Barbara, CA')
       keep=year st_cnty_nm mds_dos_per100k mds_gp_per100k mds_spec_per100k
       rename=(mds_dos_per100k=mds_dos_per100k_mean mds_gp_per100k=mds_gp_per100k_mean
               mds_spec_per100k=mds_spec_per100k_mean) 
      );
     
     ;
 if g then st_county_ct=1 ;

 if a then sb_similar_ind='ALUS';
 if b then sb_similar_ind='ALCA';
 if c then sb_similar_ind='TYPE';
 if d then sb_similar_ind='T_25';
 if e then sb_similar_ind='T_50';
 if f then sb_similar_ind='T100';
 if g then sb_similar_ind='SBCA';  
run; 

proc sort data=sas.phys_per100k_yrs;
 by sb_similar_ind year;
run;

*get slopes of each measure over years using linear regression ;
proc reg data=sas.phys_per100k_yrs noprint 
 outest=phys_per100k_yrs_slopes(keep=sb_similar_ind _depvar_ intercept year);
 by sb_similar_ind ;
 model mds_dos_per100k_mean=year;
 model mds_gp_per100k_mean=year;
 model mds_spec_per100k_mean=year;
run;
 
 
 