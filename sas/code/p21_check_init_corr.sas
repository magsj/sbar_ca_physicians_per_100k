* create an output template to generate a correlation matrix with heat map coloring.;
* from https://support.sas.com/documentation/cdl/en/statug/63962/HTML/default/viewer.htm#statug_ods_sect019.htm;
proc template;
   edit Base.Corr.StackedMatrix;
      column (RowName RowLabel) (Matrix) * (Matrix2);
      edit matrix;
         cellstyle _val_  = -1.00 as {backgroundcolor=liggr},
                   _val_ <= -0.70 as {backgroundcolor=red},
                   _val_ <= -0.50 as {backgroundcolor=orange},
                   _val_ <= -0.30 as {backgroundcolor=yellow},
                   _val_ <=  0.30 as {backgroundcolor=lime},
                   _val_ <=  0.50 as {backgroundcolor=yellow},
                   _val_ <=  0.70 as {backgroundcolor=orange},
                   _val_ <   1.00 as {backgroundcolor=red},
                   _val_  =  1.00 as {backgroundcolor=liggr};
      end;
   end;
run;

* Correlation coefficients between predictor variables > 0.7 is a heuristic indicator for multicollinearity.;
ods html body='/home/maguirejonathan/physician_supply/output/p21_init_corr.html' style=HTMLBlue;
proc corr data=sas.selected_counties nomiss pearson ;
 ods select PearsonCorr;
 var &init_vars ;
run;
ods html close;

ods listing;
proc template;
 delete Base.Corr.StackedMatrix;
run;
