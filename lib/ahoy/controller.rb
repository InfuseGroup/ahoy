module Ahoy
  module Controller
    def self.included(base)
      if base.respond_to?(:helper_method)
        base.helper_method :current_visit
        base.helper_method :ahoy
      end
      base.before_action :set_ahoy_cookies, if: -> { Ahoy.controller_callbacks }, unless: -> { Ahoy.api_only }
      base.before_action :delete_ahoy_cookies, if: -> { Ahoy.controller_callbacks }, unless: -> { Ahoy.api_only }
      base.before_action :track_ahoy_visit, if: -> { Ahoy.controller_callbacks }, unless: -> { Ahoy.api_only }
      base.around_action :set_ahoy_request_store
    end

    def ahoy
      @ahoy ||= Ahoy::Tracker.new(controller: self)
    end

    def current_visit
      ahoy.visit
    end

    def set_ahoy_cookies
      return unless Ahoy.cookies

      ahoy.set_visitor_cookie
      ahoy.set_visit_cookie
    end

    def delete_ahoy_cookies
      return if Ahoy.cookies

      # delete cookies if exist
      ahoy.reset
    end

    def track_ahoy_visit
      defer = Ahoy.server_side_visits != true

      if defer && !Ahoy.cookies
        # avoid calling new_visit?, which triggers a database call
      elsif ahoy.new_visit?
        ahoy.track_visit(defer: defer)
      end
    end

    def set_ahoy_request_store
      previous_value = Ahoy.instance
      begin
        Ahoy.instance = ahoy
        yield
      ensure
        Ahoy.instance = previous_value
      end
    end
  end
end
