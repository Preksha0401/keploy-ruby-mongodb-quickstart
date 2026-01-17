require "sinatra"
require "mongo"
require "json"

set :bind, "0.0.0.0"
set :port, 4567   # or any free port like 3000, 8080, 9292

mongo_url = ENV["MONGO_URL"] || "mongodb://localhost:27017"
client = Mongo::Client.new("#{mongo_url}/keploy_todos")
todos = client[:todos]

before do
  content_type :json
end

get "/health" do
  { status: "ok" }.to_json
end

post "/todos" do
  body = JSON.parse(request.body.read)
  result = todos.insert_one({ title: body["title"], done: false })
  { message: "Todo created", id: result.inserted_id.to_s }.to_json
end

get "/todos" do
  list = todos.find.map do |t|
    { id: t["_id"].to_s, title: t["title"], done: t["done"] }
  end
  { todos: list }.to_json
end

get "/todos/:id" do
  todo = todos.find(_id: BSON::ObjectId(params[:id])).first
  halt 404, { error: "Todo not found" }.to_json unless todo
  { id: todo["_id"].to_s, title: todo["title"], done: todo["done"] }.to_json
end

put "/todos/:id" do
  body = JSON.parse(request.body.read)
  result = todos.update_one(
    { _id: BSON::ObjectId(params[:id]) },
    { "$set" => { title: body["title"], done: body["done"] } }
  )
  halt 404, { error: "Todo not found" }.to_json if result.matched_count == 0
  { message: "Todo updated" }.to_json
end

delete "/todos/:id" do
  result = todos.delete_one(_id: BSON::ObjectId(params[:id]))
  halt 404, { error: "Todo not found" }.to_json if result.deleted_count == 0
  { message: "Todo deleted" }.to_json
end