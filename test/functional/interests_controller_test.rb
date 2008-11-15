require File.dirname(__FILE__) + '/../test_helper'

class InterestsControllerTest < ActionController::TestCase
  tests InterestsController

  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:interests)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_interest
    assert_difference('Interest.count') do
      post :create, :interest => { }
    end

    assert_redirected_to interest_path(assigns(:interest))
  end

  def test_should_show_interest
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_interest
    put :update, :id => 1, :interest => { }
    assert_redirected_to interest_path(assigns(:interest))
  end

  def test_should_destroy_interest
    assert_difference('Interest.count', -1) do
      delete :destroy, :id => 1
    end

    assert_redirected_to interests_path
  end
end
