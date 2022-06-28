# frozen_string_literal: true

require 'uri'
require 'http'

module Magento
  class Request
    ALLOW_SELF_SIGNED_SSL_CERTS_ENV_VAR = 'MAGENTO_ALLOW_SELF_SIGNED_SSL_CERT_ENABLED'.freeze

    attr_reader :config

    def initialize(config: Magento.configuration)
      @config = config
    end

    def get(resource)
      save_request(:get, url(resource))
      handle_error http_auth.get(url(resource), request_params)
    end

    def put(resource, body)
      save_request(:put, url(resource), body)
      handle_error http_auth.put(url(resource), request_params(json: body))
    end

    def post(resource, body = nil, url_completa = false)
      url = url_completa ? resource : url(resource)
      save_request(:post, url, body)
      handle_error http_auth.post(url, request_params(json: body))
    end

    def delete(resource)
      save_request(:delete, url(resource))
      handle_error http_auth.delete(url(resource), request_params)
    end

    private

    def request_params(params = {})
      params.merge!(ssl_context: no_ssl_context) if allow_self_signed_ssl_certificates?

      params
    end

    def no_ssl_context
      context = OpenSSL::SSL::SSLContext.new
      context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      context
    end

    def allow_self_signed_ssl_certificates?
      ENV.fetch(ALLOW_SELF_SIGNED_SSL_CERTS_ENV_VAR, false).to_s.downcase == 'true'
    end

    def http_auth
      HTTP.auth("Bearer #{config.token}")
          .timeout(connect: config.timeout, read: config.open_timeout)
    end

    def base_url
      url = config.url.to_s.sub(%r{/$}, '')
      "#{url}/rest/#{config.store}/V1"
    end

    def url(resource)
      "#{base_url}/#{resource}"
    end

    def handle_error(resp)
      return resp if resp.status.success?

      begin
        msg = resp.parse['message']
        errors = resp.parse['errors'] || resp.parse['parameters']
        case errors
        when Hash
          errors.each { |k, v| msg.sub! "%#{k}", v }
        when Array
          errors.each_with_index { |v, i| msg.sub! "%#{i + 1}", v.to_s }
        end
      rescue StandardError
        msg = 'Failed access to the magento server'
        errors = []
      end

      raise Magento::NotFound.new(msg, resp.status.code, errors, @request) if resp.status.not_found?

      raise Magento::MagentoError.new(msg, resp.status.code, errors, @request)
    end

    def save_request(method, url, body = nil)
      begin
        body = body.symbolize_keys[:product].reject { |e| e == :media_gallery_entries }
      rescue StandardError
      end

      @request = { method: method, url: url, body: body }
    end
  end
end
