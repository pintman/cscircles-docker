# cscircles-docker

Docker Container for CS-Circles. Mainly its based on the wordpress container but enriched
with python3jail and safeexec which are needed to safely execute python code.

Start the services with ``docker-compose up -d`` and follow the installation instructions from
wordpress - the service is by default exposed on port 8888. 
After that, you can follow the instructions given in the 
[cscircles-wp-content repo](https://github.com/cemc/cscircles-wp-content). During setup of the
safeexec and python3jail in the CScircles admin section in wordpress use the paths
``/cscircles/python3jail`` and ``/cscircles/python3jail``.
