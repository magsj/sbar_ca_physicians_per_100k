/* Adapted from sas/code/p33_create_y20_bins.sas (magsj/sbar_ca_physicians_per_100k)
   The original computes 20 equal-width bins for each rate-per-100k measure
   (min/max via PROC SQL INTO, bin size = range/20), builds a small lookup
   dataset per measure describing each bin's numeric range as a label string
   (with a deliberate 21st bin to catch the max-value observation, which is
   then collapsed back into bin 20), and finally a %bins macro that assigns
   every county to a bin and counts counties per bin -- looped over several
   geography/similarity subsets. This produces the histogram data that feeds
   the Tableau workbook checked into tblo/.

   Substitution applied: cnty_smlr_all_ is a 10-county mock table (matching
   the shape produced by p31's %top macro) instead of a persisted WORK
   dataset from the full pipeline. The bin-boundary DATA step, the %bins
   macro body, and the SQL used to assign counties to bins are unedited
   from the source; only the mds_dos measure and two subsets (all US
   counties; CA counties only) are run, instead of all three measures across
   six subsets. */

data cnty_smlr_all_;
   input fips_st_cnty $ st_abbr $ mds_dos_per_100k ca_cnty $;
   datalines;
06083 CA 91.4 Y
06073 CA 155.2 Y
06037 CA 128.3 Y
06001 CA 158.6 Y
41051 OR 242.8 N
32003 NV 141.7 N
06111 CA 105.5 Y
06079 CA 183.7 Y
17031 IL 176.2 N
48201 TX 121.5 N
;
run;

*make 20 equally sized bins for mds_dos_per_100k;
proc sql noprint;
 select distinct
  min(mds_dos_per_100k),
  (max(mds_dos_per_100k)-min(mds_dos_per_100k))/20

 into
  :mddo_bmn ,
  :mddo_bsz

 from cnty_smlr_all_ ;

;quit;run;

%put mddo_bmn= &mddo_bmn ;
%put mddo_bsz= &mddo_bsz ;

*generate a dataset for total MDs/DOs with one row per bin with the bin index, description and size.
 need to get the 21st bin since the obs with the max value will jump to that bin. we'll collapse it
 back to the 20th bin later;
data mddo_binct(keep=bin bin_desc binsize);
 binsize=&mddo_bsz ;
 do i=1 to 21;
  bin=i-1;
  bin_desc=
   strip( put( %sysevalf(&mddo_bmn.) + ((i-1) * %sysevalf(&mddo_bsz.)),8.1 ) )
   || ' - ' ||
   strip( put( %sysevalf(&mddo_bmn.) + (i     * %sysevalf(&mddo_bsz.)),8.1 ) ) ;
   if bin=20 then do;
    bin_desc=
     strip( put( %sysevalf(&mddo_bmn.) + ((i-2) * %sysevalf(&mddo_bsz.)),8.1 ) )
     || ' - ' ||
     strip( put( %sysevalf(&mddo_bmn.) + ((i-1) * %sysevalf(&mddo_bsz.)),8.1 ) ) ;
   end;
  output;
 end;
run;

*loop through the permutations of geography and subsets to put counts of counties into the bins;
%macro bins(var,varabbr,ca_whr,geo,subset);
 proc sql noprint;
  create table &varabbr._&geo._&subset._bins as
  select distinct
   /*collapses the obs with the max value back down into the 20th bin*/
   case when a.bin=20 then 19 else a.bin end as bin,
   a.bin_desc,
   "&var." as var,
   "&geo." as geo,
   max(case when fips_st_cnty='06083' then 1 else 0 end) as sb_ind,
   count(distinct fips_st_cnty) as n
  from &varabbr._binct a
  full join cnty_smlr_all_ (where=( &ca_whr )) b
  on a.bin = floor(b.&var./a.binsize)
  group by 1, 2
 ;quit;run;

 proc append base=phys_per1k_bins data=&varabbr._&geo._&subset._bins force; run;
 proc delete data=&varabbr._&geo._&subset._bins ; run;
%mend;

%bins(mds_dos_per_100k,mddo,%str(1=1),US,all_);
%bins(mds_dos_per_100k,mddo,%str(ca_cnty='Y'),CA,all_);

proc print data=phys_per1k_bins noobs;
 where n>0;
 var geo bin bin_desc n sb_ind;
 title "Non-empty physicians-per-100k bins, US vs CA-only subsets";
run;
