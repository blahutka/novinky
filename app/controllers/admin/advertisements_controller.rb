class Admin::AdvertisementsController < Admin::AdminController
  layout "admin", :except => [:detail]


  def index
    if (params[:search_advertisements])
      @collection = Advertisement.search params[:search_advertisements], :page => params[:page], :per_page => 10, :order => 'module_name DESC'
    else
      @collection = Advertisement.paginate(:per_page => 10, :page => params[:page], :order => 'module_name DESC')
    end
    render 'shared/admin/index.js.erb'
  end

  show.response do |wants|
    wants.js
    wants.html { render :text => 'alert();'}
  end

  show.before :get_content

  new_action.response do |wants|
    wants.js
  end

  create.response do |wants|
    wants.js
  end

  edit.response do |wants|
    wants.js
  end

  update.response do |wants|
    wants.js
  end

  private
  def get_content
    @advertisement_contents = object.advertisement_contents.paginate(:page => params[:page] || 1, :per_page => 20)
  end
end