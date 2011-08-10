
class Groups::PermissionsController < Groups::BaseController

  helper 'acts_as_locked'

  def index
    @key  = @group.keys.find_or_create_by_holder(:public)
    @keys = [@key]
  end

  def update
    @key   = @group.keys.find_or_create_by_keyring_code params.delete(:id)
    @locks = @key.update!(params)
    @keys  = @group.keys.filter_by_holder(:include => [:public], :exclude => [@group])
    render :template => 'common/permissions/update'
  end

  protected

  def key_holder_path(id)
    group_permission_path(@group, id)
  end
  helper_method :key_holder_path

end

