#!/bin/sh
cd /home/jayanaka/neojac-deslop/perf/memU/bench
BENCH_LABEL=cli python3 bench.py 7 startup_help import_service commit recommit retrieve list_files memorize_prepare
BENCH_LABEL=inproc python3 bench.py 5 inproc
BENCH_LABEL=pytest python3 bench.py 3 pytest
echo ALLDONE
