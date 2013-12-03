class Object
  def self.new_attr_accessor(*args)
    args.each do |arg|
      define_method("@#{arg}=") do |value|
        self.instance_variable_set("@#{arg}", value)
      end
    
      define_method(arg) do 
        self.instance_variable_get("@#{arg}")
      end
    end
  end
end
