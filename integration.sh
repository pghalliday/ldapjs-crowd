#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
TMP_DIR=`mktemp -d /tmp/$1.XXXX` && cd $TMP_DIR
npm install $DIR
node -e "var assert = require('assert'); var test = require('$1'); assert.notEqual(typeof test, 'undefined');"
rm -rf $TMP_DIR
