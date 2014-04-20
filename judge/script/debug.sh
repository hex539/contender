#!/bin/bash

echo -n 'stopping judge... ' >&2
(kill `ps axu | grep [j]udge_server.pl | awk '{print $2'}` 2> /dev/null && echo '[OK]' >& 2) || echo '[FAILED]' >&2

echo    'starting judge... ' >&2
nohup ./script/judge_server.pl -d --keeperr 2>>./error.log >/dev/null
echo 'finished.'
