module EsSearchable
	module Configurable
		def self.extended(base)
			base.const_set :SearchMethods,
				[:where, :like, :limit, :offset, :or, :not, :select, :and]
			
			base.const_set :DEFAULTS, { 
				log: true,
				retry_on_failure: 5, 
				async_callback: true,
				queue: 'elasticsearch',
				reload_on_failure: true, 
				hosts: ['localhost:9200'], 
				logger: defined?(Rails) ? Logger.new($stdout) : nil,
			}
				
			base.class_eval do
				DEFAULTS.each do |k, v|
					self.define_singleton_method "#{k}=" do |value|
						self.options.merge!(k => value)
					end

					self.define_singleton_method k do
						self.options[k]
					end
				end
			end
		end

		def configure
			yield self
		end

		def options
			@options ||= DEFAULTS.dup
		end

		def options=(opts)
			@options = opts
		end

	end
end
