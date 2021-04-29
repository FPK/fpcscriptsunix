#!/usr/bin/env bash
if command -v kate &> /dev/null
then 
  kate $@ 2> /dev/null &
elif command -v code &> /dev/null
then
  code $@
elif command -v joe &> /dev/null
then
  joe $@
fi
