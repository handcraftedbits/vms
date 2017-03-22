#!/bin/bash

postprocess_dir=${1}/postprocess

if [ ! -d ${postprocess_dir}/node_modules ]
then
     # Install Node.js dependencies.

     cd ${postprocess_dir}

     npm install
fi

gulp --gulpfile ${postprocess_dir}/gulpfile.js

# Start HTTP server to serve resume and use netshot to capture it as a PDF.

${postprocess_dir}/node_modules/.bin/http-server ${1}/public &

pid=$!

pdf_url=`curl -s -H "Content-Type: application/json" -X POST -d '{ "url": "http://hugo:8080/resume", "format": "pdf", \
     "width": 1024, "pdf": { "orientation": "portrait", "page-size": "letter" } }' http://netshot:8000 | \
     jq -r ".[0].href"`

wget -O ${1}/public/resume-cjh-public.pdf ${pdf_url}

curl -X DELETE ${pdf_url}

rm -rf ${1}/public/resume

sed -i "s/resume\//resume-cjh-public.pdf/g" ${1}/public/sitemap.xml

kill -9 ${pid}