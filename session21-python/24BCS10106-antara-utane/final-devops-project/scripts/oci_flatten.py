#!/usr/bin/env python3
"""Flatten a buildx OCI layout so every platform manifest is listed in index.json.

`docker buildx build --output type=oci` (docker-container driver) writes an
index.json with ONE entry: the multi-arch image index. Trivy's --platform
selection needs the per-platform manifests at the top level, so we replace
index.json with the nested index. Usage: oci_flatten.py <layout-dir>
"""
import json
import os
import sys

layout = sys.argv[1]
path = os.path.join(layout, "index.json")
index = json.load(open(path))
entries = index["manifests"]
if len(entries) == 1 and "platform" not in entries[0] and entries[0]["mediaType"].endswith("index.v1+json"):
    algo, digest = entries[0]["digest"].split(":")
    nested = json.load(open(os.path.join(layout, "blobs", algo, digest)))
    json.dump(nested, open(path, "w"))
    entries = nested["manifests"]
for m in entries:
    p = m.get("platform", {})
    print(f"{p.get('os')}/{p.get('architecture')}  {m['digest']}")
