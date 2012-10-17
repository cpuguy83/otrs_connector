class OTRSConnector::Relation < Array
  # OTRS::Relation is my attempt at making something similar to ActiveRecord::Relation
  # There is still a lot to do here.
  # Right now where chains don't work as AR does, the first in the chain connects to OTRS, the rest of the chained items are parsing through the returned objects... somtimes this is faster, but the more objects get returned the slower it will be.
  
  #require 'will_paginate/array'
  
  #attr_accessor :where_hash, :connect_params
  #
  #def where(opts_hash={}, *rest)
  #  return self if opts_hash.blank?
  #
  #  relation = clone
  #  relation.where_hash += opts_hash
  #  relation
  #end
  #
  #def initialize(opts)
  #  self.send("where_hash=".to_sym, opts[:data])
  #  self.send("connect_params=".to_sym, opts.except(:data))
  #end
  #
  #def to_query
  #  self.where_hash
  #end
  #
  #
  #def run_query
  #  a = OTRS.connect(self.connect_params.merge(self.where_hash))
  #  a.collect { |b| b.collect {|c| OTRS.object_preprocessor c }}
  #end
  
  # Allows chaining where methods, this method only parses the already returned objects from OTRS, currently.  In the future I hope to have this grouping the where chains together into one OTRS request for all in the chain
  def where(attributes)
    relation = self.class.new
    attributes.each do |lookup_key,lookup_value|
      self.each do |object|
        object.attributes.each do |object_key,object_value|
          if object_key == lookup_key and object_value == lookup_value
            relation << object
          end
        end
      end
    end
    return relation
  end
  
  def limit(int)
    self[0...int]
  end
  
  # This is hit and miss for some reason... sometimes the order works correctly, sometimes it's backwards (desc/asc)
  def order(field='id',order='desc')
    case order.downcase.to_s
    when 'asc'
      self.sort { |a,b| b.send(field.to_s) <=> a.send(field.to_s) }
    when 'desc'                                               
      self.sort { |a,b| a.send(field.to_s) <=> b.send(field.to_s) }
    end
  end
  
  # Removes duplicate records
  def uniqify
    ids = []
    results = self.class.new
    self.each do |s|
      results << s unless ids.include? s.id
      ids << s.id
    end
    results
  end
  
end