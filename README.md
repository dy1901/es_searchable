# es_searchable 
es_searchable implemented an ActiveRecord like search api for Elasticsearch. 

## Install 

`gem 'es_searchable', git: 'git@github.com:rongchain/es_searchable.git', tag: 'v0.0.6'`

And then execute: 

`bundle`

## Configure 

```ruby

# config/initializers/es_searchable.rb

EsSearchable.configure do |config|
  config.logger = Logger.new("log/es_searchable.log")
  config.hosts = ["localhost:9200"]
end

```

## Use es_searchable with Zombie 

### #es_where
```ruby
# Like ActiveRecord, es_searchable use es_where for exact matching, 

Zombie::Courier.es_where(tel: 18510705036).load
# => [#<Zombie::Courier:0x007f8ec80c0a90 @id=7, @realname="韩佳明-离职", @password="hanjiaming", @tel="18510705036", @outlet_id=16, @status=true, @push_token="a367e9c4-d38f-4013-8101-766fcc0efc08", @created_at="2014-10-28T11:16:13.000+08:00", @updated_at="2015-04-18T01:25:35.000+08:00", @city="北京", @kind=0, @polygon_group_id=2484, @use_auto_schedule=true, @bank_card="", @id_number="", @bank_name="", @saofen=true, @shouka=true, @jiedan=true, @unique_number="001000000007", @start_time=nil, @end_time=nil, @channel="com.1.wuliu", @luxury_logistic=false, @city_id=1, @zhuanyun=false, @client_name="android_client", @is_zhongtui=false, @is_employee=false, @close_time=nil, @kuaixi=false, @street_name=nil, @gender=nil, @service_time_type=nil, @catch_reasons=nil, @edaixi_nr=nil, @is_zancun=nil, @is_owner=nil, @yizhan_id=nil, @is_van=nil, @songyao=false>]

# call total_entries to get all count of matched records
Zombie::Courier.es_where(tel: 18510705036).load.total_entries 
# => 1

# when you pass an empty hash to es_where then it will return all records 
Zombie::Courier.es_where({}).load.total_entries
# => 2579

# when you pass a hash with an array value, es_where will perform a sql like in search
Zombie::Courier.es_where(id: [7,11]).select(:realname, :id).load
# => [#<Zombie::Courier:0x007f81658f20f8 @id=[11], @realname=["上海"]>, #<Zombie::Courier:0x007f81658f2080 @id=[7], @realname=["韩佳明-离职"]>]
```
### #es_select
```ruby
# use es_select to select the attribtues you want
Zombie::Courier.es_where(tel: 18510705036).es_select(:id,:tel).load 
#  => [#<Zombie::Courier:0x007f8ec808ba20 @id=[7], @tel=["18510705036"]>]
```
### #es_like
```ruby
# use es_like to perform keyword matching
Zombie::Courier.es_like(realname: "韩").select(:realname).load
# => [#<Zombie::Courier:0x007f8ec2362920 @realname=["SZ-WL韩强强"]>, #<Zombie::Courier:0x007f8ec23628d0 @realname=["SZ_ZB韩强强"]>, #<Zombie::Courier:0x007f8ec2362880 @realname=["韩璐（不做了）"]>, #<Zombie::Courier:0x007f8ec2362830 @realname=["BJ-ZB-JXQ韩敏"]>, #<Zombie::Courier:0x007f8ec23627e0 @realname=["韩佳俊-离职"]>, #<Zombie::Courier:0x007f8ec2362790 @realname=["BJ-ZB-YYC韩微"]>, #<Zombie::Courier:0x007f8ec2362740 @realname=["TJ-ZB韩国民"]>, #<Zombie::Courier:0x007f8ec23626f0 @realname=["BJ-WL-JXQ韩得利"]>, #<Zombie::Courier:0x007f8ec23626a0 @realname=["韩佳明-离职"]>, #<Zombie::Courier:0x007f8ec2362650 @realname=["TJ-WL韩立洺"]>]

Zombie::Courier.es_like(realname: { and: "zuozuo"} )
# {
# 	:query => {
# 		:filtered => {
# 			:query => {
# 				:bool => {
# 					:must => [
# 						[0] {
# 							:match => {
# 								:realname => {
# 									:operator => :and,
# 									:query => "zuozuo"
# 								}
# 							}
# 						}
# 					]
# 				}
# 			}
# 		}
# 	}
# }

```
### #use :like in #es_where
```ruby
# the following search are equal
Zombie::Courier.es_like(realname: "韩").es_where(id:1)
Zombie::Courier.es_where(id:1, id: {like: "韩"})

Zombie::Courier.es_where(realname: {like:  { and: "zuozuo"} }).search_params
# {
# 	:query => {
# 		:filtered => {
# 			:query => {
# 				:bool => {
# 					:must => [
# 						[0] {
# 							:match => {
# 								:realname => {
# 									:operator => :and,
# 									:query => "zuozuo"
# 								}
# 							}
# 						}
# 					]
# 				}
# 			}
# 		}
# 	}
# }

```
### #es_or
```
# use es_or to perform OR condition search
 Zombie::Courier.es_or(tel: 18510705036, id: 11).select(:id, :tel).load
# => [#<Zombie::Courier:0x007f8ebdef4e78 @id=[11], @tel=["18019242010"]>, #<Zombie::Courier:0x007f8ebdef4dd8 @id=[7], @tel=["18510705036"]>]
```

### #es_or and #es_where for nested condition search
```ruby
# use es_where or es_and to perform and condition search, es_and and es_where are alias methods
Zombie::Courier.es_and(tel: 18510705036, or: {email: {like: 'edaixi.com'}, is_admin: true})
# the condictions of the search above is  
tel=18510705036 and ( email like 'edaixi.com' or is_admin=true)
```
### #es_not
```ruby
#use es_not to perform not equal condition search
Zombie::Courier.es_where({}).load.total_entries
#  => 2579
Zombie::Courier.es_not({id: 7}).load.total_entries
#  => 2578
```
### #search_params
```ruby
# call search_params to get search_params of elasticsearch
Zombie::Courier.es_where({id: 7}).search_params
# => {:query=>{:filtered=>{:filter=>{:bool=>{:must=>[{:term=>{:id=>7}}]}}}}}
```
### #load_json
```ruby
# call load_json to get json response of elasticsearch
Zombie::Courier.es_where({id: 7}).load_json
# => {"took"=>1, "timed_out"=>false, "_shards"=>{"total"=>5, "successful"=>5, "failed"=>0}, "hits"=>{"total"=>1, "max_score"=>1.0, "hits"=>[{"_index"=>"couriers", "_type"=>"courier", "_id"=>"7", "_score"=>1.0, "_source"=>{"id"=>7, "realname"=>"韩佳明-离职", "password"=>"hanjiaming", "tel"=>"18510705036", "outlet_id"=>16, "status"=>true, "push_token"=>"a367e9c4-d38f-4013-8101-766fcc0efc08", "created_at"=>"2014-10-28T11:16:13.000+08:00", "updated_at"=>"2015-04-18T01:25:35.000+08:00", "city"=>"北京", "kind"=>0, "polygon_group_id"=>2484, "use_auto_schedule"=>true, "bank_card"=>"", "id_number"=>"", "bank_name"=>"", "saofen"=>true, "shouka"=>true, "jiedan"=>true, "unique_number"=>"001000000007", "start_time"=>nil, "end_time"=>nil, "channel"=>"com.1.wuliu", "luxury_logistic"=>false, "city_id"=>1, "zhuanyun"=>false, "client_name"=>"android_client", "is_zhongtui"=>false, "is_employee"=>false, "close_time"=>nil, "kuaixi"=>false, "street_name"=>nil, "gender"=>nil, "service_time_type"=>nil, "catch_reasons"=>nil, "edaixi_nr"=>nil, "is_zancun"=>nil, "is_owner"=>nil, "yizhan_id"=>nil, "is_van"=>nil, "songyao"=>false}}]}}
```
### #range search
```ruby
# use the following syntax to perform range search
Zombie::Courier.es_where(id: {lt: 202, gt: 200 }).select(:id).load
# => [#<Zombie::Courier:0x007f815d529348 @id=[201]>]
Zombie::Courier.es_where(id: {lte: 202, gte: 200 }).select(:id).load
#=> [#<Zombie::Courier:0x007f815d5a0ec0 @id=[201]>, #<Zombie::Courier:0x007f815d5a0e70 @id=[202]>, #<Zombie::Courier:0x007f815d5a0e20 @id=[200]>]

#   lt   =>    less than   <
#   gt  =>    greater than >
#   lte =>    less than equal  <= 
#   gte =>   greater than equal >=


# es_limit and es_offset work the same as limit and offset methods of ActiveRecord

Zombie::Courier.es_where(id: {lt: 210, gte: 200 }).select(:id).load
# => [#<Zombie::Courier:0x007f815b59f860 @id=[201]>, #<Zombie::Courier:0x007f815b59f608 @id=[206]>, #<Zombie::Courier:0x007f815b59f4f0 @id=[202]>, #<Zombie::Courier:0x007f815b59f478 @id=[207]>, #<Zombie::Courier:0x007f815b59f428 @id=[203]>, #<Zombie::Courier:0x007f815b59f3b0 @id=[208]>, #<Zombie::Courier:0x007f815b59f310 @id=[204]>, #<Zombie::Courier:0x007f815b59f1d0 @id=[209]>, #<Zombie::Courier:0x007f815b59f108 @id=[200]>, #<Zombie::Courier:0x007f815b59ee88 @id=[205]>]

Zombie::Courier.es_where(id: {lt: 210, gte: 200 }).select(:id).limit(3).load
# => [#<Zombie::Courier:0x007f815b74cb90 @id=[201]>, #<Zombie::Courier:0x007f815b74ca78 @id=[206]>, #<Zombie::Courier:0x007f815b74c988 @id=[202]>]

Zombie::Courier.es_where(id: {lt: 210, gte: 200 }).select(:id).limit(3).offset(2).load
 => [#<Zombie::Courier:0x007f815bbe55d0 @id=[202]>, #<Zombie::Courier:0x007f815bbe54b8 @id=[207]>, #<Zombie::Courier:0x007f815bbe5328 @id=[203]>]

```
### #paginate
```ruby
# methods form paginate 
Zombie::Courier.es_where(id: {lt: 210, gte: 200 }).select(:id).limit(3).offset(2).load.current_page
# => 1
Zombie::Courier.es_where(id: {lt: 210, gte: 200 }).select(:id).limit(3).offset(2).load.total_pages
# => 4

```

## Use es_searchable with ActiveRecord

```
class Courier < ActiveRecord::Base
  include EsSearchable
end
```

`Courier` is an ActiveRecord model, and include `EsSearchable`, then you can use es_search on `Courier`

```ruby
search_collection = Courier.es_where(tel: 18510705036)
```
the return value `search_collection` is an `EsSearchable::SearchCollection` object

call `search_params` on `EsSearchable::SearchCollection` object will return the `search_params` used to search on elasticsearch servers. 

```ruby
search_params = search_collection.search_params    

# {
#     :query => {
#         :filtered => {
#             :filter => {
#                 :bool => {
#                     :must => [
#                         [0] {
#                             :term => {
#                                 :tel => 18510705036
#                             }
#                         }
#                     ]
#                 }
#             }
#         }
#     }
# }

```

If you want the result of elasticsearch, call `load` on the `EsSearchable::SearchCollection` object

```
search_response = search_collection.load

# => #<Elasticsearch::Model::Response::Response:0x007f8ebb4a5b40 @klass=[PROXY] Courier(id: integer, realname: string, password: string, tel: string, outlet_id: integer, status: boolean, push_token: string, created_at: datetime, updated_at: datetime, city: string, kind: integer, polygon_group_id: integer, use_auto_schedule: boolean, bank_card: string, id_number: string, bank_name: string, saofen: boolean, shouka: boolean, jiedan: boolean, unique_number: string, start_time: date, end_time: date, channel: string, luxury_logistic: boolean, city_id: integer, zhuanyun: boolean, client_name: string, is_zhongtui: boolean, is_employee: boolean, close_time: datetime, kuaixi: boolean, street_name: string, gender: string, service_time_type: string, catch_reasons: string, edaixi_nr: string, is_zancun: integer, is_owner: integer, yizhan_id: integer, is_van: boolean, songyao: boolean, contract_version: integer, contract_version_end_time: integer), @search=#<Elasticsearch::Model::Searching::SearchRequest:0x007f8ebb4a66f8 @klass=[PROXY] Courier(id: integer, realname: string, password: string, tel: string, outlet_id: integer, status: boolean, push_token: string, created_at: datetime, updated_at: datetime, city: string, kind: integer, polygon_group_id: integer, use_auto_schedule: boolean, bank_card: string, id_number: string, bank_name: string, saofen: boolean, shouka: boolean, jiedan: boolean, unique_number: string, start_time: date, end_time: date, channel: string, luxury_logistic: boolean, city_id: integer, zhuanyun: boolean, client_name: string, is_zhongtui: boolean, is_employee: boolean, close_time: datetime, kuaixi: boolean, street_name: string, gender: string, service_time_type: string, catch_reasons: string, edaixi_nr: string, is_zancun: integer, is_owner: integer, yizhan_id: integer, is_van: boolean, songyao: boolean, contract_version: integer, contract_version_end_time: integer), @options={}, @definition={:index=>"couriers", :type=>"courier", :body=>{:query=>{:filtered=>{:filter=>{:bool=>{:must=>[{:term=>{:tel=>18510705036}}]}}}}}}>>

```
the `search_response` is an `Elasticsearch::Model::Response::Response` object, and when you include es_searchable in an ActiveRecord model it will use gem `elasticsearch-model`(https://github.com/elastic/elasticsearch-rails/tree/master/elasticsearch-model) internally to perform search. So for more details of the response object please see doc  of `elasticsearch-model`  here   http://www.rubydoc.info/gems/elasticsearch-model
