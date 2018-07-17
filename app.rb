require 'sinatra'
require 'slack-notifier'
require 'open3'

set :logging, true
set :run, true
set :bind, '0.0.0.0'

before do
  # Authenticate slack and/or CI
  true
end

post '/info' do
  if service = params['text']
    stdout, stderr, status = Open3.capture3("docker service ps #{service}")
  else
    stdout, stderr, status = Open3.capture3('docker service ls')
  end
  status.success? ? notify(stdout) : notify(stderr)
  status
end

post '/deploy' do
  if login
    status, message = redeploy
    notify(message)
    status
  else
    403
  end
end

post '/update' do
  if login
    status, message = update(params)
    notify(message)
    status
  else
    403
  end
end

private

def redeploy
  # Change to directory of cloned stack code
  Dir.chdir('/src')

  # Update config to latest and redeploy
  command = %Q{
    git fetch origin &&
    git reset --hard origin/master &&
    docker stack deploy -c $STACK_CONFIG_FILE $STACK_NAME --with-registry-auth
  }

  stdout, stderr, status = Open3.capture3(command)

  if status.success?
    [200, stdout]
  else
    [500, stderr]
  end
end

def login 
  system "cat /run/secrets/dockerhub_password | docker login --username $DOCKER_USERNAME --password-stdin"
  $?.exitstatus == 0
end

def update(params)
  # Only update whitelisted services
  service, tag = params.dig('text').split(':')
  return [403, "service cannot be updated"] unless ENV['ALLOWED_SERVICES'].split(',').include?(service)

  # Apply passed in or default tag
  current_image = %x{docker service inspect #{service} -f {{.Spec.TaskTemplate.ContainerSpec.Image}}}.split('@').first
  image_name, image_tag = current_image.split(':')
  new_tag = tag || ENV.fetch('DEFAULT_TAG', 'dev')

  command = "docker service update --image #{image_name}:#{new_tag} --force #{service} --with-registry-auth"
  stdout, stderr, status = Open3.capture3(command)

  if status.success?
    [200, stdout]
  else
    [500, stderr]
  end
end

def slack
  @slack ||= Slack::Notifier.new(ENV["WEBHOOK_URL"])
end

def notify(message)
  logger.info(message)
  slack.ping(message)
end

