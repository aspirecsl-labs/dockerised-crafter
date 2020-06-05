#!/bin/bash
#set -x

run(){
  local service=$1
  local version=$2
  local port=$3
  local debug_port=${4:-8000}

  echo "Starting container: crafter-$service:$version"
  if [ "$service" = 'authoring' ]
  then
    docker run -p "${port:-8080}":8080 -p "$debug_port":8000 "crafter-$service:$version"
  else
    docker run -p "${port:-9080}":9080 -p "$debug_port":8000 "crafter-$service:$version"
  fi
}

build() {
  local service=$1
  local version=$2

  # SHA512 checksums for the Crafter Delivery bundle
  declare -a delivery
  delivery[315]=4c29231f53c8d2dd5d48b880c9a9a6e38ca801c418580a104fef6f8327cfddee15f0632efd4d2a67bac0c0536a9a6fab3e766e6d268e1efa477d342f2afa669e
  # shellcheck disable=SC2034
  delivery[316]=9a651634bffe117e6f86eda3aacb4b4e7b63b4cca7ba6cb7d216021b1b13ec5bf27146fecebbecfa5c6515b1d04338ae7c4664eacdc197b781e5049ec8b264b1

  # SHA512 checksums for the Crafter Authoring bundle
  declare -a authoring
  authoring[315]=7010e77f1d68c9cc3fd4e12e596ca784ba3e4b3505fea7a77499e04648499b43a0c738691a8942547061c1787b1de638ebb007210dd839f9666bbb2fb83a5e7c
  # shellcheck disable=SC2034
  authoring[316]=85dd6c9b4ef6e111a0a2d2e1e9cc6e8216fc44cc5eed725f9cc71a86ce41fac6668aa86b8da6deb77cb7cdf08578ba16086d6d2fda52327b3da21660c42b5acc

  checksum="${service}[${version//./}]"

  docker build \
    --build-arg SERVICE="$service" \
    --build-arg VERSION="$version" \
    --build-arg CHECKSUM="${!checksum}" \
    --tag crafter-"$service":"$version" .
}

if [ "$WRAPPER" != "true" ]
then
  echo -e "\nDirect execution of this script is not allowed. Please use the wrapper script [cms]\n"
fi

port=$4
version=$1
service=$2
debug_port=$4

case $3 in
build)
  build "$service" "$version"
  ;;
run)
  run "$service" "$version" "$port" "$debug_port"
  ;;
esac

exit 0

