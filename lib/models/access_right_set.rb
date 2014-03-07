class AccessRightSet
   def initialize(resource, requester)
      @resource     = resource
      @requester    = requester
      @type         = requester.instance_of?(User) ? :user : :client
      @access_token = load_token
   end

   attr_reader :resource, :requester, :type

   # Tests whether the requester has a specified permission on the resource
   # covered by the right set.
   def allow?(right)
      false
   end

   # Convenience method for testing permissions on a set of rights.
   def allow_all?(*rights)
      false
   end

   # Tests whether the requester possesses at least one of a set of permissions
   # on a resource.
   def allow_any?(*rights)
      false
   end

   def grant(*rights)
      raise "The #{self.class.name} class has not implemented the #grant() method."
   end

   def revoke(*rights)
      raise "The #{self.class.name} class has not implemented the #revoke() method."
   end

   # Tests whether the requester is the owner of the resource being accessed.
   def is_owner?
   	@type == :user && @resource.respond_to?(:owner) ? (@resource.owner_id == @requester.id) : false
   end

   # This method is used to test whether the underlying resource is public.
   def is_public?
   	@resource.respond_to?(:is_public?) && @resource.is_public?
   end

   # This method fetches the access token for the right set. For client right
   # sets this will generally be the client latest token.
   def token
      @access_token
   end

   def self.for(resource, requester)
      case resource.class
         when Camera.class
            CameraRightSet.new(resource, requester)
         else
            raise "Right set requested for unknown resource class '#{resource.class.name}'."
      end
   end

   private

   def load_token
      token
      if @type != :user
         token = AccessToken.where(client_id: @requester.id).order(Sequel.desc(:created_at)).first
         token = AccessToken.create(client: @requester, refresh: SecureRandom.base64(24)) if token.nil?
      else
         token = @requester.token
      end
      token
   end
end