#!/usr/bin/env ruby -wKU

require 'rubygems'
require 'sinatra'

$: << File.join(File.dirname(__FILE__), 'lib')
require 'amazon/ecs'
require 'amazon/book'


template = <<'END_TEMPLATE'
@book{<%= isbn %>,<br>
% %w(author editor title year publisher cover date isbn description).each do |var|
%   unless (eval var).empty? then 
<%= "\s\s#{var} = {#{eval var}}," %><br>
%   end
% end
}
END_TEMPLATE


set :port, 8080

get '/' do
  haml :index
end

# post '/' do
# end

get '/hello' do
  @time = "Hello world, it's #{Time.now} at the server!"  
  haml :hello
end

get %r{/\b(\d{9}[\w|\d])\b/view} do
  book = Amazon::Book.new(params[:captures].first)
  @bibtex = book.populate(template) 
  haml :htmlbib
end


get %r{/\b(\d{9}[\w|\d])\b} do
  book = Amazon::Book.new(params[:captures].first)
  @bibtex = book.populate(template).gsub(%r{</?[^>]+?>}, '')
  content_type 'application/text', :charset => 'utf-8'
  
  haml :bibtex, layout => false
end

use_in_file_templates!

__END__

@@ layout
%html
  %head
    %title Get BibTeX record from ISBN number
  %body
    #container
      = yield

@@ index
%p= @time

@@ hello
%p= @time

@@ htmlbib
%div{ :style => 'width: 600px; font-family: monospace'}
  %p= @bibtex

@@ bibtex
=@bibtex