#!/bin/bash

egrep -v '^\[.{19}\]\[register\]' |
    egrep -v '^\[.{19}\]\[engine/mastersrv\]'
