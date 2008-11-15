require File.dirname(__FILE__) + '/../test_helper'

class ComitesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:comites)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_comite
    assert_difference('Comite.count') do
      post :create, :comite => { }
    end

    assert_redirected_to comite_path(assigns(:comite))
  end

  def test_should_show_comite
    get :show, :id => comites(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => comites(:one).id
    assert_response :success
  end

  def test_should_update_comite
    put :update, :id => comites(:one).id, :comite => { }
    assert_redirected_to comite_path(assigns(:comite))
  end

  def test_should_destroy_comite
    assert_difference('Comite.count', -1) do
      delete :destroy, :id => comites(:one).id
    end

    assert_redirected_to comites_path
  end
end
