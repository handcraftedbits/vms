#!/bin/bash

postprocess_dir=${1}/postprocess

if [ ! -d ${postprocess_dir}/node_modules ]
then
     cd ${postprocess_dir}

     npm install
fi

gulp --gulpfile ${postprocess_dir}/gulpfile.js