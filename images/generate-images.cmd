@echo off
cd /d %~dp0/..

perl -w bin\ffeedflotr.pl t\cpantesters.txt --width 870 --height 320 -o images\simple-plot-CPAN-Testers.png

perl -w bin\ffeedflotr.pl t\cpantesters.txt --width 870 --height 320 --time -o images\simple-plot-time-CPAN-Testers.png

perl -w bin\ffeedflotr.pl t\cpantesters.txt --width 870 --height 320  --time --fill -o images\simple-plot-filled-CPAN-Testers.png
perl -w bin\ffeedflotr.pl t\cpantesters.txt --width 870 --height 320  --time --fill --xlabel "CPAN Test Results" -o images\simple-plot-label-CPAN-Testers.png

perl -w bin\ffeedflotr.pl t\stats1.txt --width 870 --height 320 --time --sep=, --fill -o images\multi-plot-CPAN-Testers-time-long.png
perl -w bin\ffeedflotr.pl t\stats1.txt --width 870 --height 320 --time --sep=, --xlen 48 --fill -o images\multi-plot-CPAN-Testers-time-short.png

perl -w bin\ffeedflotr.pl t\stats1.txt  --width 870 --height 320 --time --sep=, --xlen 48 --fill --legend 1=Uploads --legend 2=Reports --legend 3=Pass --legend 4=Fail -o images\multi-plot-CPAN-Testers-time-legend.png
perl -w bin\ffeedflotr.pl t\stats1.txt --width 870 --height 320 --time --sep=, --xlen 48 --fill --legend 1=Uploads --legend 2=Reports --legend 3=Pass --legend 4=Fail --color 3=green --color 4=red -o images\multi-plot-CPAN-Testers-color.png

perl -w bin\ffeedflotr.pl t\stats1.txt --width 870 --height 320 --time --sep=, --xlen 1 --fill --legend 1=Uploads --legend 2=Reports --legend 3=Pass --legend 4=Fail --color 3=green --color 4=red -o images\CPAN-Testers-pie.png
