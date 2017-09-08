#!/bin/bash
set -x

# Install GHC and build dependencies
timeout 100m stack build --stack-yaml=luna-studio/stack.yaml --no-terminal --only-dependencies --install-ghc -j2 --ghc-options=-j2 --ghc-options=-O2 --ghc-options="+RTS -M3G -RTS" +RTS -N1 -RTS
ret=$?
case "$ret" in
  0)
    # continue
    ;;
  124)
    echo "Timed out while installing dependencies."
    echo "Try building again by pushing a new commit."
    exit 1
    ;;
  *)
    echo "Failed to install dependencies; stack exited with $ret"
    exit "$ret"
    ;;
esac

# Build your project

stack build --stack-yaml luna-studio/stack.yaml --no-terminal -j2 --ghc-options=-j2 --ghc-options="+RTS -M3G -RTS" +RTS -N1 -RTS
