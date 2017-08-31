echo "-------------- LINUX SWIFT 3.1 ----------------"
rm -rf .build_lin
rm -rf Package.pins
docker pull rockywei/swift:3.1
docker run -it -v $PWD:/home rockywei/swift:3.1 /bin/bash -c "cd /home;swift build --build-path=.build_lin; swift build -c release --build-path=.build_lin;swift test --build-path=.build_lin"
echo "-------------- LINUX SWIFT 4.0 ----------------"
rm -rf .build_linux
rm -rf Package.resolved
docker pull rockywei/swift:4.0
docker run -it -v $PWD:/home rockywei/swift:4.0 /bin/bash -c "cd /home;swift build --build-path=.build_linux; swift build -c release --build-path=.build_linux;swift test --build-path=.build_linux"
echo "-------------- OS X / Xcode ----------------"
rm -rf .build
rm -rf Package.pins
swift build
swift build -c release
swift test
