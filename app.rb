require 'sinatra'
require 'slack-notifier'

set :logging, true
set :run, true
set :bind, '0.0.0.0'

use Rack::Auth::Basic, "Authentication failed" do |username, password|
  username == 'deploy' and password == ENV.fetch('AUTHENTICATION_SECRET', 'deploy')
end

get '/' do
  message = system "docker service ls"
  notify(message)
  200
end

get '/redeploy' do
  notify(redeploy)
  200
end

get '/update/:service_name' do
  message = update(params['service_name'])
  notify(message)
  200
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

def update(service)
  raise unless ENV['ALLOWED_SERVICES'].split(',').include?(service)

  system "docker service update --force #{service}"

  if $?.exitstatus == 0
    "Updated #{service} successfully"
  else
    "Updated #{service} failed"
  end
end

def slack
  @slack ||= Slack::Notifier.new(ENV["WEBHOOK_URL"])
end

def notify(message)
  logger.info(message)
  slack.ping(message)
end

