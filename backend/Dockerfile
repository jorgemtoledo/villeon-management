FROM ruby:3.3.6-slim

ENV LANG=C.UTF-8 \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

RUN apt-get update -qq \
    && apt-get install --no-install-recommends -y \
        build-essential \
        libpq-dev \
        libyaml-dev \
        postgresql-client \
        git \
        curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN chmod +x bin/docker-entrypoint

ENTRYPOINT ["bin/docker-entrypoint"]

EXPOSE 3010

CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3010"]
