#!/bin/sh

# change to the current directory
pushd $(cd -P $(dirname $0) && pwd) > /dev/null

# compile the actionscript file
mxmlc -static-link-runtime-shared-libraries "src/Downloadify.as" -o "media/downloadify.swf"

# minify the javascript file
yui "src/downloadify.js" -o "js/downloadify.min.js"

# restore the previous working directory
popd > /dev/null