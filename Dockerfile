FROM ruby:alpine

LABEL author="seo.cahill@gmail.com"

WORKDIR /app

RUN \
  gem install sinatra \
  slack-notifier \
  && apk --update --no-cache add \
  docker \
  openrc \
  && rc-update add docker boot

COPY app.rb .

CMD [ "ruby app.rb" ]