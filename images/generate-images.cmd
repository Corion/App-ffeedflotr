@echo off
cd /d %~dp0/..

perl -w bin\ffeedflotr.pl t\cpantesters.txt -o images\simple-plot-CPAN-Testers.png

perl -w bin\ffeedflotr.pl t\cpantesters.txt --time -o images\simple-plot-time-CPAN-Testers.png

perl -w bin\ffeedflotr.pl t\cpantesters.txt --time --fill -o images\simple-plot-filled-CPAN-Testers.png
perl -w bin\ffeedflotr.pl t\cpantesters.txt --time --fill --xlabel "CPAN Test Results" -o images\simple-plot-label-CPAN-Testers.png

perl -w bin\ffeedflotr.pl t\stats1.txt --time --sep=, --fill -o images\multi-plot-CPAN-Testers-time-long.png
perl -w bin\ffeedflotr.pl t\stats1.txt --time --sep=, --xlen 48 --fill -o images\multi-plot-CPAN-Testers-time-short.png

perl -w bin\ffeedflotr.pl t\stats1.txt --time --sep=, --xlen 48 --fill --legend 1=Uploads --legend 2=Reports --legend 3=Pass --legend 4=Fail -o images\multi-plot-CPAN-Testers-time-legend.png
