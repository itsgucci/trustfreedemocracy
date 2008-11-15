require File.dirname(__FILE__) + '/../test_helper'
require 'proposals_controller'

# Re-raise errors caught by the controller.
class ProposalsController; def rescue_action(e) raise e end; end

class ProposalsControllerTest < Test::Unit::TestCase
  fixtures :proposals

  def setup
    @controller = ProposalsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = proposals(:first).id
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

    assert_not_nil assigns(:proposals)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:proposal)
    assert assigns(:proposal).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:proposal)
  end

  def test_create
    num_proposals = Proposal.count

    post :create, :proposal => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_proposals + 1, Proposal.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:proposal)
    assert assigns(:proposal).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Proposal.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Proposal.find(@first_id)
    }
  end
end
