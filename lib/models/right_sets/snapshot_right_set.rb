class SnapshotRightSet < AccessRightSet
   # The list of valid rights for a snapshot.
   VALID_RIGHTS = [AccessRight::DELETE,
                   AccessRight::EDIT,
                   AccessRight::LIST,
                   AccessRight::VIEW,
                   "#{AccessRight::GRANT}~#{AccessRight::DELETE}",
                   "#{AccessRight::GRANT}~#{AccessRight::EDIT}",
                   "#{AccessRight::GRANT}~#{AccessRight::LIST}",
                   "#{AccessRight::GRANT}~#{AccessRight::VIEW}"]

   # Constructor for the SnapshotRightSet class.
   #
   # ==== Parameters
   # snapshot::   The snapshot that the rights pertain to.
   # requester::  The user or client that the rights pertain to.
   def initialize(snapshot, requester)
    super(snapshot, requester)
   end

   alias :snapshot :resource

   # Tests whether the requester has a specified permission on the snapshot.
   #
   # ==== Parameters
   # right::  The name of the right to perform the check for.
   def allow?(right)
      type == :user ? user_allow?(right) : client_allow?(right)
   end

   # Tests whether the requester has all of a specified set of permissions on
   # the snapshot.
   #
   # ==== Parameters
   # *rights::  An array of the rights to include in the check.
   def allow_all?(*rights)
      rights.find {|right| allow?(right) == false}.nil?
   end

   # Tests whether the requester has at least one of a specified set of
   # permissions on the snapshot.
   #
   # ==== Parameters
   # *rights::  An array of the rights to include in the check.
   def allow_any?(*rights)
      !(rights.find {|right| allow?(right) == false}.nil?)
   end

   # This method gifts one or more rights to the requester on the snapshot.
   #
   # ==== Parameters
   # *rights::  An array of the rights to be granted to the requester.
   def grant(*rights)
      rights.each do |right|
         if !allow?(right) && !is_owner?
            AccessRight.create(token:    token,
                               snapshot: snapshot,
                               right:    right,
                               status:   AccessRight::ACTIVE)
         end
      end
   end

   # This method removes one or more rights on the snapshot from the requester.
   #
   # ==== Parameters
   # *rights::  An array of the rights to be revoked.
   def revoke(*rights)
      type == :user ? user_revoke(*rights) : client_revoke(*rights)
   end

   # Tests whether a specified right is valid for a snapshot.
   #
   # ==== Parameters.
   # right::  The right to perform the test for.
   def valid_right?(right)
      SnapshotRightSet.valid_right?(right)
   end

   # Class level implementation of the valid right test.
   def self.valid_right?(right)
      VALID_RIGHTS.include?(right)
   end

   private

   # An implementation of the allow? method specific to checking user
   # permissions.
   #
   # ==== Parameters
   # right::  The name of the right to perform the check for.
   def user_allow?(right)
      raise "#{right} is not a valid snapshot access right." if !valid_right?(right)
      result = is_public? && AccessRight::PUBLIC_RIGHTS.include?(right)
      if !result && !requester.nil? && !snapshot.nil?
         result = is_owner?
         if !result && token.valid?
            result = (AccessRight.where(token_id:    token.id,
                                        snapshot_id: snapshot.id,
                                        status:      AccessRight::ACTIVE,
                                        right:       right).count > 0) 
            if !result
               # Check for an account level permissions grant.
               rights = AccountRightSet.new(snapshot.owner, requester, AccessRight::SNAPSHOTS)
               result = rights.allow?(right)
            end
         end
      end
      result
   end

   # An implementation of the revoke method specific to removing rights from
   # a user.
   #
   # ==== Parameters
   # *rights::  The rights to be removed from the user.
   def user_revoke(*rights)
      if allow_all?(*rights) && !is_owner? && !is_public?
         AccessRight.where(token:    token,
                           snapshot: snapshot,
                           status:   AccessRight::ACTIVE,
                           right:    rights).update(status: AccessRight::DELETED)
      end
   end

   # An implementation of the allow? method specific to checking client
   # permissions.
   #
   # ==== Parameters
   # right::  The name of the right to perform the check for.
   def client_allow?(right)
      raise "#{right} is not a valid snapshot access right." if !valid_right?(right)
      result = is_public? && right == AccessRight::SNAPSHOT
      if !result && !requester.nil? && !snapshot.nil?
         query = AccessRight.join(:access_tokens, id: :token_id).where(client_id: requester.id,
                                                                       is_revoked: false,
                                                                       snapshot_id: snapshot.id,
                                                                       status: AccessRight::ACTIVE,
                                                                       right: right)
         result = (query.count > 0)
         if !result
            # Check for an account level permissions grant.
            rights = AccountRightSet.new(snapshot.owner, requester, AccessRight::SNAPSHOTS)
            result = rights.allow?(right)
         end
      end
      result
   end

   # An implementation of the revoke method specific to removing rights from
   # a user.
   #
   # ==== Parameters
   # *rights::  The rights to be removed from the user.
   def client_revoke(*rights)
      if allow_all?(*rights) && !is_public?
         AccessRight.select(:token_id, :right).join(:access_tokens, id: :token_id).where(client_id: requester.id,
                                                                                         is_revoked: false,
                                                                                         snapshot_id: snapshot.id,
                                                                                         status: AccessRight::ACTIVE,
                                                                                         right: rights).each do |record|
            AccessRight.where(token_id: record.token_id,
                              status: AccessRight::ACTIVE,
                              right:  record.right).update(status: AccessRight::DELETED)
         end
      end
   end
end