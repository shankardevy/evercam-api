class AccessRightSet
   def initialize(resource, requester)
      @resource  = resource
      @requester = requester
      @type      = requester.instance_of?(User) ? :user : :client
      @token     = @type == :user && !@requester.nil? ? @requester.token : nil
   end

   attr_reader :resource, :requester, :type

   # Tests whether the requester has a specified permission on the resource
   # covered by the right set.
   def allow?(right)
      @type == :user ? user_allowed?(right) : client_allowed?(right)
   end

   # Convenience method for testing permissions on a set of rights.
   def allow_all?(*rights)
      rights.find {|right| allow?(right) == false}.nil?
   end

   # Tests whether the token used to create the access right set is the owner of
   # the resource being accessed.
   def is_owner?
   	@type == :user && @resource.respond_to?(:owner) ? (@resource.owner_id == @requester.id) : false
   end

   def is_token_valid?
   	!@token.nil? && @token.is_valid?
   end

   def is_resource_public?
   	@resource.respond_to?(:is_public?) && @resource.is_public
   end

   def grant(*rights)
   	rights.each do |right|
	   	if !allow?(right) && !is_owner?
	   		AccessRight.create(token:  current_token,
	   			                camera: @resource,
	   			                right: right,
	   			                status: AccessRight::ACTIVE)
	   	end
	   end
   end

   def revoke(*rights)
      @type == :user ? revoke_from_user(*rights) : revoke_from_client(*rights)
   end

   private

   def user_allowed?(right)
      result = is_resource_public? && AccessRight::PUBLIC_RIGHTS.include?(right)
      if !result && !@requester.nil? && !@resource.nil?
         result = is_owner?
         if !result && @token.valid?
            result = (AccessRight.where(token_id:  @token.id,
                                        camera_id: @resource.id,
                                        status:    AccessRight::ACTIVE,
                                        right:     right).count > 0) 
         end
      end
      result
   end

   def client_allowed?(right)
      result = is_resource_public? && right == AccessRight::SNAPSHOT
      if !result && !@requester.nil? && !@resource.nil?
         query = AccessRight.join(:access_tokens, id: :token_id).where(client_id: @requester.id,
                                                                       is_revoked: false,
                                                                       camera_id: @resource.id,
                                                                       status: AccessRight::ACTIVE,
                                                                       right: right)
         result = (query.count > 0)
      end
      result
   end

   def current_token
      type == :client ? requester.tokens.last :  requester.token
   end

   def revoke_from_user(*rights)
      if allow_all?(rights) && !is_owner? && !is_resource_public?
         AccessRight.where(token:  @token,
                           camera: @resource,
                           status: AccessRight::ACTIVE,
                           right: rights).update(status: AccessRight::DELETED)
      end
   end

   def revoke_from_client(*rights)
      if allow_all?(rights) && !is_resource_public?
         AccessRight.select(:token_id, :right).join(:access_tokens, id: :token_id).where(client_id: @requester.id,
                                                                                         is_revoked: false,
                                                                                         camera_id: @resource.id,
                                                                                         status: AccessRight::ACTIVE,
                                                                                         right: rights).each do |record|
            AccessRight.where(token_id: record.token_id,
                              status: AccessRight::ACTIVE,
                              right:  record.right).update(status: AccessRight::DELETED)
         end
      end
   end
end