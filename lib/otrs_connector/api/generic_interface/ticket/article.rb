module OTRSConnector
  module API
    module GenericInterface
      class Ticket
        class Article
          include ActiveAttr::Model
          
          attribute :id, type: Integer
          attribute :from
          attribute :to
          attribute :cc
          attribute :subject
          attribute :body
          attribute :reply_to
          attribute :message_id, type: Integer
          attribute :in_reply_to
          attribute :references
          attribute :sender_type
          attribute :sender_type_id, type: Integer
          attribute :article_type
          attribute :article_type_id, type: Integer
          attribute :content_type
          attribute :charset, default: 'utf8'
          attribute :mime_type, default: 'text/plain'
          attribute :incoming_time
        end
      end
    end
  end
end