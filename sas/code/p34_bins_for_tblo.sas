*create metadata labels for the summary stats to be used in tableau;
proc sql;
 create table sas.phys_per1k_bins (where=(Subset ne 'REMOVE')) as
 
 select 
  case when sb_similar_ind='all_' and geo='US' then 'All US Counties'
       when sb_similar_ind='all_' and geo='CA' then 'All CA Counties'
       when sb_similar_ind='type' and geo='US' then 'Central MSA US Counties of 250k-1M'
       when sb_similar_ind='t_25' and geo='US' then 'Top 25 Most Similar US Counties'
       when sb_similar_ind='t_50' and geo='US' then 'Top 50 Most Similar US Counties'
       when sb_similar_ind='t100' and geo='US' then 'Top 100 Most Similar US Counties'
       else 'REMOVE' end as Subset length=35,
  
  case when var like 'mds_dos%' then 'MDs/DOs Per 100k'
       when var like 'mds_gp%' then 'MD GPs Per 100k'
       when var like 'mds_spec%' then 'MD Specialists Per 100k'
       else '' end as Measure length=25,
       
  bin as 'Bin Index'n, 
  bin_desc as 'Bin'n,
  case when sb_ind=1 then 'Bin with SB' else 'Bin without SB' end as 'Santa Barbara'n length=15,
  n as 'N Counties'n
  
 from phys_per1k_bins
 order by 1,2,3
;quit;run;

*output the permanent file to pipe delimited text for consumption by tableau.;
proc export 
 data=sas.phys_per1k_bins  
 outfile='/home/maguirejonathan/physician_supply/output/p34_phys_per1k_bins_tblo.txt'
 dbms=dlm replace;
 delimiter='|';
run;

 
