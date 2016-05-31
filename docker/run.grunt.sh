#!/bin/bash
grunt prod;
while true; do
    cd /app;
    grunt watch;
done