class Web::SectionsController < Web::WebController
  layout "web/referendum"
  before_filter :set_last_id
  
  def test_proxy
    t = params[:sleep].to_i
    sleep(t)
    render :nothing=>true
  end
  
  def topics
    @section = Section.find(params[:id]) if params[:id]
    add_breadcrumb "Témata", topics_path
    render :layout=>"web/gallery"
  end
  
  def index
    length_limit = 5
    redirect_to section_path(:name=>"vikend") and return if Web::Calendar.week?
    @section = Section.find(Section::HOME_SECTION_ID)
    set_common_variables(Section::HOME_SECTION_ID)
    ign_arr = [@headliner_box ? @headliner_box.article_id : 0]
    ign_arr += @rel_articles.map{|a| a.id}.uniq
      @today_opinions = Article.home_opinions(Time.now,Time.now,{:limit=>1,:ignore_arr=>ign_arr,:length_limit=>nil})
      if @today_opinions.length < length_limit
        @older_opinions = Article.home_opinions(Time.now.yesterday,Time.now.yesterday,{:limit=>20,:ignore_arr=>ign_arr,:length_limit=>length_limit-@today_opinions.length})
      end
    @question = Dailyquestion.first_by_date
    @article_photo_show = true
  end
  
  def detail
    @section = Section.find(:first,:conditions=>["name LIKE ?",unpretty_name(params[:name])],:select=>"id,name")
    cookies[:section_id] = @section.id
    set_default_variables
    add_breadcrumb @section.name, section_path(pretty_name(@section))
    render :action=>"holidays" and return if Web::Calendar.holidays?
    render :action=>"#{@section.id}" and return
  end
  
  def subsection
    @subsection = Section.find(:first,:conditions=>["name LIKE ?",unpretty_name(params[:name])])
    @section = @subsection.parent
    @article_photo_show = true
    set_default_variables
    @articles = Article.paginate(:all,
                             :conditions=>["article_sections.section_id = ? AND articles.approved = ? AND articles.visibility = ?",@subsection.id,true,false],
                             :joins=>[:sections],
                             :order=>"order_date DESC, priority_section DESC, order_time DESC",
                             :page=>params[:page],
                             :per_page=>10,
                             :include=>[:content_type, :author, :pictures],
                             :select=>"articles.id, articles.author_id, articles.content_type_id, articles.name, articles.perex")
    ign_arr = @articles.map{|a| a.id}.uniq                         
    @opinions = Article.middle_opinions(@section.id,12,ign_arr)
    @type = 1 #for partial readest menu
    @readest = Article.all_readest(Time.now-24.hours)
    add_breadcrumb @subsection.name, ""
  end
  
  def search
    @text = params[:text]
    @articles = Article.paginate(:all,
                                 :conditions=>["publish_date <= ? AND articles.approved = ? AND articles.visibility = ? AND name LIKE ? OR perex LIKE ? OR text LIKE ?",Time.now,true,false,"%#{@text}%","%#{@text}%","%#{@text}%"],
                                 :order=>"order_date DESC, priority_section DESC, order_time DESC",
                                 :page=>params[:page],
                                 :per_page=>25,
                                 :include=>[:content_type, :author, :pictures],
                                 :select=>"articles.id, articles.author_id, articles.content_type_id, articles.name, articles.perex")
    add_breadcrumb "Vyhledávání", ""
    render :layout=>"web/gallery"
  end
  
protected
  def set_default_variables
    set_common_variables(@section.id)
    case @section.id
      when Section::NAZORY
        set_opinions_variables
      when Section::VIKEND
        @week =  true
        set_weekend_variables
      else
        set_non_opinion_variables(@section.id)
    end
    #set_common_variables(@section.id)
  end

  def set_opinions_variables
    @article_photo_show = true
=begin    
    if Web::Calendar.week? && Web::Calendar.sunday?
      tfrom_date = Time.now - 1.days
      tto_date = Time.now
      yfrom_date = Time.now.yesterday - 2.days
      yto_date = Time.now.yesterday - 2.days
    else
      tfrom_date = Time.now
      tto_date = Time.now
      yfrom_date = Time.now.yesterday
      yto_date = Time.now.yesterday
    end
    
    @today_articles = Article.from_section(:section_id=>Section::NAZORY,
                                           :from_date=>tfrom_date,
                                           :to_date => tto_date,
                                           :limit=>nil)
                                          
    @yesterday_articles = Article.from_section(:section_id=>Section::NAZORY,
                                               :from_date=>yfrom_date,
                                               :to_date => yto_date,
                                               :limit=>nil)
    if (@today_articles + @yesterday_articles).length < 12
=end
      succ_date = DateTime.parse(params[:succ_date]) rescue nil
      prev_date = DateTime.parse(params[:prev_date]) rescue nil
      op = ""
      op += "publish_date < '#{succ_date.end_of_day.to_s(:db)}' AND " if succ_date
      op += "publish_date > '#{prev_date.beginning_of_day.to_s(:db)}' AND " if prev_date
      @all_opinions = Article.find(:all,
                                   :conditions=>["#{op}content_type_id IN (?)",ContentType.opinion_types],
                                   :group=>"pub_date",
                                   :select=>"date(publish_date) as pub_date",
                                   :order=>"pub_date DESC, order_date DESC, priority_section DESC, order_time DESC")
    #end
  end
  
  def set_weekend_variables
    @sunday = DateTime.strptime(params[:date],"%d.%m.%Y") rescue Web::Calendar.sunday_date
    
    if Web::Calendar.holidays?
      @holiday_articles = []
      curr_date = Time.now 
      while Web::Calendar.holidays?(curr_date)
        @holiday_articles << Article.find(:all,
                                        :conditions=>["article_sections.section_id = ? AND content_type_id != ? AND publish_date >= ? AND publish_date <= ? AND publish_date <= ? AND articles.approved = ? AND articles.visibility = ?",Section::VIKEND,ContentType::ZPRAVA,curr_date.beginning_of_day,curr_date.end_of_day,Time.now,true,false],
                                        :order=>"order_date DESC, priority_section DESC, order_time DESC",
                                        :joins=>[:sections],
                                        :include=>[:content_type, :author, :pictures],
                                        :select=>"articles.id, articles.author_id, articles.content_type_id, articles.name, articles.perex")
        curr_date -= 1.days                             
      end
      return
    end
         
    @saturday_articles = Article.find(:all,
                                      :conditions=>["article_sections.section_id = ? AND content_type_id != ? AND publish_date >= ? AND publish_date <= ? AND publish_date <= ? AND articles.approved = ? AND articles.visibility = ?",Section::VIKEND,ContentType::ZPRAVA,(@sunday-1.days).beginning_of_day,(@sunday-1.days).end_of_day,Time.now,true,false],
                                      :order=>"order_date DESC, priority_section DESC, order_time DESC",
                                      :joins=>[:sections],
                                      :include=>[:content_type, :author, :pictures],
                                      :select=>"articles.id, articles.author_id, articles.content_type_id, articles.name, articles.perex")                                
    if Web::Calendar.saturday? && @sunday > Time.now
      @only_saturday = true
      return
    end
    @sunday_articles = Article.find(:all,
                                    :conditions=>["article_sections.section_id = ? AND content_type_id != ? AND publish_date >= ? AND publish_date <= ? AND publish_date <= ? AND articles.approved = ? AND articles.visibility = ?",Section::VIKEND,ContentType::ZPRAVA,@sunday.beginning_of_day,@sunday.end_of_day,Time.now,true,false],
                                    :order=>"order_date DESC, priority_section DESC, order_time DESC",
                                    :joins=>[:sections],
                                    :include=>[:content_type, :author, :pictures],
                                    :select=>"articles.id, articles.author_id, articles.content_type_id, articles.name, articles.perex")                                  
  end
  
  def set_non_opinion_variables(section_id)
    per_page = 10
    ign_arr = [@headliner_box ? @headliner_box.article_id : 0]
    @articles = Article.paginate(:all,
                                 :conditions=>["article_sections.section_id = ? AND publish_date <= ? AND articles.approved = ? AND articles.visibility = ? AND articles.id NOT IN (?) AND articles.content_type_id NOT IN (?)",section_id,Time.now,true,false,ign_arr,ContentType.author_types],
                                 :order=>"order_date DESC, priority_section DESC, order_time DESC",
                                 :joins=>[:sections],
                                 :page=>params[:page],
                                 :per_page=>per_page,
                                 :include=>[:content_type, :author, :pictures],
                                 :select=>"articles.id, articles.author_id, articles.content_type_id, articles.name, articles.perex")
  end
  
  def set_common_variables(section_id)
    @top_themes = @section.top_themes
    @headliner_box = Article.headliner_box(section_id)
    @rel_articles = @headliner_box ? @headliner_box.articles : []
    @themes = @headliner_box ? @headliner_box.themes : []
    @right_boxes = Article.right_boxes(section_id)
    arr = @rel_articles
    arr += [@headliner_box.article] if @headliner_box
    arr += @articles if @articles
    arr += @today_articles if @today_articles
    arr += @yesterday_articles if @yesterday_articles
    arr += @opinions if @opinions
    arr += @right_boxes if @right_boxes
    ign_arr = arr.map{|a| a.id}.uniq
    @down_boxes, down_arr = Article.down_boxes(section_id,ign_arr)
    ign_arr += down_arr.map{|a| a.id}
    if (section_id == Section::HOME_SECTION_ID || section_id == Section::NAZORY || section_id == Section::VIKEND)
      @news = Article.middle_news(section_id,12,ign_arr)
    else
      @opinions = Article.middle_opinions(section_id,12,ign_arr)           
    end
  end
end
