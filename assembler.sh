#!/bin/bash

if [ $# -eq 0 ]; then
  echo -e "usage: no argument is provided."
  exit 1

elif [ $# -gt 1 ]; then
  ehco -e "usage: more than one argument are provided."
  exit 1

fi

