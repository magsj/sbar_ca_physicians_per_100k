* Without standardization variables measured in larger units will 
  dominate computed dissimilarity and variables that are measured 
  in smaller units will be overwhelmed.;
proc stdize data=sas.selected_counties out=cluster_std method=std nomiss ;
 var &fnl_vars ;
run;

*K is the number of groups of counties to divide all counties into. This macro will
 iterate over possible Ks between the min and max given as inputs to the macro.;
%macro kmean(minK, maxK);
 %do i = &minK %to &maxK ; /*I indexes over possible Ks*/
  /*fastclus combines an effective method for finding initial clusters with a standard iterative
    algorithm for minimizing the sum of squared distances from the cluster means*/
  proc fastclus data=cluster_std noprint 
   out=outk&I.      /*output dataset with similar counties for each possible K*/
   outstat=statk&I. /*output 3 selected stats for Ith dataset*/
    (where=(_type_ in ('PSEUDO_F','ERSQ','CCC')) 
     keep=_type_ over_all) 
   maxclusters= &I. maxiter=100 converge=0 impute;
   var &fnl_vars ;  /*final list of variables to guage similarity of counties by*/
  run;
  
  /*inserts the number of counties grouped together with santa barbara 
    for each possible K into macro variable n_counties_k*/
  proc sql noprint; 
   select distinct count(distinct fips_st_cnty) 
   into :n_counties_k
   from outk&I. 
   where cluster in 
   (select distinct cluster 
    from outk&I. 
    where fips_st_cnty='06083'/*Santa Barbara*/)
  ;quit;run;
  %put n_counties_k= &n_counties_k ;

  /*obtain a dataset containing the cluster that SB is a member of*/
  proc sql noprint; 
   create table sb_outk&I. as
   select distinct 
    fips_st_cnty, st_cnty_nm, st_abbr, cluster, distance, _impute_, 
    &I as k_clstrs, &n_counties_k as n_counties_w_sb
   from outk&I. 
   where cluster in 
   (select distinct cluster 
    from outk&I. 
    where fips_st_cnty='06083'/*Santa Barbara*/)
  ;quit;run;
  
  /*append the selected clusters with SB for subsequent summarization and delete temp datasets*/
  proc append base=list_sb_ks data=sb_outk&I. force; run; 
  proc delete data=sb_outk&I. ; run;
  proc delete data=outk&I. ; run;
   
  /*append the stats for the kept dataset to a file with stats for the slected Ks, and delete temp datasets*/
  data statk&I. ; set statk&I. ; k_clstrs = &I. ; n_counties_w_sb = &n_counties_k ; run;
  proc append base=describe_ks data=statk&I. force; run; 
  proc delete data=statk&I. ; run;
 %end; 
%mend;

*insert the total number of counties into &n_counties macro variable;
proc sql noprint;
 select count(*) into :n_counties from cluster_std
;quit;run;
%put n_counties= &n_counties ;

*Find all possible numbers of groupings (Ks) that evenly divide the total number of counties.
 We want at least 3 groups of counties and the largest possible number of groups should contain 
 at least 3 counties each. Need to do this in case the total number of counties is not evenly divisible.;
data factors(where=(k ge 3 and k le &n_counties /3 ));
 do k=1 to &n_counties ;
  if mod(&n_counties ,k)= 0 then do;
   n_counties=&n_counties /k;
   output;
  end; 
 end;
run; 

*find the min and max number of groupings (Ks) from the possible range for input to the macro 
 that selects ks;
proc sql noprint;
 select min(k) into :min_k from factors;
 select max(k) into :max_k from factors;
;quit;run;
%put min_k= &min_k;
%put max_k= &max_k;

*delete the file of appended stats from previous executions;
proc delete data=describe_ks ; run;

*execute the macro using the found kmin and kmax;
%kmean(&min_k., &max_k.);

*sort the resulting stats;
proc sort data=describe_ks; by n_counties_w_sb k_clstrs; run;

* Look for Pseudo F and CCC to increase to a local maximum as k clusters increases. 
  Observe when the stat starts to decrease. Take the number of clusters at that local maximum. 
  Look for consensus in local peaks of CCC and Pseudo-F statistic.;
* Look for ERSQ to increase to a local maximum and then starts falling or plateau.
  Take the number of clusters at that local maximum. Not as reliable as Pseudo F and CCC;

*transpose the stats to get one row per grouping size k and save dataset for reference;
proc transpose data=describe_ks out=sas.describe_ks (drop=_name_ _label_) ;
 by n_counties_w_sb k_clstrs ;
 id _type_;
run;  

*create list of similar counties with similarity metrics;
proc sql;
 create table county_similarity as
 select * from
 (select distinct fips_st_cnty, st_cnty_nm, st_abbr, 
   
   /*how many groups (Ks) with SB the county shows up in, higher is more similar to SB*/
   count(distinct put(cluster,8.0)||put(k_clstrs,8.0)) as ks, 
   
   /*the mean size of the groups (Ks) with SB the county shows up in, smaller is more similar to SB*/
   sum(n_counties_w_sb)/count(distinct put(cluster,8.0)||put(k_clstrs,8.0)) as mean_k_size, 
   
   /*the mean distance of the county to the seed obs in each group with SB, closer is more similar to the mean of the group*/
   sum(distance)/count(distinct put(cluster,8.0)||put(k_clstrs,8.0)) as mean_distance, 
   
   /*whether anything was ever imputed, if true then lower quality information*/
   max(_impute_) as impute_flag 
  
  from list_sb_ks
  group by fips_st_cnty, st_cnty_nm, st_abbr
 )
 /*sort by similarity to SB*/
 order by ks desc, mean_k_size, mean_distance, impute_flag
;quit;run;

*add similarity rank according to sort key;
proc sql;
 create table sas.county_similarity as
 select monotonic() as sb_similar_rank, * from county_similarity 
;quit;run;

*output top 100 similar counties;
ods html body='/home/maguirejonathan/physician_supply/output/p23_sb_similar_counties.html' style=HTMLBlue;
proc sql;
 select * from 
 (
 select 
  a.sb_similar_rank as 'SB Similarity Rank'n,
  a.fips_st_cnty as 'County FIPS Code'n, 
  a.st_cnty_nm as 'County Name'n,
  a.st_abbr as 'State'n, 
  a.ks as 'Clusters with SB'n,
  a.mean_k_size as 'Mean Cluster Size'n format=32.1, 
  a.mean_distance as 'Mean Distance from Seed'n format=16.1,
  b.popn as 'County Pop 2020'n format=comma32.0,
  b.cbsa_ind_cd_msa as 'MSA Indicator'n format=percent8.1,
  b.cbsa_status_central as 'Central County Indicator'n format=percent8.1,
  b.rur_urb_cntm_cd_02 as 'Metro Area 250k-1M Indicator'n format=percent8.1,
  b.urb_infl_cd_2 as 'Small Metro <1M Indicator'n format=percent8.1,
  b.pct_ovr64 as '% Over 64'n format=percent8.1,
  b.pct_female as '% Female'n format=percent8.1,
  b.pct_wht_non_hisp as '% White Non-Hisp'n format=percent8.1,
  b.pct_cvln_lbr_frc_ovr15 as '% >15 in Labor Force'n format=percent8.1,
  b.prsnl_income as 'Personal Income'n format=dollar32.0,
  b.pct_in_pvrty as '% in Poverty'n format=percent8.1,
  b.hsptl_beds_per_1k as 'Hospital Beds per 1k'n format=32.1
 from sas.county_similarity a
 left join sas.selected_counties b
 on a.fips_st_cnty=b.fips_st_cnty 
 where a.sb_similar_rank le 101

 union
 select distinct
  0 as 'SB Similarity Rank'n,
  '00000' as 'County FIPS Code'n, 
  'Mean Top 100 Similar Counties' as 'County Name'n,
  'XX' as 'State'n, 
  sum(a.ks)/100 as 'Clusters with SB'n format=32.1,
  sum(a.mean_k_size)/100 as 'Mean Cluster Size'n format=32.1, 
  sum(a.mean_distance)/100 as 'Mean Distance from Seed'n format=16.1,
  sum(b.popn)/100 as 'County Pop 2020'n format=comma32.0,
  sum(b.cbsa_ind_cd_msa)/100 as 'MSA Indicator'n format=percent8.1,
  sum(b.cbsa_status_central)/100 as 'Central County Indicator'n format=percent8.1,
  sum(b.rur_urb_cntm_cd_02)/100 as 'Metro Area 250k-1M Indicator'n format=percent8.1,
  sum(b.urb_infl_cd_2)/100 as 'Small Metro <1M Indicator'n format=percent8.1,
  sum(b.pct_ovr64)/100 as '% Over 64'n format=percent8.1,
  sum(b.pct_female)/100 as '% Female'n format=percent8.1,
  sum(b.pct_wht_non_hisp)/100 as '% White Non-Hisp'n format=percent8.1,
  sum(b.pct_cvln_lbr_frc_ovr15)/100 as '% >15 in Labor Force'n format=percent8.1,
  sum(b.prsnl_income)/100 as 'Personal Income'n format=dollar32.0,
  sum(b.pct_in_pvrty)/100 as '% in Poverty'n format=percent8.1,
  sum(b.hsptl_beds_per_1k)/100 as 'Hospital Beds per 1k'n format=32.1
 from sas.county_similarity a
 left join sas.selected_counties b
 on a.fips_st_cnty=b.fips_st_cnty 
 where a.sb_similar_rank between 2 and 101
 
 union
 select distinct
  0 as 'SB Similarity Rank'n,
  '00000' as 'County FIPS Code'n, 
  'Mean Not Similar Counties' as 'County Name'n,
  'XX' as 'State'n, 
  0 as 'Clusters with SB'n format=32.1,
  0 as 'Mean Cluster Size'n format=32.1, 
  0 as 'Mean Distance from Seed'n format=16.1,
  sum(b.popn)/count(distinct b.fips_st_cnty) as 'County Pop 2020'n format=comma32.0,
  sum(b.cbsa_ind_cd_msa)/count(distinct b.fips_st_cnty) as 'MSA Indicator'n  format=percent8.1,
  sum(b.cbsa_status_central)/count(distinct b.fips_st_cnty) as 'Central County Indicator'n format=percent8.1,
  sum(b.rur_urb_cntm_cd_02)/count(distinct b.fips_st_cnty) as 'Metro Area 250k-1M Indicator'n format=percent8.1,
  sum(b.urb_infl_cd_2)/count(distinct b.fips_st_cnty)  as 'Small Metro <1M Indicator'n format=percent8.1,
  sum(b.pct_ovr64)/count(distinct b.fips_st_cnty)  as '% Over 64'n format=percent8.1,
  sum(b.pct_female)/count(distinct b.fips_st_cnty)  as '% Female'n format=percent8.1,
  sum(b.pct_wht_non_hisp)/count(distinct b.fips_st_cnty)  as '% White Non-Hisp'n format=percent8.1,
  sum(b.pct_cvln_lbr_frc_ovr15)/count(distinct b.fips_st_cnty)  as '% >15 in Labor Force'n format=percent8.1,
  sum(b.prsnl_income)/count(distinct b.fips_st_cnty)  as 'Personal Income'n format=dollar32.0,
  sum(b.pct_in_pvrty)/count(distinct b.fips_st_cnty)  as '% in Poverty'n format=percent8.1,
  sum(b.hsptl_beds_per_1k)/count(distinct b.fips_st_cnty)  as 'Hospital Beds per 1k'n format=32.1
 from sas.selected_counties b
 where b.fips_st_cnty not in (select distinct fips_st_cnty from sas.county_similarity)
 or b.fips_st_cnty in (select distinct fips_st_cnty from sas.county_similarity where sb_similar_rank gt 101)
 )
 order by 'SB Similarity Rank'n
;quit;run;
ods html close;
ods listing;
