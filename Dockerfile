FROM ruby:3.3

RUN apt-get update -qq && apt-get install -y nodejs npm postgresql-client

WORKDIR /app

# Gemfile/bundle installはvolume経由で管理（COPYしない）

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
