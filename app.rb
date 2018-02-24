require 'sinatra'

set :logging, true
set :run, true

use Rack::Auth::Basic, "Authentication failed" do |username, password|
  username == 'deploy' and password == ENV['AUTHENTICATION_SECRET']
end

get '/redeploy' do
  if login
    message = redeploy_app
    notify(message)
  else
    notify("Login failed")
  end
end

get '/update/:service_name'
  if login
    message = update_service
    notify(message)
  else
    notify("Login failed")
  end
end

private

def redeploy
  system "docker stack deploy -c /run/secrets/docker-stack.yml"

  if $?.exitstatus == 0
    "Stack was redeployed"
  else
    "Stack could not be re-deployed"
  end
end

def login 
  system "docker login"
  $?.exitstatus == 0
end

def update(params)
  service = params['service_name']

  raise unless ENV['ALLOWED_SERVICES'].split(',').include?(service)

  system "docker service update --force #{service}"

  if $?.exitstatus == 0
    "Updated #{service} successfully"
  else
    "Updated #{service} failed"
  end
end

def notify(message)
  logger.info(message)
  # slack
end

