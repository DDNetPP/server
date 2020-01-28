#!/bin/bash

Reset='\033[0m'
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'

function err() {
      echo -e "[${Red}error${Reset}] $1"
}

function log() {
    if [ "$#" == 2 ] && [ "$1" == "-n" ]
    then
      echo -ne "[${Yellow}*${Reset}] $2"
    else
      echo -e "[${Yellow}*${Reset}] $1"
    fi
}

function wrn() {
      echo -e "[${Yellow}!${Reset}] $1"
}

function suc() {
      echo -e "[${Green}+${Reset}] $1"
}

