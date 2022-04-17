server {
    listen ${LISTEN_PORT};

    # This catches all request beginning with /static
    # Given that our django configuration for both static 
    # and media file url configuration begins with 
    # /static, just this block will serve both

    location /static {
        alias /vol/static;
    }

    # The block below serves every other request not beginning 
    # with /static

    location / {
        
        uwsgi_pass                  ${APP_HOST}:${APP_PORT};

        # Include configurations parameters as defined in 
        # uwsgi_params file

        include                     /etc/nginx/uwsgi_params;

        # This would restrict sending request above 10M to the 
        # application

        client_max_body_size        10M;
        
    }
}
