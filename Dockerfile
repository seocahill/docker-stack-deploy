FROM ruby:2.5.0-alpine3.7

LABEL author="seo.cahill@gmail.com"

WORKDIR /app

RUN \
  gem install sinatra \
  slack-notifier \
  && apk --update --no-cache add \
  curl \
  docker \
  openrc \
  && rc-update add docker boot

COPY app.rb .

CMD ruby app.rb