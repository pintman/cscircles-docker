# cscircles-docker

Docker Container for CS-Circles. Mainly its based on the wordpress container but enriched
with python3jail and safeexec which are needed to safely execute python code.

## Installation

1. Check out this repo.
2. Start the services with ``docker-compose up -d`` (this may take a
   while). During this step python3jail and safeexec will be installed
   for you.
3. Go to http://localhost:8888 and follow the installation
   instructions of your wordpress installation - the service is by
   default exposed on port 8888.
4. All files will be created in a new data-folder.
5. Follow the instructions from
[cscircles-wp-content repo](https://github.com/cemc/cscircles-wp-content). 
   python3jail and safeexec are already installed in the container at
   ``/cscircles/python3jail`` and ``/cscircles/safeexec``.
