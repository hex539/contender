#!/bin/bash

echo -n 'stopping judge... ' >&2
(killall 'judge_server.pl' 2> /dev/null && echo '[OK]' >& 2) || echo '[FAILED]' >&2

echo    'starting judge... ' >&2
nohup ./judge_server.pl -d --keeperr 2>>../error.log >/dev/null
echo 'finished.'
