# Docker stack deploy

A service to handle continuous delivery to a docker stack.

## Configuration

Add to your stack using the included docker-stack template file as a guide.

## Required settings

- A text file containing a password for basic authentication (the user is 'deploy')
- A text file containing your dockerhub password

See the suggested secrets configuration for details.

Docker login is executed as suggested [here](https://docs.docker.com/engine/reference/commandline/login/#provide-a-password-using-stdin) in the official docs.

## Usage

- Setup a reverse proxy for requests to the continuous deploy service e.g.

```
# Nginx conf file
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  
  # an example application service
  location / {
    proxy_pass http://app;
  }

  # reverse proxy /cd/** requests to cd service
  location /cd/ {
    proxy_pass http://cd:4567/;
  }
}
```

- Setup a trigger on dockerhub - e.g. 

```
# Update image of service "app" in stack "my_stack" to latest version

POST https://deploy:basic_auth_password@example.com/cd/update/my_stack_app
```
