# frozen_string_literal: true

# RUN:
# $ ruby notifications.rb && WITHOUT_NOTIFICATIONS=true ruby notifications.rb

require "bundler/inline"

gemfile(true, quiet: true) do
  source "https://rubygems.org"

  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "rails", github: "rails/rails", branch: "main"
  gem 'benchmark-ips'
end

require "benchmark/ips"
require "action_controller/railtie"

class AppController < ActionController::Base
end

AppController.view_paths = [File.expand_path("../views", __dir__)]
controller_view = AppController.new.view_context

Benchmark.ips do |x|
  x.time = 10
  x.warmup = 2

  x.report('subscribed') do
    controller_view.render('partial', name: 'Orange')
  end

  if ENV['WITHOUT_NOTIFICATIONS'] == 'true'
    ActiveSupport::Notifications.unsubscribe 'render_partial.action_view'
  end

  x.report('unsubscribe') do
    controller_view.render('partial', name: 'Orange')
  end

  x.hold! 'temp_results'
  x.compare!
end
