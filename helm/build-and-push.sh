#!/bin/sh
helm package inference
TAG=controller
podman build . -f Dockerfile -t quay.io/rh_ee_cschmitz/ose-cli-edge:$TAG
podman push quay.io/rh_ee_cschmitz/ose-cli-edge:$TAG
