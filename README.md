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

