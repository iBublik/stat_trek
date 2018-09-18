require 'active_support/lazy_load_hooks'

require 'stat_trek/version'
require 'stat_trek/stat_trek'

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.extend(StatTrek::ClassMethods)
  ActiveRecord::Base.include(StatTrek::InstanceMethods)
end
