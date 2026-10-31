#!/bin/bash

DOMAIN="scaler.com"

while true; do
    echo "[$(date)] DNS lookup for $DOMAIN"
    dig "$DOMAIN" +short
    sleep 5
done