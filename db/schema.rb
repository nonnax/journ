require 'sequel'
DB=Sequel.sqlite 'journ-test.sqlite3'
DB.create_table(:topics) do
  primary_key :id
  String :topic
  DateTime :created_at
end
DB.create_table(:posts) do
  primary_key :id
  String :post
  Integer :parent_id, :default=>0
  String  :path
  DateTime :created_at
  DateTime :updated_at
end
DB.create_table(:postings) do
  primary_key :id
  Integer :topic_id, :default=>0
  Integer :post_id,  :default=>0
  DateTime :created_at
end
DB.create_table(:relationships) do
   primary_key :id
  Integer :topic_id, :default=>0
  Integer :following_id, :default=>0
  DateTime :created_at
end