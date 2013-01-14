require 'action_controller/railtie'

# Once and only once!
if !defined?(MyApp)

  ENV['NEW_RELIC_DISPATCHER'] = 'test'

  class MyApp < Rails::Application
    # We need a secret token for session, cookies, etc.
    config.active_support.deprecation = :log
    config.secret_token = "49837489qkuweoiuoqwehisuakshdjksadhaisdy78o34y138974xyqp9rmye8yrpiokeuioqwzyoiuxftoyqiuxrhm3iou1hrzmjk"
  end
  MyApp.initialize!

  MyApp.routes.draw do
    get('/bad_route' => 'Test#controller_error',
        :constraints => lambda do |_|
          raise ActionController::RoutingError.new('this is an uncaught routing error')
        end)
    match '/:controller(/:action(/:id))'
  end

  class ApplicationController < ActionController::Base; end

  # a basic active model compliant model we can render
  class Foo
    extend ActiveModel::Naming
    def to_model
      self
    end

    def valid?()      true end
    def new_record?() true end
    def destroyed?()  true end

    def raise_error
      raise 'this is an uncaught model error'
    end

    def errors
      obj = Object.new
      def obj.[](key)         [] end
      def obj.full_messages() [] end
      obj
    end
  end

  class ErrorController < ApplicationController
    include Rails.application.routes.url_helpers
    newrelic_ignore :only => :ignored_action

    def controller_error
      raise 'this is an uncaught controller error'
    end

    def view_error
      render :inline => "<% raise 'this is an uncaught view error' %>"
    end

    def model_error
      Foo.new.raise_error
    end

    def ignored_action
      raise 'this error should not be noticed'
    end

    def ignored_error
      raise IgnoredError.new('this error should not be noticed')
    end

    def server_ignored_error
      raise ServerIgnoredError.new('this is a server ignored error')
    end

    def noticed_error
      newrelic_notice_error(RuntimeError.new('this error should be noticed'))
      render :text => "Shoulda noticed an error"
    end
  end

  class QueueController < ApplicationController
    include Rails.application.routes.url_helpers

    def queued
      respond_to do |format|
        format.html { render :text => "<html><head></head><body>Queued</body></html>" }
      end
    end
  end
end
