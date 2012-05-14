class OTRS::Relation < Array
  require 'will_paginate/array'
  
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
  
  def order(field='id',order='desc')
    case order.downcase.to_s
    when 'asc'
      self.sort { |a,b| b.send(field.to_s) <=> a.send(field.to_s) }
    when 'desc'                                               
      self.sort { |a,b| a.send(field.to_s) <=> b.send(field.to_s) }
    end
  end
  
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