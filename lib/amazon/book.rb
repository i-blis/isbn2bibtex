#!/usr/bin/env ruby -wKU

require 'rubygems'
require 'amazon/ecs'
require 'erb'

module Amazon

  KEY = ENV['AWS_KEY'] || '0540ZTF1YK0574PSFH02'

  class Book

    @@dispatch = {
      :author    => lambda {  |item| item.get_array('author').join(' and ') },
      :authors   => lambda {  |item| item.get_array('author') },
      :editor    => lambda {  |item| item/'creator/#"Editor"' },
      :editors   => lambda {  |item| item.get_array('creator/#"Editor"') },
      :isbn      => lambda {  |item| item.get('isbn') },
      :ean       => lambda {  |item| item.get('ean') },
      :publisher => lambda {  |item| item.get('publisher') },
      :cover     => lambda {  |item| item.get('binding') },
      :price     => lambda {  |item| item.get('formatedprice') },
      :pages     => lambda {  |item| item.get('numberofpages') },
      :title     => lambda {  |item| item.get('title') },
      :date      => lambda {  |item| item.get('publicationdate') },
      :year      => lambda {  |item| $1 if item.get('publicationdate') =~ /^(\d{4})/ },
      :language  => lambda {  |item| 
        if item.get_array('//languages//type').member?('Published') then
          return ((item/'language').find { |e| e.search('type').inner_text == 'Published' }).search('/name').inner_text
        else
          return nil
        end
      },
      :description  => lambda { |item| 
        if item.get_array('/editorialreviews//source').member?('Product Description') then
          return ((item/'editorialreview').find { |e| e.search('source').inner_text == 'Product Description' }).search('/content').inner_text
        else
          return nil
        end
      },

    }
    
    attr_reader :fields, :data
    
    # debugging
    # attr_reader :output, :item

    def initialize(isbn, filepath = '' )
      begin
              
        # get data from amazon
        Amazon::Ecs.options = {:aWS_access_key_id => KEY} 
        items = Amazon::Ecs.item_lookup(isbn, {:response_group => 'Medium'}).items
        if items.empty?
          raise ArgumentError, "#{isbn} is not a isbn number to be matched in the database"
        end
        item = items.first

        # build data hash from retrieved item
        @data = @@dispatch.inject(Hash.new) do |collect, (field, code)| 
          value = code.call(item) 
          collect[field] = value unless value.nil? or value.empty?
          collect 
        end
        
        # debugging
        # @item = item
 
        # add filepath to data
        @data[:filepath] = filepath unless filepath.empty?

        # build a string list of avaible fields
        @fields = []
        @data.keys.each do |access_key|
          @fields << access_key.to_s
        end

        if not @data.has_key?(:isbn)
          raise ArgumentError, "#{isbn} is not a isbn number to be matched in the database"
        end

        @defined = true

      rescue Exception => e
        $stderr.puts "#{e.class}: #{e.message}"
        @defined = false
      end
    end 

    def defined?(field = '')
      if field.empty?
        @defined
      else
        @data.has_key?(field.to_sym)
      end
    end

    def populate(template = '')
      b = binding
      ERB.new(template, 0, "%<>", "@output").result b
      @output
    end
    
    def method_missing(method_sym, *arguments, &block)
      if @data.has_key?(method_sym)
        @data[method_sym]
      else
        ""
      end
    end

    def respond_to?(method_sym, include_private = false)
      if @data.keys.include?(method_sym)
        true
      else
        super
      end
    end

  end
  
end
