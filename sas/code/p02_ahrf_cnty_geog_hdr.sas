proc sql;

   create table ahrf.cnty_geog_hdr as 
   
   select
   
      F00002 as fips_st_cnty,               /*Header - FIPS St & Cty Code*/
      F00011 as fips_st,                    /*FIPS State Code*/
      F00012 as fips_cnty,                  /*FIPS County Code*/
      F04437 as st_cnty_nm,                 /*County Name w/State Abbrev*/
      F12424 as st_abbr,                    /*State Name Abbreviation*/
      F00010 as cnty_nm,                    /*County Name*/
      
      F0081176 as elev_ft,                  /*Elevation Feet*/
      F1406720 as cbsa_ind_cd,              /*CBSA Indicator Code*/
      F1419520 as cbsa_status,              /*CBSA County Status*/
      F0002013 as rur_urb_cntm_cd,          /*Rural-Urban Continuum Code*/
      F1255913 as urb_infl_cd,              /*Urban Influence Code*/
      F1397315 as ers_econ_typ_cd,          /*Economic-Dependnt Typology Code*/
      F1248115 as ers_farm_typ_cd,          /*Farming-Dependent Typology Code*/
      F1248215 as ers_mine_typ_cd,          /*Mining-Dependent Typology Code*/
      F1248315 as ers_manf_typ_cd,          /*Manufacturing-Dep Typology Code*/
      F1248415 as ers_govt_typ_cd,          /*Fed/St Govt-Depdnt Typolgy Code*/
      F1546915 as ers_recr_typ_cd,          /*Recreation Typolpgy Code*/
      F1248615 as ers_nonsp_typ_cd,         /*Nonspecializd-Dep Typology Code*/
      F1397515 as ers_low_ed_typ_cd,        /*Low Education Typology Code*/
      F1397615 as ers_low_emp_typ_cd,       /*Low Employment Typology Code*/
      F1533414 as ers_hi_pov_typ_cd,        /*High Poverty Typology Code*/
      F1249014 as ers_pers_pov_typ_cd,      /*Persistent Povrty Typology Code*/
      F1547015 as ers_pers_chld_pov_typ_cd, /*Persistent Child Pov Typol Code*/
      F1397715 as ers_pop_loss_typ_cd,      /*Population Loss Typology Code*/
      F1248715 as ers_retr_dest_typ_cd,     /*Retirement Destnatn Typlgy Code*/
      F1387420 as ttl_area_sqmi_y20,        /*Total Area in Square Miles*/
      F0972120 as lnd_area_sqmi_y20,        /*Land Area in Square Miles*/
      F1387520 as wtr_area_sqmi_y20,        /*Water Area in Square Miles*/
      F1387620 as pop_dnsty_per_sqmi_y20,   /*Population Density per Sq Mile*/
      F1387720 as hsng_dnsty_per_sqmi_y20   /*Housing Unit Density per Sq Mle*/
   
   from &ahrf_out
   
   where F12424 not in ('GU','PR','VI') /*keep only 50 states plus DC*/

;quit;run;
