require 'sinatra'
require 'slack-notifier'

set :logging, true
set :run, true
set :bind, '0.0.0.0'

use Rack::Auth::Basic, "Authentication failed" do |username, password|
  username == 'deploy' and password == ENV.fetch('AUTHENTICATION_SECRET', 'deploy')
end

get '/' do
  message = %x{docker service ls}
  notify(message)
  200
end

get '/redeploy' do
  if login
    notify(redeploy)
    200
  else
    403
  end
end

get '/update/:service_name' do
  if login
    message = update(params)
    notify(message)
    200
  else
    403
  end
end

private

def redeploy
  system "git fetch origin"
  system "git reset --hard origin/master"
  system "docker stack deploy -c $STACK_CONFIG_FILE $STACK_NAME --with-registry-auth"

  if $?.exitstatus == 0
    "Stack was redeployed"
  else
    "Stack could not be re-deployed"
  end
end

def login 
  system "cat /run/secrets/dockerhub_password | docker login --username $DOCKER_USERNAME --password-stdin"
  $?.exitstatus == 0
end

def update(params)
  service = params.dig('service_name')
  raise unless ENV['ALLOWED_SERVICES'].split(',').include?(service)
  image = %x{docker service inspect #{service} -f {{.Spec.TaskTemplate.ContainerSpec.Image}}}.split('@').first
  image_name, image_tag = current_image.split(':')
  default_tag = ENV.fetch('DEFAULT_TAG', 'dev')
  tag = params.fetch('tag', default_tag)

  system "docker service update --image #{image_name}:#{tag} --force #{service} --with-registry-auth"

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

