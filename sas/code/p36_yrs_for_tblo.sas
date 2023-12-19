*transpose stats output data so that all the stats are in one column called Value;
proc transpose 
 data=sas.phys_per1k_yrs
 out=phys_per1k_yrs_tblo (rename=(col1=Value));
 by sb_similar_ind year st_county_ct;
run;

*add the slopes and intercept data to have it on hand at the annual level;
proc sql;
 create table phys_per1k_yrs_tblo as
 select a.*, b.intercept as 'Intercept'n, b.year as 'Slope'n
 from phys_per1k_yrs_tblo a
 left join phys_per1k_yrs_slopes b
 on a._name_=b._depvar_
 and a.sb_similar_ind=b.sb_similar_ind 
;quit;run;

*create metadata labels for the summary stats to be used in tableau;
proc sql;
 create table sas.phys_per1k_yrs_tblo (where=(Subset ne 'REMOVE')) as
 
 select 
  case when sb_similar_ind='ALUS' 
       then 'All US Counties (n='||strip(put(st_county_ct,comma32.0))
                        ||') (slope='||strip(put(Slope,percentn32.2))||')'
                          
       when sb_similar_ind='ALCA' 
       then 'All CA Counties (n='||strip(put(st_county_ct,comma32.0))
                        ||') (slope='||strip(put(Slope,percentn32.2))||')'
                          
       when sb_similar_ind='TYPE' 
       then 'Central MSA US Counties of 250k-1M (n='||strip(put(st_county_ct,comma32.0))
                                           ||') (slope='||strip(put(Slope,percentn32.2))||')'
                          
       when sb_similar_ind='T_25' 
       then 'Top 25 Most Similar US Counties (n='||strip(put(st_county_ct,comma32.0))
                                        ||') (slope='||strip(put(Slope,percentn32.2))||')'
                          
       when sb_similar_ind='T_50' 
       then 'Top 50 Most Similar US Counties (n='||strip(put(st_county_ct,comma32.0))
                                        ||') (slope='||strip(put(Slope,percentn32.2))||')'
                          
       when sb_similar_ind='T100' 
       then 'Top 100 Most Similar US Counties (n='||strip(put(st_county_ct,comma32.0))
                                         ||') (slope='||strip(put(Slope,percentn32.2))||')'
                                         
       when sb_similar_ind='SBCA' 
       then 'Santa Barbara County (n='||strip(put(st_county_ct,comma32.0))
                             ||') (slope='||strip(put(Slope,percentn32.2))||')'
                          
       else 'REMOVE' end as Subset length=75,

  case when substr(_name_,1,6)='mds_do' then 'MDs/DOs Per 1,000'
       when substr(_name_,1,6)='mds_gp' then 'MD GPs Per 1,000'
       when substr(_name_,1,6)='mds_sp' then 'MD Specialists Per 1,000'
       else '' end as Measure length=25,
       
  year as 'Year'n,            
  Value,
  Intercept,
  Slope,
  st_county_ct as N
  
 from phys_per1k_yrs_tblo 
 order by Subset, Measure, Year
;quit;run;

*output the permanent annual file to pipe delimited text for consumption by tableau.;
proc export 
 data=sas.phys_per1k_yrs_tblo  
 outfile='/home/maguirejonathan/physician_supply/output/p36_phys_per1k_yrs_tblo.txt'
 dbms=dlm replace;
 delimiter='|';
run;

*create a permanent summary file with just slopes, etc.;
proc sql;
 create table sas.phys_per1k_yrs_slopes_tblo as 
 select distinct Subset, Measure, Intercept, Slope, N
 from sas.phys_per1k_yrs_tblo 
;quit;run; 

*output the permanent slopes file to pipe delimited text for consumption by tableau.;
proc export 
 data=sas.phys_per1k_yrs_slopes_tblo   
 outfile='/home/maguirejonathan/physician_supply/output/p36_phys_per1k_yrs_slopes_tblo.txt'
 dbms=dlm replace;
 delimiter='|';
run;
