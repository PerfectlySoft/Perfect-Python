clear
VER=4.1.2
echo "-------------- LINUX SWIFT $VER ----------------"
rm -rf .build_linux
rm -rf Package.resolved
docker pull rockywei/swift:$VER
docker run -it -v $PWD:/home -w /home rockywei/swift:$VER /bin/bash -c "swift build -c release --build-path=.build_lin && swift test --build-path=.build_lin"
echo "-------------- OS X / Xcode ----------------"
rm -rf .build
rm -rf Package.pins
rm -rf Package.resolved
swift build -c release
swift test

