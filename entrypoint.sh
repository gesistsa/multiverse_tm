#!/bin/bash
exec "$@"

make rawdata/UNGDC_1946-2024.tar.gz

R --slave < jankin01.R --debug