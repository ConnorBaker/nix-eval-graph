#!/usr/bin/env bash

curl \
  -L \
  -X GET \
  'http://localhost:3000/produce-attr-paths' \
  -H 'Content-Type: application/json' \
  -d '{
        "flakeRef": "path:/nix/store/p561bgj49nbfy5z2cnls19cg9z28n5vl-source?narHash=sha256-lSshKJazku5p+NJ+tBJUcff2ytp5UJZ/oz0oYDwDbV0=",
        "attrPath": "legacyPackages.x86_64-linux.cudaPackages_12"
      }' \
  | jq