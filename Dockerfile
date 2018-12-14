FROM ruby:2.4

COPY ./reddit /reddit

RUN cd /reddit && bundle install

