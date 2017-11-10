clear
echo "-------------- LINUX SWIFT 4.0 ----------------"
rm -rf .build_linux
rm -rf Package.resolved
docker pull rockywei/swift:4.0
docker run -it -v $PWD:/home -w /home rockywei/swift:4.0 /bin/bash -c "swift build -c release --build-path=.build_lin && swift test --build-path=.build_lin"
echo "-------------- OS X / Xcode ----------------"
rm -rf .build
rm -rf Package.pins
rm -rf Package.resolved
swift build -c release
swift test

