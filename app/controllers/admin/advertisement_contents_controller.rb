class Admin::AdvertisementContentsController < Admin::AdminController
  layout "admin"

  belongs_to :advertisement

  index.response do |wants|
    wants.js
    wants.html
  end

  show.response do |wants|
    wants.js
  end

  new_action.response do |wants|
    wants.js
  end

  create.after :format_date
  update.after :format_date

  create.response do |wants|
    wants.js { redirect_to(admin_advertisement_path(object.advertisement), :notice => 'ok') }
  end

  edit.response do |wants|
    wants.js
  end

  update.response do |wants|
    wants.html {redirect_to :action => 'index'}
  end

  destroy do
    wants.js { redirect_to admin_advertisement_path(object.advertisement) }
  end

  private
  def collection
    @collection ||= end_of_association_chain.paginate(:per_page => 20, :page => params[:page] || 1)
  end


  def format_date
    @advertisement_content.update_attributes(:date_start => params[:advertisement_content][:date_start].split('/').reverse.join('-').to_date.to_s) unless \
          params[:advertisement_content][:date_start].blank?
    @advertisement_content.update_attributes(:date_finish => params[:advertisement_content][:date_finish].split('/').reverse.join('-').to_date.to_s) unless \
       params[:advertisement_content][:date_finish].blank?
    @advertisement_content.save

  end

end