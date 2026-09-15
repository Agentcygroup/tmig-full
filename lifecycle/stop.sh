#!/usr/bin/env bash
for port in 8080 8081 8082 8083 8084; do
  pid=$(lsof -ti:"$port" 2>/dev/null || true)
  [ -n "$pid" ] && kill "$pid" 2>/dev/null && echo "  stopped :$port"
done
