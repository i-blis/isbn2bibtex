#!/usr/bin/env ruby -wKU

require 'rubygems'
require 'sinatra'

$: << File.join(File.dirname(__FILE__), 'lib')
require 'amazon/ecs'
require 'amazon/book'


set :port, 8080

get '/' do
  haml :index
end

post "*" do
  redirect "/#{params[:choice]}/#{params[:isbn]}"
end

get '/:action/:isbn' do
  pass unless %r{(\b\d{9}[\w|\d]\b)+}.match(params[:isbn])
  pass unless params[:action] == 'preview' || 'download'
  @books = []
  params[:isbn].split("\s").each do |isbn|
    book = Amazon::Book.new(isbn)
    next unless book.defined?
    @books << book
  end
  @isbn = params[:isbn]
  case params[:action]
    when 'preview'
      haml :htmlbib
    when 'download'
      content_type 'application/text', :charset => 'utf-8'
      haml :textbib, :layout => false
    else
      redirect '/'
  end
end

# get %r{/(\b\d{9}[\w|\d]\b)+} do
#   redirect '/get/' + params[:captures].first
# end
    
get '/styles/main.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :main
end

get '/images/:image.:ext' do
  filename = File.dirname(__FILE__) + "/images/#{params[:image]}.#{params[:ext]}"
  send_file filename, :type => "image/#{params[:ext]}"  
end


get "/*" do
  redirect '/'
end

