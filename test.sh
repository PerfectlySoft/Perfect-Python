docker pull rockywei/swift:3.1
docker run -it -v $PWD:/home rockywei/swift:3.1 /bin/bash -c "cd /home;swift test --build-path=.build_lin"
