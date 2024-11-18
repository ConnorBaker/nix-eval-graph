#!/usr/bin/env bash

curl -L -X GET 'http://localhost:3000/produce-attr-paths' -H 'Content-Type: application/json' -d '{
  "flakeRef": "github:ConnorBaker/cuda-packages/8cb28e23b8c7cee612fb68d86a12b263841df109",
  "attrPath": "legacyPackages.x86_64-linux.pkgsCuda.sm_89.cudaPackages_12"
}'