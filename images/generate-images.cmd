@echo off
cd /d %~dp0/..

perl -w bin\ffeedflotr.pl t\cpantesters.txt -o images\simple-plot-CPAN-Testers.png

perl -w bin\ffeedflotr.pl t\cpantesters.txt --time -o images\simple-plot-time-CPAN-Testers.png

perl -w bin\ffeedflotr.pl t\cpantesters.txt --time --fill -o images\simple-plot-filled-CPAN-Testers.png
perl -w bin\ffeedflotr.pl t\cpantesters.txt --time --fill --xlabel "CPAN Test Results" -o images\simple-plot-label-CPAN-Testers.png
