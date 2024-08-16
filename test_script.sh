#!/usr/bin/env bash

export SOME_ENV=0

a() {
  echo hello
  SOME_ENV="$((SOME_ENV + 1))"
}

b() {
  echo world
  SOME_ENV="$((SOME_ENV + 5))"
}

echo "$SOME_ENV"
