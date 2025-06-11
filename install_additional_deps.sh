#!/bin/bash

# Check sipp already installed
if ! [ -x "$(command -v sipp)" ]; then
  # Install sipp for unit test
  echo "Installing sipp"

  curl -L https://github.com/SIPp/sipp/releases/download/v3.7.3/sipp-3.7.3.tar.gz -o sipp-3.7.3.tar.gz
  tar -xvf sipp-3.7.3.tar.gz
  cd sipp-3.7.3
  cmake .
  make -j`nproc`
  make install
  cd ..
  rm -rf sipp-3.7.3 sipp-3.7.3.tar.gz
fi


# Check sipsak already installed
if ! [ -x "$(command -v sipsak)" ]; then
  echo "Installing sipsak"

  # Install sipsak for unit test
  curl -L https://github.com/nils-ohlmeier/sipsak/releases/download/0.9.8.1/sipsak-0.9.8.1.tar.gz -o sipsak-0.9.8.1.tar.gz
  tar -xvf sipsak-0.9.8.1.tar.gz
  cd sipsak-0.9.8.1
  ./configure
  make -j`nproc`
  make install
  cd ..
  rm -rf sipsak-0.9.8.1 sipsak-0.9.8.1.tar.gz
fi