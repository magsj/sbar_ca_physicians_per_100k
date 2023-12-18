*transpose stats output data so that all the stats are in one column called Xaxis;
proc transpose 
 data=sas.physicians_per_1k_smry (where=(st_abbr in ('CA','US')))
 out=physicians_per_1k_tblo (rename=(col1=Xaxis));
 by st_abbr	sb_similar_ind;
run;

*create metadata labels for the summary stats to be used for both x and y axes in tableau;
proc sql;
 create table physicians_per_1k_tblo as
 
 select 
  case when st_abbr='CA' then 'California'
       when st_abbr='US' then 'USA'
       else '' end as Geography length=10,     

  case when sb_similar_ind='ALL_' then 'All Counties'
       when sb_similar_ind='TYPE' then 'Central MSA Counties of 250k-1M'
       when sb_similar_ind='T_25' then 'Top 25 Most Similar US Counties'
       when sb_similar_ind='T_50' then 'Top 50 Most Similar US Counties'
       when sb_similar_ind='T100' then 'Top 100 Most Similar US Counties'
       else sb_similar_ind end as Similarity length=35,
  
  case when substr(_name_,1,6)='mds_do' then 'MDs/DOs Per 1,000'
       when substr(_name_,1,6)='mds_gp' then 'MD GPs Per 1,000'
       when substr(_name_,1,6)='mds_sp' then 'MD Specialists Per 1,000'
       else '' end as Measure length=25,
       
  case when substr(_name_,length(_name_),1)='N' then 'N'
       when substr(_name_,length(_name_)-3,4)='Mean' then 'Mean'
       when substr(_name_,length(_name_)-5,6)='StdDev' then 'StdDev'
       when substr(_name_,length(_name_)-2,3)='Min' then 'Min'
       when substr(_name_,length(_name_)-1,2)='P1' then 'P1'
       when substr(_name_,length(_name_)-1,2)='P5' then 'P5'
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
  
  Xaxis,
  
  case when substr(_name_,length(_name_)-2,3)='Min' then 0
       when substr(_name_,length(_name_)-1,2)='P1' then .01
       when substr(_name_,length(_name_)-1,2)='P5' then .05
       when substr(_name_,length(_name_)-2,3)='P10' then .1
       when substr(_name_,length(_name_)-2,3)='P25' then .25
       when substr(_name_,length(_name_)-2,3)='P40' then .4
       when substr(_name_,length(_name_)-2,3)='P50' then .5
       when substr(_name_,length(_name_)-2,3)='P60' then .4
       when substr(_name_,length(_name_)-2,3)='P75' then .25
       when substr(_name_,length(_name_)-2,3)='P90' then .1
       when substr(_name_,length(_name_)-2,3)='P95' then .05
       when substr(_name_,length(_name_)-2,3)='P99' then .01
       when substr(_name_,length(_name_)-2,3)='Max' then 0
       else . end as Yaxis
       
 from physicians_per_1k_tblo  
 where _name_ ne 'st_county_ct'
 order by Geography, Similarity, Measure, Statistic
;quit;run;

*transpose SB percentiles data so that those stats are in one column called Xaxis;
proc transpose 
 data=sas.physicians_per_1k_sb
 out=physicians_per_1k_sb (rename=(col1=Xaxis) drop=_label_);
 by st_abbr	sb_similar_ind;
run;

*create metadata labels for the SB percentiles data to be used for the x-axis in tableau;
proc sql;
 create table physicians_per_1k_sbx as
 select 
  case when sb_similar_ind='ALL_' then 'All Counties'
       when sb_similar_ind='TYPE' then 'Central MSA Counties of 250k-1M'
       when sb_similar_ind='T_25' then 'Top 25 Most Similar US Counties'
       when sb_similar_ind='T_50' then 'Top 50 Most Similar US Counties'
       when sb_similar_ind='T100' then 'Top 100 Most Similar US Counties'
       else sb_similar_ind end as Similarity length=35,
       
  case when _name_='mds_dos_per_1k' then 'MDs/DOs Per 1,000'
       when _name_='mds_gp_per_1k' then 'MD GPs Per 1,000'
       when _name_='mds_spec_per_1k' then 'MD Specialists Per 1,000'
       else '' end as Measure length=25,
       
  Xaxis
  
 from physicians_per_1k_sb 
 where substr(_name_,length(_name_)-1,2)='1k' 
 order by Measure
;quit;run;

*create metadata labels for the SB percentiles data to be used for the y-axis in tableau;
proc sql;
 create table physicians_per_1k_sby as
 select 
  case when substr(_name_,length(_name_)-7,8)='st_ptile' then'California' 
       when substr(_name_,length(_name_)-7,8)='us_ptile' then'USA' 
       else '' end as Geography length=10,     
       
  case when sb_similar_ind='ALL_' then 'All Counties'
       when sb_similar_ind='TYPE' then 'Central MSA Counties of 250k-1M'
       when sb_similar_ind='T_25' then 'Top 25 Most Similar US Counties'
       when sb_similar_ind='T_50' then 'Top 50 Most Similar US Counties'
       when sb_similar_ind='T100' then 'Top 100 Most Similar US Counties'
       else sb_similar_ind end as Similarity length=35,
       
  case when substr(_name_,1,6)='mds_do' then 'MDs/DOs Per 1,000'
       when substr(_name_,1,6)='mds_gp' then 'MD GPs Per 1,000'
       when substr(_name_,1,6)='mds_sp' then 'MD Specialists Per 1,000'
       else '' end as Measure length=25,
  
  /*embed SB's percentile in the Statistic label for visibility in tableau*/
  'Santa Barbara (P'||compress(put(round(Xaxis),16.0))||')' as Statistic length=25,
  
  /*percentiles run from 0 to 1, but we want to achieve a probability distribution effect,
    so set the y axis values to the percentiles until the median and then after the median
    set them to one minus the percentile*/
  case when Xaxis/100 <= .5 then Xaxis/100 
       when Xaxis/100 > .5 then 1-(Xaxis/100)
       else . end as Yaxis
       
 from physicians_per_1k_sb 
 where substr(_name_,length(_name_)-4,5)='ptile' 
 order by Measure
;quit;run;

*bring both x and y axis SB percentile datasets together and add or subtract a miniscule 
 to/from the the x axis amount to ensure there are no visual conflicts with summary stats;
proc sql;
 create table physicians_per_1k_sb as
 select a.*, 
  case when substr(a.Statistic,17,2) < '50' then b.Xaxis + .000001
       when substr(a.Statistic,17,2) >= '50' then b.Xaxis - .000001
       else . end as Xaxis
 from physicians_per_1k_sby a
 left outer join physicians_per_1k_sbx b 
 on a.Measure=b.Measure 
 and a.Similarity=b.Similarity
 order by a.Geography, a.Similarity, a.Measure
;quit;run;

*set the tableau-formatted summary stats together with the tableau-formatted SB percentiles for a permanent dataset.;
*we need a duplicate set of SB percentiles, marked as highlight=Y, to add visual elements in tableau;
data sas.physicians_per_1k_tblo ;
 set 
  physicians_per_1k_tblo(in=a) 
  physicians_per_1k_sb(in=b) 
  physicians_per_1k_sb(in=c) ;
 if a or b then Highlight='N';
 else if c then Highlight='Y';
 by Geography Similarity Measure Statistic;
run;

*output the file to pipe delimited text for consumption by tableau.;
proc export 
 data=sas.physicians_per_1k_tblo 
 outfile='/home/maguirejonathan/physician_supply/output/p32_physicians_per_1k_tblo.txt'
 dbms=dlm replace;
 delimiter='|';
run;

 
