require File.dirname(__FILE__) + '/../../test_helper'

class Groups::GroupsControllerTest < ActionController::TestCase

  def test_new_group_requires_login
    get :new
    assert_login_required
  end

  def test_new_group
    login_as :gerrard
    assert_permission :may_create_group? do
      get :new
    end
    assert_response :success
  end

  def test_create_group
    login_as :gerrard
    assert_difference 'Group.count' do
      assert_permission :may_create_group? do
        post :create, :group => {:name => 'test-create-group', :full_name => "Group for Testing Group Creation!"}
      end
      assert_response :redirect
      group = Group.find_by_name 'test-create-group'
      assert_redirected_to group_url(group)
    end
  end

  def test_create_no_group_without_name
    login_as :gerrard
    assert_no_difference 'Group.count' do
      post :create, :group => {:name => ''}
      assert_error_message
    end
  end

  def test_create_no_group_with_duplicate_name
    login_as :gerrard
    assert_no_difference 'Group.count' do
      post :create, :group => {:name => 'animals'}
      assert_error_message
    end
  end

end