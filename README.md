# dcd-django-project
Docker Compose Deploy (DCD) with django project and postgres database

### Getting Started Guide

Here is a step by step work through on how to create and containerize your django with deployment setup.
Each steps would have a commit reference to changes made.


1) Create a repository for project to track progress 

Created a repository to house the django project. Most importantly is to have a `.gitignore` for python during repo setup.


2) Create `.dockerignore` file 

This works like `.gitignore`. It is used to specify files & folders that should be ignored during the build of our docker images. (read more)[https://docs.docker.com/engine/reference/builder/#dockerignore-file]

