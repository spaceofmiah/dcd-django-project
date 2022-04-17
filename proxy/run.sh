#!/bin/sh

set -e 

# This takes in a template which has been defined and output the exact
# same template but replacing all ${xxxx} with the appropriate value.
# It's safe to say this feeds the actual variable values used in 
# defining the template. 

# Some permissions and ownership configurations are run on Dockerfile
# just to ensure this operation is possible.

envsubst < /etc/nginx/default.conf.tpl > /etc/nginx/conf.d/default.conf

# Run nginx and don't run it on the background but full ground.
nginx -g 'daemon off;'
