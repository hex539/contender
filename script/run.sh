#!/bin/bash

./judge_fastcgi.pl --listen 127.0.0.1:30115 --keeperr 2>>../error.log >/dev/null
