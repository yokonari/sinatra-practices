# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'pg'

class Memo
  db = ENV['PGDATABASE']
  user = ENV['PGUSER']
  password = ENV['PGPASSWORD']
  CONNECTION = PG.connect(dbname: db, user: user, password: password)

  def self.create_table
    CONNECTION.exec(
      "create table if not exists memos
      (id serial not null primary key,
      title text not null,
      body text);"
    )
  end

  def self.all
    CONNECTION.exec(
      'select id,title from memos;'
    )
  end

  def self.read(id)
    CONNECTION.exec_params(
      'select * from memos where id = $1;', [id]
    )
  end

  def self.new(params)
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
  array = []
  result.each do |row|
    array << row['id'] << row['title'] << row['body']
  end
  @memo = %w[id title body].zip(array).to_h
end

before '/memos' do
  Memo.create_table
end

get '/memos' do
  @memos_all = Memo.all
  erb :index
end

get '/memos/new' do
  erb :new
end

post '/memos/new' do
  result = Memo.new(params)
  result.each do |row|
    id = row['id']
    redirect "/memos/#{id.to_i}"
  end
end

get '/memos/edit/*' do |id|
  result = Memo.read(id)
  assign_to_instance(result)
  erb :edit
end

patch '/memos/*' do |id|
  Memo.edit(id, params)
  redirect "/memos/#{id.to_i}"
end

get '/memos/*' do |id|
  result = Memo.read(id)
  assign_to_instance(result)
  redirect 404 if @memo['id'].empty?
  erb :memo
end

delete '/memos/*' do |id|
  Memo.delete(id)
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
