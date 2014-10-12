#!/bin/bash

dot -Tps $1 -o $2;
gnome-open $2;
