# Run nginx as an unprivileged user for security reasons
FROM nginxinc/nginx-unprivileged:1-alpine

LABEL maintainer="spaceofmiah"

# Copy the configuration files accordingly
COPY ./default.conf.tpl /etc/nginx/default.conf.tpl
COPY ./uwsgi_params /etc/nginx/uwsgi_params
COPY ./run.sh /run.sh


# Create environment variable which is needed
# by nginx configuration template.
ENV LISTEN_PORT=8000
ENV APP_HOST=project
ENV APP_PORT=9000


# Switch user to root 
USER root

# Only root user can perform these ops
# Create the static volume from which static files will 
# be served in production environment
RUN mkdir -p /vol/static && \
    # Modify access of the static volume for the root user
    # granting read, write & update
    chmod 755 /vol/static && \
    # Create an empty nginx configuration file 
    touch /etc/nginx/conf.d/default.conf && \
    # Grant the ownership of this file to the nginx user
    chown nginx:nginx /etc/nginx/conf.d/default.conf && \
    # Give executable permission on the run script
    chmod +x /run.sh

VOLUME /vol/static

# Switch user back to nginx ... Because this is the last user
# set in this file, it'll be used by docker to run the the 
# image... above all permissions and files needed by this 
# user has been created by root user ready to be used.
USER nginx

# Run the script defined in run.sh
CMD [ "/run.sh" ]

