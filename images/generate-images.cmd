@echo off
cd /d %~dp0/..

setlocal
set PERL5LIB=lib;%PERL5LIB%
set MOZREPL_CLASS=

perl -w bin\ffeedflotr.pl t\cpantesters.txt --width 870 --height 320 -o images\simple-plot-CPAN-Testers.png

perl -w bin\ffeedflotr.pl t\cpantesters.txt --width 870 --height 320 --time -o images\simple-plot-time-CPAN-Testers.png

perl -w bin\ffeedflotr.pl t\cpantesters.txt --width 870 --height 320  --time --fill -o images\simple-plot-filled-CPAN-Testers.png
perl -w bin\ffeedflotr.pl t\cpantesters.txt --width 870 --height 320  --time --fill --xlabel "CPAN Test Results" -o images\simple-plot-label-CPAN-Testers.png

perl -w bin\ffeedflotr.pl t\stats1.txt --width 870 --height 320 --time --sep=, --fill -o images\multi-plot-CPAN-Testers-time-long.png
perl -w bin\ffeedflotr.pl t\stats1.txt --width 870 --height 320 --time --sep=, --xlen 48 --fill -o images\multi-plot-CPAN-Testers-time-short.png

perl -w bin\ffeedflotr.pl t\stats1.txt  --width 870 --height 320 --time --sep=, --xlen 48 --fill --legend 1=Uploads --legend 2=Reports --legend 3=Pass --legend 4=Fail -o images\multi-plot-CPAN-Testers-time-legend.png
perl -w bin\ffeedflotr.pl t\stats1.txt --width 870 --height 320 --time --sep=, --xlen 48 --fill --legend 1=Uploads --legend 2=Reports --legend 3=Pass --legend 4=Fail --color 3=green --color 4=red -o images\multi-plot-CPAN-Testers-color.png

perl -w bin\ffeedflotr.pl t\pie.txt --width 870 --height 320 --sep=, --type=pie --legend 1=Pass --color 1=green --legend 2=Fail --color 2=red --legend 3=Other -o images\CPAN-Testers-pie.png

perl -w bin\ffeedflotr.pl t\pacman.txt --width 870 --height 320 --sep=, --type=pie --legend "1=%% of Pie charts that look like Pacman" --color 1=yellow  --legend "2=%% of Pie charts that don't look like Pacman" --color 2=blue --legend 3=Other --pie-start-angle 0.25 -o images\Pacman-pie.png

perl -w bin\ffeedflotr.pl t\random-poissondisc-fail1.txt --type=scatter --xmax=100 --ymax=100 --width 870 --height 320 -o images\random-poissondisc-fail1.png

perl -w bin\ffeedflotr.pl t\random-poissondisc-better1.txt --type=scatter --xmax=100 --ymax=100 --width 870 --height 320 -o images\random-poissondisc-better1.png

pause