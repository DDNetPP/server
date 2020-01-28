#!/bin/bash

Reset='\033[0m'
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'

function err() {
  echo -e "[${Red}error${Reset}] $1"
}

function log() {
  echo -e "[${Yellow}*${Reset}] $1"
}

function wrn() {
  echo -e "[${Yellow}!${Reset}] $1"
}

function suc() {
  echo -e "[${Green}+${Reset}] $1"
}

