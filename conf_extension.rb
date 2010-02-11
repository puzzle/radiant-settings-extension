# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application_controller'

class ConfExtension < Radiant::Extension
  version "1.1"
  description "Web based administration for Radiant default configuration settings."
  url "http://github.com/squaretalent/radiant-conf-extension"
  
  define_routes do |map|
    map.namespace 'admin' do |admin|
      admin.resources :configs
    end
  end
  
  def activate
    Radiant::Config.extend ConfigFindAllAsTree
    Radiant::Config.send :include, ConfigProtection
    
    if Radiant::Config['roles.settings']
      config_roles = Radiant::Config['roles.settings']
      roles = []
      roles << :developer if config_roles.include?('developer')
      roles << :admin if config_roles.include?('admin')
      if config_roles.include?('all')
        roles = [:all]
      end
    end
    
    tab :Settings do
      add_item :Config, "/admin/configs", :after => :Users
    end
    
    Page.class_eval do
      include ConfigTags
    end
    
    Radiant::AdminUI.class_eval do
      attr_accessor :settings
    end
    admin.settings = load_default_settings_regions
  end
  
  def deactivate
  end
  
  def load_default_settings_regions
    returning OpenStruct.new do |settings|
      settings.index = Radiant::AdminUI::RegionSet.new do |index|
        index.main.concat %w{top list bottom}
      end
    end
  end
  
end
