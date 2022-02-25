# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'pg'

class Data
  db = 'memo'
  user = 'yokonari'
  password = 'app'
  CONNECTION = PG.connect(dbname: db, user: user, password: password)

  def self.show
    CONNECTION.exec(
      "create table if not exists memos
      (id serial not null primary key,
      title text not null,
      body text);
      select id,title from memos;"
    )
  end

  def self.read(id)
    CONNECTION.exec_params(
      'select * from memos where id = $1;', [id]
    )
  end

  def self.write(params)
    title = params[:title]
    body = params[:body]

    CONNECTION.exec_params(
      "insert into memos(title,body) values ($1, $2)
      returning id;",
      [title, body]
    )
  end

  def self.edit(id, params)
    title = params[:title]
    body = params[:body]

    CONNECTION.exec_params(
      "update memos set
      title = $1, body = $2 where id = $3;",
      [title, body, id]
    )
  end

  def self.delete(id)
    CONNECTION.exec_params(
      'delete from memos where id = $1;',
      [id]
    )
  end
end

def assign_to_instance(result)
  result.each do |row|
    @id = row['id']
    @title = row['title']
    @body = row['body']
  end
end

get '/memos' do
  @memos_all = Data.show
  erb :index
end

get '/memos/new' do
  erb :new
end

post '/memos/new' do
  result = Data.write(params)
  result.each do |row|
    id = row['id']
    redirect "/memos/#{id.to_i}"
  end
end

get '/memos/edit/*' do |id|
  result = Data.read(id)
  assign_to_instance(result)
  erb :edit
end

patch '/memos/*' do |id|
  Data.edit(id, params)
  redirect "/memos/#{id.to_i}"
end

get '/memos/*' do |id|
  result = Data.read(id)
  assign_to_instance(result)
  redirect 404 if @id.empty?
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
