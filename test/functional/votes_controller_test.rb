require File.dirname(__FILE__) + '/../test_helper'
require 'votes_controller'

# Re-raise errors caught by the controller.
class VotesController; def rescue_action(e) raise e end; end

class VotesControllerTest < Test::Unit::TestCase
  fixtures :votes

  def setup
    @controller = VotesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = votes(:first).id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:votes)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:vote)
    assert assigns(:vote).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:vote)
  end

  def test_create
    num_votes = Vote.count

    post :create, :vote => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_votes + 1, Vote.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:vote)
    assert assigns(:vote).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Vote.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Vote.find(@first_id)
    }
  end
end
