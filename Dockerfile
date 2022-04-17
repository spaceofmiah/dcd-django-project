FROM python:3.9-alpine3.12

# A label which denotes the maintainer of the project
# you could add more label for easy identification.
LABEL maintainer="spaceofmiah"

# Config to render python logs to the console
ENV PYTHONUNBUFFERED 1

# Copy host (pc from which the image is built) 
# requirements file to the root path in the image
COPY ./requirements.txt  /requirements.txt

# Copy project from host (pc from which the image is built) 
# to the root path in the image but rename folder as 
# project
COPY ./src /project

# Configure working directory as the project folder
WORKDIR /project

# Allow public access to the image on port 8000
EXPOSE 8000

# create a virtual environment in the root path / of image
RUN python -m venv /py && \ 
    # install upgrade for pip within the virtual env
    /py/bin/pip install --upgrade pip  && \
    # install postgres driver needed for postgres connection
    apk add --update --no-cache postgresql-client && \
    # install postgres dependencies needed to build postgres
    # driver and have these dependencies stored temporarily
    apk add --update --no-cache --virtual .tmp-deps \
        build-base postgresql-dev musl-dev && \
    # install project dependencies using requirements file
    /py/bin/pip install -r /requirements.txt && \
    # delete all the dependencies needed to build postgres
    # driver because at this point the driver is built.
    apk del .tmp-deps && \
    # create a user named project for the image to 
    # avoid root usage. No home directory is created, 
    # no password either
    adduser --disabled-password --no-create-home project && \
    # Create directory and subdirectory (-p) to house static file
    mkdir -p /vol/web/static && \
    # Create directory and subdirectory (-p) to house media file
    mkdir -p /vol/web/media  && \
    # Grant ownership of the of media and static directory (-R) 
    # recursively to the application user which was created above
    chown -R project:project /vol && \
    # Grant read, write and execute access to the owner
    chmod -R 755 /vol

# Set to PATH the virtual environment created within image 
# so every python command would use the virtual environment
ENV PATH="/py/bin:$PATH"

# Set the user named project as the user to run commands by
USER project



