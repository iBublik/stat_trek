require 'active_support/lazy_load_hooks'

require 'stat_trek/version'
require 'stat_trek/stat_trek'
# require 'stat_trek/class_methods'
# require 'stat_trek/instance_methods'

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.extend(StatTrek::ClassMethods)
  ActiveRecord::Base.include(StatTrek::InstanceMethods)
end
