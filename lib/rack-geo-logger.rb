require 'rack'
require 'net/http'
require 'json'

module Rack
  class GeoLogger
    GEO_API_URL = 'http://freegeoip.net/json/'.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      if env['rack.session']['geo.link'].nil?
        set_geo_info(env)
      end
      log_geo_info(env)
      status, headers, body = @app.call(env)
    end

    private

    def set_geo_info(env)
      geo_info = call_geo_api(env['REMOTE_ADDR'])
      env['rack.session']['geo.lat']     = geo_info["latitude"]
      env['rack.session']['geo.lon']     = geo_info["longitude"]
      env['rack.session']['geo.country'] = geo_info["country_name"]
      env['rack.session']['geo.city']    = geo_info["city"]
      env['rack.session']['geo.zip']     = geo_info["zipcode"]
      env['rack.session']['geo.link']    = "https://maps.google.com/?q=#{geo_info["latitude"]},#{geo_info["longitude"]}"
    end

    def log_geo_info(env)
      session = env['rack.session']
      env['rack.errors'].write "GEO LOCATION - country: #{session["geo.country"]}, city: #{session["geo.city"]}, zipcode: #{session["geo.zip"]}, latitude: #{session["geo.lat"]}, longitude: #{session["geo.lon"]}\n"
      env['rack.errors'].write "GEO LINK - #{session["geo.link"]}\n"
    end

    def call_geo_api(remote_address)
      url = URI.parse(GEO_API_URL + remote_address)
      puts "GEO API CALL - #{url.to_s}"
      req = Net::HTTP::Get.new(url.to_s)
      res = Net::HTTP.start(url.host, url.port) do |http|
        http.request(req)
      end
      JSON.parse(res.body)
    end
  end
end
