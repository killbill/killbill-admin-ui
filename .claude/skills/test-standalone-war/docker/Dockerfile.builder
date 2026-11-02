ARG JRUBY_IMAGE
FROM ${JRUBY_IMAGE}
# Same toolchain as the GitHub ubuntu runner: some gems (e.g. prism) compile native extensions
RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends build-essential git ca-certificates && rm -rf /var/lib/apt/lists/*
