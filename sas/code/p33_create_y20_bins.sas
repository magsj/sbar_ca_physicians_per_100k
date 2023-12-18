*make 20 equally sized bins for each of the three variables of interest;
proc sql noprint;
 select distinct 
  /*need the mins for each variable*/
  min(mds_dos_per_1k), min(mds_gp_per_1k), min(mds_spec_per_1k),   
   
  /*bin size is the difference between max and min*/
  (max(mds_dos_per_1k)-min(mds_dos_per_1k))/20, 
  (max(mds_gp_per_1k)-min(mds_gp_per_1k))/20, 
  (max(mds_spec_per_1k)-min(mds_spec_per_1k))/20 
   
 /*put the values in macro variables*/
 into 
  :mddo_bmn , :gp_bmn , :spec_bmn ,
  :mddo_bsz , :gp_bsz , :spec_bsz 
  
 /*use all data (no subsets) to create bins*/
 from cnty_smlr_all_ ;

;quit;run;  

*generate a dataset for total MDs/DOs with one row per bin with the bin index, description and size. 
 need to get the 21st bin since the obs with the max value will jump to that bin. we'll collapse it
 back to the 20th bin later;
%put mddo_bmn= &mddo_bmn ;
%put mddo_bsz= &mddo_bsz ;
data mddo_binct(keep=bin bin_desc binsize);
 binsize=&mddo_bsz ;
 do i=1 to 21;
  bin=i-1;
  bin_desc=
   strip( put( %sysevalf(&mddo_bmn.) + ((i-1) * %sysevalf(&mddo_bsz.)),8.2 ) ) 
   || ' - ' ||
   strip( put( %sysevalf(&mddo_bmn.) + (i     * %sysevalf(&mddo_bsz.)),8.2 ) ) ;
   if bin=20 then do;
    bin_desc=
     strip( put( %sysevalf(&mddo_bmn.) + ((i-2) * %sysevalf(&mddo_bsz.)),8.2 ) ) 
     || ' - ' ||
     strip( put( %sysevalf(&mddo_bmn.) + ((i-1) * %sysevalf(&mddo_bsz.)),8.2 ) ) ;
   end;
  output;
 end;
run;

*generate a dataset for GPs with one row per bin with the bin index, description and size. 
 need to get the 21st bin since the obs with the max value will jump to that bin. we'll collapse it
 back to the 20th bin later;
%put gp_bmn= &gp_bmn ;
%put gp_bsz= &gp_bsz ;
data gp_binct(keep=bin bin_desc binsize);
 binsize=&gp_bsz ;
 do i=1 to 21;
  bin=i-1;
  bin_desc=
   strip( put( %sysevalf(&gp_bmn.) + ((i-1) * %sysevalf(&gp_bsz.)),8.2 ) ) 
   || ' - ' ||
   strip( put( %sysevalf(&gp_bmn.) + (i     * %sysevalf(&gp_bsz.)),8.2 ) ) ;
   if bin=20 then do;
    bin_desc=
     strip( put( %sysevalf(&gp_bmn.) + ((i-2) * %sysevalf(&gp_bsz.)),8.2 ) ) 
     || ' - ' ||
     strip( put( %sysevalf(&gp_bmn.) + ((i-1) * %sysevalf(&gp_bsz.)),8.2 ) ) ;
   end;
  output;
 end;
run;

*generate a dataset for specialists with one row per bin with the bin index, description and size. 
 need to get the 21st bin since the obs with the max value will jump to that bin. we'll collapse it
 back to the 20th bin later;
%put spec_bmn= &spec_bmn ;
%put spec_bsz= &spec_bsz ;
data spec_binct(keep=bin bin_desc binsize);
 binsize=&spec_bsz ;
 do i=1 to 21;
  bin=i-1;
  bin_desc=
   strip( put( %sysevalf(&spec_bmn.) + ((i-1) * %sysevalf(&spec_bsz.)),8.2 ) ) 
   || ' - ' ||
   strip( put( %sysevalf(&spec_bmn.) + (i     * %sysevalf(&spec_bsz.)),8.2 ) ) ;
   if bin=20 then do;
    bin_desc=
     strip( put( %sysevalf(&spec_bmn.) + ((i-2) * %sysevalf(&spec_bsz.)),8.2 ) ) 
     || ' - ' ||
     strip( put( %sysevalf(&spec_bmn.) + ((i-1) * %sysevalf(&spec_bsz.)),8.2 ) ) ;
   end;
  output;
 end;
run;

*loop through all the permutations of variables, geography and subsets to put counts of counties into the bins;
%macro bins(var,varabbr,ca_whr,geo,subset);
 proc sql noprint;
  create table &varabbr._&geo._&subset._bins as
  select distinct 
   /*collapses the obs with the max value back down into the 20th bin*/
   case when a.bin=20 then 19 else a.bin end as bin, 
   a.bin_desc, 
   "&var." as var,
   "&geo." as geo,
   "&subset." as sb_similar_ind,
   max(case when st_cnty_nm='Santa Barbara, CA' then 1 else 0 end) as sb_ind,
   count(distinct fips_st_cnty) as n
  from &varabbr._binct a
  full join cnty_smlr_&subset (where=( &ca_whr )) b
  on a.bin = floor(b.&var./a.binsize) 
  group by 1, 2
 ;quit;run; 

 /*append each interation to a permanebt dataset*/
 proc append base=phys_per1k_bins data=&varabbr._&geo._&subset._bins force; run;
 
 /*delete each temp dataset per iteration*/
 proc delete data=&varabbr._&geo._&subset._bins ; run;
%mend;

*delete any the permanent file if it exists from a previous execution;
proc delete data=phys_per1k_bins; run;

*execute the bins macro over all needed permutations: bins(var,varabbr,ca_whr,geo,subset);

%bins(mds_dos_per_1k,mddo,%str(1=1),US,all_);
%bins(mds_dos_per_1k,mddo,%str(ca_cnty='Y'),CA,all_);
%bins(mds_dos_per_1k,mddo,%str(1=1),US,type);
%bins(mds_dos_per_1k,mddo,%str(1=1),US,t_25);
%bins(mds_dos_per_1k,mddo,%str(1=1),US,t_50);
%bins(mds_dos_per_1k,mddo,%str(1=1),US,t100);

%bins(mds_gp_per_1k,gp,%str(1=1),US,all_);
%bins(mds_gp_per_1k,gp,%str(ca_cnty='Y'),CA,all_);
%bins(mds_gp_per_1k,gp,%str(1=1),US,type);
%bins(mds_gp_per_1k,gp,%str(1=1),US,t_25);
%bins(mds_gp_per_1k,gp,%str(1=1),US,t_50);
%bins(mds_gp_per_1k,gp,%str(1=1),US,t100);

%bins(mds_spec_per_1k,spec,%str(1=1),US,all_);
%bins(mds_spec_per_1k,spec,%str(ca_cnty='Y'),CA,all_);
%bins(mds_spec_per_1k,spec,%str(1=1),US,type);
%bins(mds_spec_per_1k,spec,%str(1=1),US,t_25);
%bins(mds_spec_per_1k,spec,%str(1=1),US,t_50);
%bins(mds_spec_per_1k,spec,%str(1=1),US,t100);

