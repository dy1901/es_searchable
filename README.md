
# es_searchable 
es_searchable implemented an ActiveRecord like search api for Elasticsearch. 

## Install 

`gem 'es_searchable', git: 'git@github.com:rongchain/es_searchable.git'`

or

`gem install es_searchable`

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

## Use es_searchable

```ruby
class User
  include EsSearchable
end

search_collection = User.es_where(id: 1)
pp search_collection
=> #<EsSearchable::SearchCollection:0x007fa64361be08
 @conditions=
  {:query=>{:filtered=>{:filter=>{:bool=>{:must=>[{:term=>{:id=>1}}]}}}}},
 @klass=User>

search_collection.class
 => EsSearchable::SearchCollection

search_params = search_collection.search_params
 => {:query=>{:filtered=>{:filter=>{:bool=>{:must=>[{:term=>{:id=>1}}]}}}}}
```

call `load` on `search_collection` to perform the search

```ruby
search_response = search_collection.load     #perform search
pp search_response
=> #<EsSearchable::SearchCollection:0x007fa64288bf18
 @collections=
  [{"id"=>1,
    "name"=>"Arnaldo Powlowski PhD",
    "email"=>"charley_walsh@weber.co.uk",
    "created_at"=>"2016-03-04T06:47:58.999Z",
    "updated_at"=>"2016-03-04T06:47:58.999Z",
    "is_admin"=>true}],
 @conditions=
  {:query=>{:filtered=>{:filter=>{:bool=>{:must=>[{:term=>{:id=>1}}]}}}},
   :fields=>{}},
 @count=1,
 @klass=User,
 @response=
  {"took"=>1,
   "timed_out"=>false,
   "_shards"=>{"total"=>1, "successful"=>1, "failed"=>0},
   "hits"=>
    {"total"=>1,
     "max_score"=>1.0,
     "hits"=>
      [{"_index"=>"users",
        "_type"=>"user",
        "_id"=>"1",
        "_score"=>1.0,
        "_source"=>
         {"id"=>1,
          "name"=>"Arnaldo Powlowski PhD",
          "email"=>"charley_walsh@weber.co.uk",
          "created_at"=>"2016-03-04T06:47:58.999Z",
          "updated_at"=>"2016-03-04T06:47:58.999Z",
          "is_admin"=>true}}]}},
 @time=1>

pp search_response.collections     #return search results as an Array of hash
=> [{"id"=>1,
  "name"=>"Arnaldo Powlowski PhD",
  "email"=>"charley_walsh@weber.co.uk",
  "created_at"=>"2016-03-04T06:47:58.999Z",
  "updated_at"=>"2016-03-04T06:47:58.999Z",
  "is_admin"=>true}}]

search_response.time      #time consumed by the search
 => 1

search_response.count      #count of search results
 => 1

pp search_response.response       #response hash from elasticsearch
=> {"took"=>1,
 "timed_out"=>false,
 "_shards"=>{"total"=>1, "successful"=>1, "failed"=>0},
 "hits"=>
  {"total"=>1,
   "max_score"=>1.0,
   "hits"=>
    [{"_index"=>"users",
      "_type"=>"user",
      "_id"=>"1",
      "_score"=>1.0,
      "_source"=>
       {"id"=>1,
        "name"=>"Arnaldo Powlowski PhD",
        "email"=>"charley_walsh@weber.co.uk",
        "created_at"=>"2016-03-04T06:47:58.999Z",
        "updated_at"=>"2016-03-04T06:47:58.999Z",
        "is_admin"=>true}}}]}}
```

### #es_where
```ruby
# Like ActiveRecord, es_searchable use es_where for exact matching, 
pp User.es_where(id: 1).load.collections
=> [{"id"=>1,
  "name"=>"Arnaldo Powlowski PhD",
  "email"=>"charley_walsh@weber.co.uk",
  "created_at"=>"2016-03-04T06:47:58.999Z",
  "updated_at"=>"2016-03-04T06:47:58.999Z",
  "is_admin"=>true}}]

pp User.es_where(id: [1,2]).load.collections
=> [{"id"=>1,
  "name"=>"Arnaldo Powlowski PhD",
  "email"=>"charley_walsh@weber.co.uk",
  "created_at"=>"2016-03-04T06:47:58.999Z",
  "updated_at"=>"2016-03-04T06:47:58.999Z",
  "is_admin"=>true}},
 {"id"=>2,
  "name"=>"Chanel Robel",
  "email"=>"wilma@rice.com",
  "created_at"=>"2016-03-04T06:47:59.008Z",
  "updated_at"=>"2016-03-04T06:47:59.008Z",
  "is_admin"=>false}}]

# #es_where with multiple search conditions
User.es_where(id: 1, is_admin: false).load.collections
=> []

pp User.es_where(id: 1, is_admin: true).load.collections
=> [{"id"=>1,
  "name"=>"Arnaldo Powlowski PhD",
  "email"=>"charley_walsh@weber.co.uk",
  "created_at"=>"2016-03-04T06:47:58.999Z",
  "updated_at"=>"2016-03-04T10:03:39.102Z",
  "is_admin"=>true}]
```

### #es_select
```ruby
# use es_select to select the attribtues you want
pp User.es_where(id: 1).es_select(:id,:name).load.collections
=> [{"id"=>1, "name"=>"Arnaldo Powlowski PhD"},
 {"id"=>2, "name"=>"Chanel Robel"}]
```

### #es_like
```ruby
# use es_like to perform keyword matching
pp User.es_like(name: 'Mr. Su').select(:name).load.collections
=> [{"name"=>"Mr. Marquise Goodwin"},
 {"name"=>"Mr. Stephanie Carter"},
 {"name"=>"Mr. Susana Jerde"},
 {"name"=>"Mrs. Earline Thompson"},
 {"name"=>"Mrs. Eunice Bergnaum"}]
pp User.es_like(name: 'Mr. Su').select(:name).search_params
=> {:query=>
  {:filtered=>{:query=>{:bool=>{:must=>[{:match=>{:name=>"Mr. Su"}}]}}}},
 :fields=>[:name]}

pp User.es_like(name: {or: 'Mr. Su'}).select(:name).load.collections
=> [{"name"=>"Mr. Marquise Goodwin"},
 {"name"=>"Mr. Stephanie Carter"},
 {"name"=>"Mr. Susana Jerde"},
 {"name"=>"Mrs. Earline Thompson"},
 {"name"=>"Mrs. Eunice Bergnaum"}]
pp User.es_like(name: {or: 'Mr. Su'}).select(:name).search_params
=> {:query=>
  {:filtered=>
    {:query=>
      {:bool=>
        {:must=>[{:match=>{:name=>{:operator=>:or, :query=>"Mr. Su"}}}]}}}},
 :fields=>[:name]}

pp User.es_like(name: {and: 'Mr. Su'}).select(:name).load.collections
=> []
pp User.es_like(name: {and: 'Mr. Su'}).select(:name).search_params
=> {:query=>
  {:filtered=>
    {:query=>
      {:bool=>
        {:must=>[{:match=>{:name=>{:operator=>:and, :query=>"Mr. Su"}}}]}}}},
 :fields=>[:name]}
```
### #use :like in #es_where
```ruby
# the following search are equal
User.es_like(name: "test").es_where(id:1)
User.es_where(id:1, name: {like: "test"})

pp User.es_where(id: 1, email: {like: 'charley_walsh'}).select(:id,:email).load.collections
=> [{"id"=>1, "email"=>"charley_walsh@weber.co.uk"}]
pp User.es_where(id: 1).es_like(email: 'charley_walsh').select(:id,:email).load.collections
=> [{"id"=>1, "email"=>"charley_walsh@weber.co.uk"}]

```
### #es_or, #es_and
```
# use es_or to perform OR condition search
User.es_or(id:2, is_admin: true).select(:id,:is_admin).load.collections
=> [{"id"=>1, "is_admin"=>true}, {"id"=>2, "is_admin"=>false}]

# use es_and to perform AND condition search
User.es_and(id:2, is_admin: true).select(:id,:is_admin).load.collections
=> []
User.es_and(id:1, is_admin: true).select(:id,:is_admin).load.collections
=> [{"id"=>1, "is_admin"=>true}]

# es_and is alias of es_where
```

### #es_or and #es_where for nested condition search
```ruby
User.es_and(id: 1, or: {email: {like: 'brennon'}, is_admin: true})
# the condictions of the search above is  
tel=18510705036 and ( email like 'edaixi.com' or is_admin=true)
```

### #es_not
```ruby
#use es_not to perform not equal condition search
User.es_where({}).load.count
=> 100
User.es_not({id: 1}).load.count
=> 99
```

### #range search
```ruby
# use the following syntax to perform range search
User.es_where(id: {lt: 3, gt:1  }).select(:id).load.collections
 => [{"id"=>2}]

User.es_where(id: {lte: 2, gte: 1 }).select(:id).load.collections
 => [{"id"=>1}, {"id"=>2}]

#   lt   =>    less than   <
#   gt  =>    greater than >
#   lte =>    less than equal  <= 
#   gte =>   greater than equal >=

### #es_limit and #es_offset

# es_limit and es_offset work the same as limit and offset methods of ActiveRecor

User.es_where({}).select(:id).limit(3).load.collections
 => [{"id"=>1}, {"id"=>2}, {"id"=>3}]

User.es_where({}).select(:id).limit(3).offset(2).load.collections
 => [{"id"=>3}, {"id"=>4}, {"id"=>5}]
```

### *_like, *_between, *_gt, *_lt, *_gte, *_lte
```ruby
User.name_like('test')   <=>    User.like(name: 'test')
User.id_lte(10)          <=>    User.lte(id: 10)
User.id_between(1,3)     <=>    User.where(id: {gte: 1, lte: 2})
```
