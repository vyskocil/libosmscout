#!/bin/sh

set -e

echo "Target:     " $TARGET
echo "OS:         " $TRAVIS_OS_NAME
echo "Build tool: " $BUILDTOOL
echo "Compiler:   " $CXX

echo "Installation start time: `date`"

export DEBIAN_FRONTEND=noninteractive

if [ "$TARGET" = "build" ]; then
  if [ "$TRAVIS_OS_NAME" = "linux" ]; then
    sudo apt-get -qq update

    if [ "$BUILDTOOL" = "autoconf" ]; then
      sudo apt-get install -y autoconf
    elif [ "$BUILDTOOL" = "cmake" ]; then
      sudo apt-get install -y cmake
    fi

    sudo apt-get install -y \
      pkg-config \
      gettext \
      libxml2-dev \
      libprotobuf-dev protobuf-compiler \
      libagg-dev libfreetype6-dev \
      libcairo2-dev libpangocairo-1.0-0 libpango1.0-dev \
      qt5-default qtdeclarative5-dev libqt5svg5-dev qtlocation5-dev \
      freeglut3 freeglut3-dev \
      libmarisa-dev \
      libglew2.0 libglew-dev \
      libglfw3 libglfw3-dev
  elif  [ "$TRAVIS_OS_NAME" = "osx" ]; then
    brew update

    if [ "$BUILDTOOL" = "cmake" ]; then
      brew install cmake || true
    fi

    brew install gettext libxml2 protobuf cairo pango qt5 glfw3 glew
    brew link --force gettext
    brew link --force libxml2
    brew link --force qt5
  fi
elif [ "$TARGET" = "importer" ]; then
  if [ "$TRAVIS_OS_NAME" = "linux" ]; then
    sudo apt-get -qq update

    if [ "$BUILDTOOL" = "autoconf" ]; then
      sudo apt-get install -y autoconf
    elif [ "$BUILDTOOL" = "cmake" ]; then
      sudo apt-get install -y cmake
    fi

    sudo apt-get install -y \
      pkg-config \
      libxml2-dev \
      libprotobuf-dev protobuf-compiler \
      libmarisa-dev
  fi
elif [ "$TARGET" = "website" ]; then
  echo "Installing dependencies for website..."

  wget https://github.com/spf13/hugo/releases/download/v0.21/hugo_0.21_Linux-64bit.deb
  sudo dpkg -i hugo_0.21_Linux-64bit.deb

  sudo apt-get -qq update
  sudo apt-get install -y python3-pygments python-pygments doxygen lftp
fi

echo "Installation end time: `date`"
