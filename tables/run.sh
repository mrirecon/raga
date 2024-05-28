#!/bin/bash

set -euxBo pipefail


gcc table1.c -lm && ./a.out

gcc table2.c -lm && ./a.out

gcc table3.c -lm && ./a.out
