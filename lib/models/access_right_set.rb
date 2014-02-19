class AccessRightSet
   def self.for(resource, token)
      AccessRightSet.for_camera(resource, token)
   end

   # Tests whether the entity associated with the token used to create the
   # access right set possesses a specified right. This will always return
   # true if the entity owns the resource.
   def allow?(right)
   	result = false
   	if @token.is_valid?
	   	result = is_owner?
	   	if !result
	   		result = (AccessRight.where(token_id:  @token.id,
	   			                         camera_id: @resource.id,
	   			                         status:    AccessRight::ACTIVE,
	   			                         right:     right).count > 0) 
	   	end
	   end
   	result
   end

   # Tests whether the token used to create the access right set is the owner of
   # the resource being accessed.
   def is_owner?
   	@resource.respond_to?(:owner) ? (@resource.owner_id == @token.user_id) : false
   end

   private

   def initialize(camera, token)
   	@resource = camera
   	@token    = token
   end

   def self.for_camera(camera, token)
   	AccessRightSet.new(camera, token)
   end
end