rm -rf .build
rm -rf .build_lin
swift test
docker run -it -v $PWD:/home rockywei/swift:3.1 /bin/bash -c "cd /home;swift test --build-path=.build_lin"
rm -rf .build
rm -rf .build_lin
