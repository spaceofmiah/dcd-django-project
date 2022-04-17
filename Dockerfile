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
    # install project dependencies using requirements file
    /py/bin/pip install -r /requirements.txt && \
    # create a user named project for the image to 
    # avoid root usage. No home directory is created, 
    # no password either
    adduser --disabled-password --no-create-home project

# Set to PATH the virtual environment created within image 
# so every python command would use the virtual environment
ENV PATH="/py/bin:$PATH"

# Set the user named project as the user to run commands by
USER project



