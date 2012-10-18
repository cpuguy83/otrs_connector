module OTRSConnector
  module API
    module GenericInterface
      class Ticket
        class DynamicField
          include ActiveAttr::Model
          attribute :name
          attribute :value
        end
      end
    end
  end
end