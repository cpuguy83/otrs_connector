class OTRS::ConfigItem::DeploymentState
  
  def self.states
    items = OTRS::GeneralCatalog.item_list_fast('ITSM::ConfigItem::DeploymentState')
  end
  
  def self.all
    self.states
  end
  
  self.all.each do |key,value|
    define_singleton_method value.downcase.underscore do
      return key
    end
  end

end