#!/usr/bin/env bash
if command -v code &> /dev/null
then
  if [[ $# -eq 0 ]] ;
  then
    code .
  else
    code -g $@
  fi
elif command -v kate &> /dev/null
then
  kate $@ 2> /dev/null &
elif command -v joe &> /dev/null
then
  joe $@
fi
