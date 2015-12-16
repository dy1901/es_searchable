module EsSearchable
	class IndexerCreator
		def self.create(_model)
			indexer = Class.new do

				cattr_accessor :model
				self.model = _model

				include Sidekiq::Worker
				sidekiq_options queue: EsSearchable.queue, retry: false

				def perform(operation, record_id, changed)
					logger.debug [operation, model.to_s, "ID: #{record_id}", changed]

					model = self.class.model
					index = model.index
					client = model.client
					type = model.to_s.underscore

					case operation.to_s
					when /index/
						record = model.find(record_id)
						client.index(
							type: type,
							index: index,
							id: record_id,
							body: record.as_indexed_json
						)
					when /delete/
						client.delete index: index, type: type, id: record_id
					else
						raise ArgumentError, "Unknown operation '#{operation}'"
					end
				end
			end

			EsSearchable.const_set "#{_model}Indexer", indexer
		end
	end
end
