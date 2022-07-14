module Boop
  class CacheStore
    CACHE_TTL = 125.seconds # slightly more than 2 minutes
    RACE_CONDITION_TTL = 5.seconds

    ConnectionError = Class.new(StandardError)

    @@cache = ActiveSupport::Cache::RedisCacheStore.new(
      namespace: "boop",
      expires_in: CACHE_TTL,
      race_condition_ttl: RACE_CONDITION_TTL,
      reconnect_attempts: 1,
      url: ENV["redis_url"],
      error_handler: -> (method:, returning:, exception:) {
        if Redis::BaseConnectionError === exception
          raise ConnectionError
        end
      }
    )

    attr_reader :nonce

    def self.store(thing)
      @@cache.write(thing, "")
    rescue ConnectionError
      nil
    end

    def self.consume(thing)
      if @@cache.exist?(thing)
        @@cache.delete(thing)
        true
      else
        false
      end
    rescue ConnectionError
      true # fail closed if Redis becomes unavailable
    end
  end
end
