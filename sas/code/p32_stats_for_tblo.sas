*transpose stats output data so that all the stats are in one column called Value;
proc transpose 
 data=sas.physicians_per_1k_smry (where=(st_abbr in ('CA','US')))
 out=physicians_per_1k_tblo (rename=(col1=Value));
 by st_abbr	sb_similar_ind;
run;

*create metadata labels for the summary stats to be used for both x and y axes in tableau;
proc sql;
 create table physicians_per_1k_tblo (where=(Subset ne 'REMOVE')) as
 
 select 
  case when sb_similar_ind='ALL_' and st_abbr='US' then 'All US Counties'
       when sb_similar_ind='ALL_' and st_abbr='CA' then 'All CA Counties'
       when sb_similar_ind='TYPE' and st_abbr='US' then 'Central MSA US Counties of 250k-1M'
       when sb_similar_ind='T_25' and st_abbr='US' then 'Top 25 Most Similar US Counties'
       when sb_similar_ind='T_50' and st_abbr='US' then 'Top 50 Most Similar US Counties'
       when sb_similar_ind='T100' and st_abbr='US' then 'Top 100 Most Similar US Counties'
       else 'REMOVE' end as Subset length=35,

  case when substr(_name_,1,6)='mds_do' then 'MDs/DOs Per 1,000'
       when substr(_name_,1,6)='mds_gp' then 'MD GPs Per 1,000'
       when substr(_name_,1,6)='mds_sp' then 'MD Specialists Per 1,000'
       else '' end as Measure length=25,
       
  case when substr(_name_,length(_name_),1)='N' then 'N'
       when substr(_name_,length(_name_)-3,4)='Mean' then 'Mean'
       when substr(_name_,length(_name_)-5,6)='StdDev' then 'StdDev'
       when substr(_name_,length(_name_)-2,3)='Min' then 'Min'
       when substr(_name_,length(_name_)-1,2)='P1' then 'P01'
       when substr(_name_,length(_name_)-1,2)='P5' then 'P05'
       when substr(_name_,length(_name_)-2,3)='P10' then 'P10'
       when substr(_name_,length(_name_)-2,3)='P25' then 'P25'
       when substr(_name_,length(_name_)-2,3)='P40' then 'P40'
       when substr(_name_,length(_name_)-2,3)='P50' then 'Median'
       when substr(_name_,length(_name_)-2,3)='P60' then 'P60'
       when substr(_name_,length(_name_)-2,3)='P75' then 'P75'
       when substr(_name_,length(_name_)-2,3)='P90' then 'P90'
       when substr(_name_,length(_name_)-2,3)='P95' then 'P95'
       when substr(_name_,length(_name_)-2,3)='P99' then 'P99'
       when substr(_name_,length(_name_)-2,3)='Max' then 'Max'
       else '' end as Statistic length=25,
  
  case when substr(_name_,length(_name_),1)='N' then 'Smry'
       when substr(_name_,length(_name_)-3,4)='Mean' then 'Mean'
       when substr(_name_,length(_name_)-5,6)='StdDev' then 'Smry'
       when substr(_name_,length(_name_)-2,3)='Min' then 'Extr'
       when substr(_name_,length(_name_)-1,2)='P1' then 'Ptile'
       when substr(_name_,length(_name_)-1,2)='P5' then 'Ptile'
       when substr(_name_,length(_name_)-2,3)='P10' then 'Ptile'
       when substr(_name_,length(_name_)-2,3)='P25' then 'IQR'
       when substr(_name_,length(_name_)-2,3)='P40' then 'Ptile'
       when substr(_name_,length(_name_)-2,3)='P50' then 'IQR'
       when substr(_name_,length(_name_)-2,3)='P60' then 'Ptile'
       when substr(_name_,length(_name_)-2,3)='P75' then 'IQR'
       when substr(_name_,length(_name_)-2,3)='P90' then 'Ptile'
       when substr(_name_,length(_name_)-2,3)='P95' then 'Ptile'
       when substr(_name_,length(_name_)-2,3)='P99' then 'Ptile'
       when substr(_name_,length(_name_)-2,3)='Max' then 'Extr'
       else '' end as Highlight length=25,
       
  Value
  
 from physicians_per_1k_tblo  
 where _name_ ne 'st_county_ct'
 order by Subset, Measure, case when Highlight='Smry' then 0 else 1 end, Value
;quit;run;

*transpose SB percentiles data so that those stats are in one column called Value;
proc transpose 
 data=sas.physicians_per_1k_sb
 out=physicians_per_1k_sb (rename=(col1=Value) drop=_label_);
 by st_abbr	sb_similar_ind;
run;

*create metadata labels for the SB percentiles data to be embedded in the Statistic label;
proc sql;
 create table physicians_per_1k_sbm (where=(Subset ne 'REMOVE')) as
 select 
  case when sb_similar_ind='ALL_' and substr(_name_,length(_name_)-7,8)='us_ptile' then 'All US Counties'
       when sb_similar_ind='ALL_' and substr(_name_,length(_name_)-7,8)='st_ptile' then 'All CA Counties'
       when sb_similar_ind='TYPE' and substr(_name_,length(_name_)-7,8)='us_ptile' then 'Central MSA US Counties of 250k-1M'
       when sb_similar_ind='T_25' and substr(_name_,length(_name_)-7,8)='us_ptile' then 'Top 25 Most Similar US Counties'
       when sb_similar_ind='T_50' and substr(_name_,length(_name_)-7,8)='us_ptile' then 'Top 50 Most Similar US Counties'
       when sb_similar_ind='T100' and substr(_name_,length(_name_)-7,8)='us_ptile' then 'Top 100 Most Similar US Counties'
       else 'REMOVE' end as Subset length=35,

  case when substr(_name_,1,6)='mds_do' then 'MDs/DOs Per 1,000'
       when substr(_name_,1,6)='mds_gp' then 'MD GPs Per 1,000'
       when substr(_name_,1,6)='mds_sp' then 'MD Specialists Per 1,000'
       else '' end as Measure length=25,

  /*embed SB's percentile in the Statistic label for visibility in tableau*/
  'Santa Barbara (P'||compress(put(round(Value),16.0))||')' as Statistic length=25,

  'SB' as Highlight

 from physicians_per_1k_sb 
 /*where substr(_name_,length(_name_)-1,2)='1k'*/ 
 where substr(_name_,length(_name_)-4,5)='ptile' 

 order by Subset, Measure
;quit;run;

*create values of the SB percentiles data;
proc sql;
 create table physicians_per_1k_sbv (where=(Subset ne 'REMOVE')) as
 select 
  case when sb_similar_ind='ALL_' and st_abbr='US' then 'All US Counties'
       when sb_similar_ind='ALL_' and st_abbr='CA' then 'All CA Counties'
       when sb_similar_ind='TYPE' and st_abbr='US' then 'Central MSA US Counties of 250k-1M'
       when sb_similar_ind='T_25' and st_abbr='US' then 'Top 25 Most Similar US Counties'
       when sb_similar_ind='T_50' and st_abbr='US' then 'Top 50 Most Similar US Counties'
       when sb_similar_ind='T100' and st_abbr='US' then 'Top 100 Most Similar US Counties'
       else 'REMOVE' end as Subset length=35,

  case when _name_='mds_dos_per_1k' then 'MDs/DOs Per 1,000'
       when _name_='mds_gp_per_1k' then 'MD GPs Per 1,000'
       when _name_='mds_spec_per_1k' then 'MD Specialists Per 1,000'
       else '' end as Measure length=25,

  'SB' as Highlight,
  
  Value

 from physicians_per_1k_sb 
 where substr(_name_,length(_name_)-1,2)='1k'

 order by Subset, Measure
;quit;run;

*bring both SB percentile datasets together and add or subtract a miniscule 
 to/from the value to ensure there are no conflicts with summary stats;
proc sql;
 create table physicians_per_1k_sb as
 select a.*, 
  case when substr(a.Statistic,17,2) < '50' then b.Value + .000001
       when substr(a.Statistic,17,2) >= '50' then b.Value - .000001
       else . end as Value
 from physicians_per_1k_sbm a
 left outer join physicians_per_1k_sbv b 
 on a.Measure=b.Measure 
 order by a.Subset, a.Measure
;quit;run;

*set the tableau-formatted summary stats together with the tableau-formatted SB percentiles 
 for a permanent dataset.;
proc sql;
 create table sas.phys_per1k_stats_tblo as
 select * from 
 (select * from physicians_per_1k_tblo
  union 
  select * from physicians_per_1k_sb)
 order by Subset, Measure, case when Highlight='Smry' then 0 else 1 end, Value
;quit;run;

*output the file to pipe delimited text for consumption by tableau.;
proc export 
 data=sas.phys_per1k_stats_tblo 
 outfile='/home/maguirejonathan/physician_supply/output/p32_phys_per1k_stats_tblo.txt'
 dbms=dlm replace;
 delimiter='|';
run;
