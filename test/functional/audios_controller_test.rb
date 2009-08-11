require File.dirname(__FILE__) + '/../test_helper'
require 'audios_controller'

# Re-raise errors caught by the controller.
class AudiosController; def rescue_action(e) raise e end; end

class AudiosControllerTest < Test::Unit::TestCase
  fixtures :audios

  def setup
    @controller = AudiosController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:audios)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_audio
    old_count = Audio.count
    post :create, :audio => { }
    assert_equal old_count+1, Audio.count
    
    assert_redirected_to audio_path(assigns(:audio))
  end

  def test_should_show_audio
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_audio
    put :update, :id => 1, :audio => { }
    assert_redirected_to audio_path(assigns(:audio))
  end
  
  def test_should_destroy_audio
    old_count = Audio.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Audio.count
    
    assert_redirected_to audios_path
  end
end
