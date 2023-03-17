#!/bin/bash -e

# Create server folder to create HTML files there.
mkdir server && cd server

# Create "root" file
echo "Hello, this is root" > index.html
# Create /foo path with "Hello, this is foo" and back to "root" folder
mkdir foo && cd foo && echo "Hello, this is foo" > index.html && cd ..
# Create /bar path with "Hello, this is bar"
mkdir bar && cd bar && echo "Hello, this is bar" > index.html && cd ..

# Start server
nohup busybox httpd -f -p ${server_port} &