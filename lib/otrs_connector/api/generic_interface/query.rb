module OTRSConnector
  module API
    module GenericInterface
      # Proxy class for searching.  Allows method chaining with searches similar to ActiveRecord::Reation.
      # Waits until objects are actually needed before sending request to OTRS
      # Essentially takes all query options in line before performing the lookup
      class Query
        include Enumerable
        def initialize(model)
          @model = model
        end
        
        def where(attributes)
          if @where
            @where.merge!(attributes)
          else
            @where = attributes
          end
          self
        end
        
        def order(direction)
          case direction.to_s
          when /asc|ASC|up|UP/
            @where[:order_by] = 'Up'
          when /desc|DESC|down|DOWN|dsc/
            @where[:order_by] = 'Down'
          end
          self
        end
        
        def limit(number)
          @where[:limit] = number
          self
        end
        
        def sort(*fields)
          if fields.count == 1
            @where[:sort_by] = fields.first.to_s.camelize
          else
            @where[:sort_by] = fields.collect{|f| f.to_s.camelize}
          end
          self
        end
        
        # Field names need to be camelized for OTRS
        def camelized_where_attributes
          new_where = {}
          @where.each do |key,value|
            new_where[key.to_s.camelize] = value
          end
          @where = new_where
          @where
        end
        
        def inspect
          @model.connect(@model.search_method, camelized_where_attributes).first[1]
        end
        
        def all
          inspect
        end
        
        def first
          inspect.first
        end
        
        def last
          inspect.last
        end
        
        def each(&block)
          inspect.each(&block)
        end
        
        def collect(&block)
          inspect.collect(&block)
        end

      end
    end
  end
end