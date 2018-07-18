require 'sinatra'
require 'slack-notifier'
require 'open3'

set :logging, true
set :run, true
set :bind, '0.0.0.0'

before do
  return unless params['token'] == %x{ cat /run/secrets/auth_token }
  halt 401, "Not authorized\n"
end

post '/info' do
  service = params['text']
  if service.empty?
    stdout, stderr, status = Open3.capture3('docker service ls')
  else
    stdout, stderr, status = Open3.capture3("docker service ps #{service}")
  end
  status.success? ? notify("```#{stdout}```") : notify(stderr)
  status
end

post '/deploy' do
  if login
    Thread.new { deploy }
    [200]
  else
    [403, 'Error! docker login failed']
  end
end

post '/update' do
  if login
    Thread.new { update(params) }
    [200]
  else
    [403, 'Error! docker login failed']
  end
end

private

def deploy
  # Change to directory of cloned stack code
  Dir.chdir('/src')

  # Update config to latest and redeploy
  remote = %x{ cat /run/secrets/github_uri }
  command = %Q{
    git checkout master &&
    git fetch #{remote} &&
    git reset --hard origin/master &&
    docker stack deploy -c $STACK_CONFIG_FILE $STACK_NAME --with-registry-auth
  }

  stdout, stderr, status = Open3.capture3(command)

  if status.success?
    notify("```Success! #{stdout}```")
  else
    notify("```Error! #{stderr}```")
  end
end

def login 
  system "cat /run/secrets/dockerhub_password | docker login --username $DOCKER_USERNAME --password-stdin"
  $?.exitstatus == 0
end

def update(params)
  service, tag = params.dig('text').split(':')

  # Only update whitelisted services
  whitelisted = ENV['ALLOWED_SERVICES'].split(',').include?(service)
  return notify("```Error! #{service} service is not whitelisted```") unless whitelisted

  # Apply passed in or default tag
  image_name, image_tag = current_image(service).split(':')
  new_tag = tag || ENV.fetch('DEFAULT_TAG', 'dev')

  command = "docker service update --image #{image_name}:#{new_tag} --force #{service} --with-registry-auth"
  stdout, stderr, status = Open3.capture3(command)

  if status.success?
    new_image = current_image(service)
    notify("```Success! Image was updated to #{new_image}```")
  else
    notify("```Error! #{stderr}```")
  end
end

def current_image(service)
  %x{docker service inspect #{service} -f {{.Spec.TaskTemplate.ContainerSpec.Image}}}.split('@').first
end

def slack
  @slack ||= Slack::Notifier.new(ENV["WEBHOOK_URL"], channel: "#devops")
end

def notify(message)
  logger.info(message)
  slack.ping(message)
end

