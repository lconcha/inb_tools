#!/bin/bash

prefix=$1

ls -d $SUBJECTS_DIR/${prefix}* | xargs -n 1 basename | tr '\n' ' '