# dcd-django-project
Docker Compose Deploy (DCD) with django project and postgres database

### Getting Started Guide

Here is a step by step work through on how to create and containerize your django with deployment setup.
Each steps would have a commit reference to changes made.


1) Create a repository for project to track progress 

Created a repository to house the django project. Most importantly is to have a `.gitignore` for python during repo setup.


2) Create `.dockerignore` file 

This works like `.gitignore`. It is used to specify files & folders that should be ignored during the build of our docker images. [read more](https://docs.docker.com/engine/reference/builder/#dockerignore-file)

3) Add `requirements.txt` file

This file list the dependencies which are essential to the creation and functioning of our django project.

4) Add Dockerfile

This version of docker file is just enough to create a django project. It contains commands which not only defines the type (`python`) of project we're building but also helps to install dependency needed by the project.

5) Add docker-compose.yml

This version of compose file is equiped with just the project service which is being built.

**CREATING A DJANGO PROJECT**

At this point we'll validate if the configuration and setup so far is ok by running from our project directory ( where we've docker-compose.yml ) the below command

```bash
docker-compose build
```

Would build the services as configured in the `docker-compose.yml` file.

> **NOTE:**
> Before the above command is run, make sure to have an existing empty ./src folder existing in same location as specified in same directory as the docker-compose. If you're using a different path, make sure to update the path in the `Dockerfile COPY` command and `docker-compose.yml volume` statement for the project service


```bash
docker-compose run --rm project sh -c "django-admin startproject src ."
```

This command will use the built service `project` (as defined in docker-compose file)  to create a new django project. This created project would leave in a folder called `src` on your host machine which is mapped to `project` within container created from the project Dockerfile.

Should incase your project uses a different directory, here are the setup that has made this mapping possible 

```yml
# in your Dockerfile

COPY ./src /project

# if you use a different project folder replace ./src with that
```


```yml
# in your docker-compose.yml

services:

  project:
    volume:
      - ./src:/project
      # if you use a different project folder, replace ./src with that.
```

With the above commands, if everything goes fine, you should now have a django project within your `./src` folder. 


6) Clean up secrets within project to utilize environment variable.

Secret configuration values shouldn't be exposed within projects. To clean our django project secret key, environment variables are fed from `docker-compose.yml` from `project` service into django project. This is possible as the `project` service will be used to run a container (which would act as a host someworth like our local/host machine) that contains similar copy of our project. 

Becuase our docker-compose.yml will be pushed to git, the current approach is not also adviced for projection builds as the secret configuration values are also exposed. You could read more on [how to configure environment variables ](https://docs.docker.com/compose/environment-variables/)

7) Add postgres database service

This service setup is necessary as it makes provision for a postgres database

8) Add postgres before and after build dependencies & drivers to image

To connect django project to the postgres db, there needs to be a driver to facilitate this connectivity. The django `x` postgres driver is defined within `requirements.txt`. To use this driver some packages are needed to build it `build-base, postgresql-dev, musl-dev` and some others are needed for the actual connection `postgresql-client`. The build packages are not needed after the driver is installed and are safe to delete. To easily delete these unwanted packages, during their installation, they were all installed in a `tmp-deps` where deleting the `tmp-deps` would automatically delete them.

9) Connect database to project

Database secret configs are padded as environment variable to project and connectivity is allowed with the `depends_on` which state that the project depends on the database and as such, the database would needed to be up and running before attempting to run the project. `depends_on` also allows mapping of database host possible. The database environment variable are used to configure postgres db within project's `settings.py` file.

**CREATE A DJANGO APP**

To test that the both postgres and project services are successfully connected, we'll create a django app and confirm:

```bash
docker-compose build
```
A rebuild is needed as the `Dockerfile` has been updated 


```bash
docker-compose run --rm project sh -c "python manage.py startapp core"
```

The above command would create a django app named `core` and this should be located within `./src` folder.

**MAKEMIGRATIONS**

Now that we've an app, for django to recognize the app, it need to first be
registered within `INSTALLED_APPS` within settings.py. Models are django 
representation of a database table, which can be migrated after definition of the model. 

After adding a model in the `./src/core/models.py` file, the below command would run migration for that model to the database connected to the django project

```bash
docker-compose run --rm project sh -c "python manage.py makemigrations"
docker-compose run --rm project sh -c "python manage.py migrate"
```

To interact with the model, it's registered in admin site within `./src/core/admin.py`.

**MAKING PROJECT STARTUP WAIT FOR DB AVAILABILITY**

The migrations command from above needs to be run automatically from docker-compose.yml, this brings about an issue where although our `project` service depends on the `db` service and it's expected that the `db` is started first before the `project`... that's all there's **started** ... depends on only tells which should start first. Django on the other hand, doesn't only just require that the db has started but also requires it to be **ready to accept connection** before the connectivity succeeds. These errors where just so unexplainable/unclear until after lots of trials ( it was alot of time trying to fix this ). 

To ensure that the database is ready to accept connection before we actually run any django command, we need to somehow tell django to wait for the database to initialize and be ready for connection before we proceed without breaking the process.

To do this a custom command is created to do the checks and wait. Read more from the django offical docs on [how to create custom commands](https://docs.djangoproject.com/en/4.0/howto/custom-management-commands/). 

This command is defined within `./src/core/management/commands/wait_for_db.py` and all our command is doing is safely handling errors while trying to check if the database connection is ready.

**SERVING STATIC & MEDIA FILES (DEVELOPMENT CONFIGURATION)**

Django [is not efficient at serving static and media files in production](https://docs.djangoproject.com/en/4.0/howto/deployment/wsgi/modwsgi/#serving-files-1), this functionality needs to be handled through reverse proxy. To ensure that the system are all properly functioning, we'll first test that we can work with static and media files from our development server. Static and media files need root directory to store the files collected either during developement or from user's upload. This configurations are included in `./src/src/settings.py`.

We'll allow our project's docker image to create these directory if they dont' already exist by creating the exact directory path configured within `./src/src/settings.py` for STATIC_ROOT & MEDIA_ROOT in our RUN command within `Dockerfile`. Ownership and access are also very important that it be granted to the project owner which is the user that is created for the project.

Just so we don't have to re-run our docker image whenever a media file is uploaded or updated by a user, (for development purpose only) the media and static directory are mapped from the host machine to the container which would allow an automatic sync.

Lastly to view our static and media files, they need to be accessible from the web i.e they need a route. In `./src/src/settings.py` STATIC_URL & MEDIA_URL configurations denotes that any request with such a url path is attempting to access either static or media files respectively. For django routing system to be aware of these routes, it's required that they be added to the project base route configurations `./src/src/urls.py`


**TEST STATIC & MEDIA SETUP (DEVELOPMENT CONFIGURATIONS)**

We'll be testing this configuration using the `Todo` model which as created earlier. This model was added to admin, so  to interact with it, we need an admin user. create admin user using docker compose command

```bash
docker-compose run --rm project sh -c "python manage.py createsuperuser"
```

The above command would prompt to enter some input, provide any input, but do remember the details as it'll be required of you to access the admin site. 

```bash
docker-compose up
```

should spin up the django project with the db and all configurations setup. Access the admin site with
`127.0.0.1:8000/admin` where you'll be prompted to input the user details that were created above. Proceed to create a todo and adding an attachment. On success, you should be able to view the attachment and all details provided during the todo creation.


**REVERSE PROXY CONFIGURATION**

As mentioned earlier, it's not adviced to serve django static and media files using django. Before we commence with the reverse proxy, it's safe to state here that, it wouldn't only serve our static and media files but also act as a gateway to accessing our application. So for every request containing `/static/` that would be handled by the reverse proxy by accessing the folders within our server within which our static files would be kept. For every other request that doesn't commence with `/static/` that is passed down to our application which would run the necessary computation and send back the response to the proxy which would then take serve that to the client.

A new folder `proxy` is created within our project folder and in this folder are 

  - defualt.conf.tpl : this is a template which has placeholders for secret value configurations. This template will be fed the actual values and then converted from being a template to an actual file

  - uwsgi_params : defines parameters needed for better request and response headers. [learn more](https://uwsgi-docs.readthedocs.io/en/latest/Nginx.html#what-is-the-uwsgi-params-file)

  - Dockerfile : Configures nginx image which would act as the gateway for request and response cycle for the project. This file uses an unprivileged image as the base image for security reasons. It then proceeds in copying the custom files, create new files using root user ( switches to root user ) that'll be needed to run nginx. A switch back to nginx user is found at the end of the file. Nginx is started with a script file `./proxy/run.sh`.

  - run.sh : This file does the feeding of the actual secret data to the `default.conf.tpl` and outputs the converted template to a file created in the Dockerfile by root user. 

  > Earlier some files where created within Dockerfile serving the reverse proxy, if those file were'nt created and permission not granted to the nginx user, the convertion of the template would've failed because the output file wouldn't be available and also the nginx user would'nt have privilege to either create or modify the file.

