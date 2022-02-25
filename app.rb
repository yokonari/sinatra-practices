# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'

class Data
  def self.read(id)
    File.open("./json/memos#{id.to_i}.json", 'r') do |file|
      JSON.parse(file.read, symbolize_names: true)
    end
  end

  def self.write(id, params)
    data = {
      id: id,
      title: params[:title],
      body: params[:body]
    }
    memo_json = data.to_json

    File.open("./json/memos#{id.to_i}.json", 'w') do |file|
      file.puts(memo_json.to_s)
    end
  end

  def self.delete(id)
    File.delete("./json/memos#{id.to_i}.json")
  end
end

def assign_to_instance(memo)
  @id = memo[:id]
  @title = memo[:title]
  @body = memo[:body]
end

get '/memos' do
  memos = Dir.glob('./json/*.json')
  @memos_all = memos.map do |file|
    File.open(file.to_s, 'r') do |memo|
      JSON.parse(memo.read, symbolize_names: true)
    end
  end
  erb :index
end

get '/memos/new' do
  erb :new
end

post '/memos/new' do
  id = if Dir.empty?('./json')
         1
       else
         Dir.glob('./json/*.json').max.delete('^0-9').to_i + 1
       end

  Data.write(id, params)
  redirect "/memos/#{id.to_i}"
end

get '/memos/edit/*' do |id|
  memo = Data.read(id)
  assign_to_instance(memo)
  erb :edit
end

patch '/memos/*' do |id|
  Data.write(id, params)
  redirect "/memos/#{id.to_i}"
end

get '/memos/*' do |id|
  memo = Data.read(id)
  assign_to_instance(memo)
  erb :memo
end

delete '/memos/*' do |id|
  Data.delete(id)
  redirect '/memos'
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

set :show_exceptions, :after_handler

error 400..510 do
  erb :oops
end
