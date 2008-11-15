require File.dirname(__FILE__) + '/../../test_helper'

class Admin::NotificationsControllerTest < ActionController::TestCase
  tests Admin::NotificationsController

  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:admin_notifications)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_notifications
    assert_difference('Admin::Notifications.count') do
      post :create, :notifications => { }
    end

    assert_redirected_to notifications_path(assigns(:notifications))
  end

  def test_should_show_notifications
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_notifications
    put :update, :id => 1, :notifications => { }
    assert_redirected_to notifications_path(assigns(:notifications))
  end

  def test_should_destroy_notifications
    assert_difference('Admin::Notifications.count', -1) do
      delete :destroy, :id => 1
    end

    assert_redirected_to admin_notifications_path
  end
end
