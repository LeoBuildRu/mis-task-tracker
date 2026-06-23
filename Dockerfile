# syntax=docker/dockerfile:1.6
ARG RUBY_VERSION=3.4.3
FROM ruby:${RUBY_VERSION}-slim AS base

ENV LANG=C.UTF-8 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="" \
    RAILS_ENV=development \
    BUNDLE_DEPLOYMENT=0 \
    RAILS_LOG_TO_STDOUT=true

WORKDIR /app

RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      libyaml-dev \
      libffi-dev \
      postgresql-client \
      git \
      curl \
      tzdata \
 && rm -rf /var/lib/apt/lists/*

# Install gems
COPY Gemfile Gemfile.lock* ./
RUN gem install bundler -v "~> 2.5" \
 && bundle install --jobs 4 --retry 3

# Copy source
COPY . .

RUN chmod +x bin/* || true

EXPOSE 3000

ENTRYPOINT ["bin/docker-entrypoint"]

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
