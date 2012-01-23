

module Corundum
  module Configurable
    def local_attrs
      @local_attrs ||=
        begin
          mod = Module.new
          extend mod
          mod
        end
    end

    def local_attrs=(mod)
      extend mod
      @local_attrs = mod
    end

    def setting(name, default_value = nil)
      local_attrs.instance_eval do
        attr_accessor(name)
      end
      instance_variable_set("@#{name}", default_value)
    end

    def dup
      result = super
      result.extend Configurable
      result.local_attrs = @local_attrs
      result
    end

    def settings(hash)
      hash.each_pair do |name, value|
        setting(name, value)
      end
      return self
    end

    def nested(hash=nil)
      obj = Object.new
      obj.extend Configurable
      obj.settings(hash || {})
      return obj
    end

    def nil_fields(*names)
      names.each do |name|
        setting(name, nil)
      end
      return self
    end
  end
end
