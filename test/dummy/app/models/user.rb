class User < ActiveRecord::Base
  # include Elasticsearch::Model

  # settings index: { number_of_shards: 1 } do
  #   mappings dynamic: 'false' do
  #     indexes :id, type: 'integer'
  #     indexes :is_admin, type: 'boolean', index: 'not_analyzed'
  #     indexes :name, type: 'string', dynamic: 'standard'
  #     indexes :email, type: 'string', dynamic: 'standard'
  #   end
  # end

  include EsSearchable
end
