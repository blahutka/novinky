class Article < ActiveRecord::Base
  acts_as_taggable
  version_fu do
    belongs_to :author, :class_name=>'::Author'
  end
  
  #new  migrations
  has_many :headliner_boxes
  has_many :article_banners
  
  has_many :headliner_articles
  has_many :headliner_boxes, :through => :headliner_articles
  
  has_many :article_themes
  has_many :themes, :through => :article_themes
  # 
      
  belongs_to :user
  belongs_to :author
  
  has_many :article_selections
  
  #belongs_to :section #added by Jan Uhlar
  belongs_to :subsection #added by Jan Uhlar
  
  belongs_to :content_type
  has_many :article_views #added by Jan Uhlar
  has_many :article_comments, :order=>"created_at" #added by Jan Uhlar
  
  has_many :article_pictures
  has_many :pictures, :through => :article_pictures
  
  has_many :article_insets
  has_many :insets, :through => :article_insets
  
  has_many :article_audios
  has_many :audios, :through => :article_audios
  
  has_many :article_sections
  has_many :sections, :through => :article_sections
  
  has_many :article_boxes
  has_many :info_boxes, :through => :article_boxes
  
  #souvisejici clanky
  has_many :relationships
  has_many :relarticles, :through => :relationships
  
  has_many :inverse_relationships, :class_name => "Relationship", :foreign_key => "relarticle_id"
  has_many :inverse_relarticles, :through => :inverse_relationships, :source => :article
  
  define_index do
    indexes text
    indexes perex
    indexes poznamka
    indexes publish_date, :sortable => true
    indexes created_at
    indexes updated_at, :sortable => true
    indexes :name, :sortable => true
    indexes [author.firstname, author.surname], :as => :author_name
    indexes [tags.name, tags.description], :as => :tags
    indexes [sections.name, sections.description], :as => :sections
    indexes content_type.name, :as => :content_type_name
    set_property :enable_star => true
    set_property :min_prefix_len => 3
  end
 
  #named_scope :by_publish_date, lambda { {:conditions => ["publish_date <= ?", Time.now.utc]} }
  named_scope :by_publish_date,  :conditions => ["publish_date <= ?", Time.now.utc]
  
  
  
  
  before_save do |a|
    if(a.article_sections.size > 0)
    ActiveRecord::Base.connection.execute "UPDATE articles SET priority_section = priority_section - 1 
                                           WHERE priority_section <= #{a.priority_section} 
                                           && priority_section > 1 
                                           && publish_date LIKE '%#{a.publish_date.strftime("%Y-%m-%d").to_s}%'
                                           && id <> #{a.id}
                                           && id IN ( SELECT article_id FROM article_sections WHERE section_id IN (#{a.article_sections.collect {|f| f.section_id }.join(',')}) )"                                      
    ActiveRecord::Base.connection.execute "UPDATE articles SET priority_home = priority_home - 1 
                                           WHERE priority_home <= #{a.priority_home} 
                                           && priority_home > 1 
                                           && publish_date LIKE '%#{a.publish_date.strftime("%Y-%m-%d").to_s}%'
                                           && id <> #{a.id} 
                                           && id IN ( SELECT article_id FROM article_sections WHERE section_id = 9999 )"
                                           
    ActiveRecord::Base.connection.execute "UPDATE articles SET priority_section = 1 
                                           WHERE priority_section > 1
                                           && publish_date < current_date()"
                                           
   ActiveRecord::Base.connection.execute "UPDATE articles SET priority_home = 1 
                                          WHERE priority_home > 1
                                          && publish_date < current_date()"                                       
                                                                                  
    end                                       
  end
  
  #Added by Jan Uhlar
  #Returns header of the article
  def head
    header = ""
    header += self.subsection.name + " " if self.subsection
    header += self.content_type.name
    return header
  end
  
  def section
    self.sections.first
  end
  
  def short_text
    return self.text if self.text.length <= 550
    limit = 500
    sh = self.text.slice(0..limit)
    while sh.last != " "
      limit += 1
      sh = self.text.slice(0..limit-1)
    end
    return sh
  end
  
  #pouze nazory, definovane typem clanku (Glosa, Komentr, Sloupek), 
  #razene podle priority a data vzestupne, na HP pouze aktualni­ den, v pripade ze bude
  #mene jak 2 doplnit starsimi
  #pokud je pondeli, tak limit nastavit na 4
  #minimalni limit pocet clanku = 6
  def self.home_opinions(beg_date = Time.now, options={})
    length_limit = 6
    options[:limit] -= 1
    arr = [ContentType::SLOUPEK,ContentType::KOMENTAR,ContentType::GLOSA]
    op = ""
    if !options[:ignore_arr].blank?
      op += " AND articles.id NOT IN (#{options[:ignore_arr].join(",")})"
    end
    ops = find(:all,
               :conditions=>["priority_home > ? AND publish_date >= ? AND publish_date <= ? AND content_type_id IN (?) AND approved = ? AND visibility = ?#{op}",0,beg_date.beginning_of_day,Time.now,arr,true,false],
               :order=>"priority_home DESC, order_date DESC",
               :include=>[:content_type])
    return ops if ops.length >= length_limit
    return ops if options[:limit] == 0
    while ops.length < length_limit
      beg_date -= 1.days
      return Article.home_opinions(beg_date, options)
    end     
  end
  
  #Returns last articles limited as param
  def self.newest(limit=3,ign_id = nil, section_id = nil)
    op = ""
    op += "article_sections.section_id = '#{section_id}' AND " if section_id
    op += "articles.id != '#{ign_id}' AND " if ign_id
    Article.find(:all,
                 :conditions=>["#{op}publish_date <= ? AND articles.approved = ? AND articles.visibility = ?",Time.now,true,false],
                 :order=>"order_date DESC",
                 :group=>"articles.id",
                 :joins=>[:article_sections],
                 :limit=>limit)
  end
  
  #Returns all articles paginated by current date as param
  #Conditions is publish_date <= Time.now!
  def self.all_by_date(date, page = 1, per_page = 10)
    Article.paginate(:all,
                     :conditions=>["publish_date >= ? AND publish_date <= ? AND publish_date <= ? AND approved = ? AND visibility = ?",date.beginning_of_day,date.end_of_day,Time.now,true,false],
                     :page=>page,
                     :per_page=>per_page,
                     :order=>"order_date DESC")
  end
  
  #Returns the array of readest articles from each section
  def self.all_readest(begin_date)
    readest = []
    ids = [0]
    arr = [Section::NAZORY,Section::DOMOV,Section::SVET,Section::UMENI]
    arr.each do |a|
      article = Article.find(:first,
                                 :conditions=>["article_sections.section_id = ? AND article_views.shown_date >= ? AND article_views.shown_date <= ? AND articles.id NOT IN (?) AND articles.approved = ? AND articles.visibility = ?",a,begin_date,Time.now,ids,true,false],
                                 :select=>"articles.*,COUNT(article_views.article_id) as c",
                                 :group=>"articles.id",
                                 :order=>"c DESC",
                                 :joins=>[:article_views,:article_sections])
      if article
        ids << article.id
        readest << article 
      end  
    end
    return readest
  end
   
  #Returns top tags according to number of articles in each group
  #limited by param 'limit'
  def self.top_taggings(limit = 4) 
    Tagging.find(:all,
                 :select=>"taggings.tag_id,COUNT(taggings.taggable_id) as c",
                 :group=>"taggings.tag_id",
                 :order=>"c DESC",
                 :limit=>limit)
  end
  
  #Returns all today news from all sections except NAZORY and HP 
  def self.today_top_news(limit = 10)
    find(:all,
         :conditions=>["content_type_id = ? AND publish_date >= ? AND publish_date <= ? AND approved = ? AND visibility = ?",ContentType::ZPRAVA,(Time.now - 2.days).beginning_of_day,Time.now,true,false],
         :order=>"priority_section DESC, order_date DESC",
         :include=>[:content_type],
         :group=>"articles.id",
         :limit=>limit)
  end
  
  #Returns all today opinions not from section NAZORY and HP
  def self.today_top_opinions(section_id,limit = 10)
    arr = [ContentType::SLOUPEK,ContentType::KOMENTAR,ContentType::GLOSA]
    find(:all,
         :conditions=>["content_type_id IN (?) AND article_sections.section_id != ? AND publish_date >= ? AND publish_date <= ? AND articles.approved = ? AND articles.visibility = ?",arr,section_id,(Time.now - 2.days).beginning_of_day,Time.now,true,false],
         :order=>"order_date DESC",
         :joins=>[:article_sections],
         :include=>[:content_type],
         :group=>"articles.id",
         :limit=>limit)
  end
  
  #Returns all today articles belonging to the section as params 'section_id'
  #limited by param 'limit'
  #neni v opinions na HP
  def self.from_section(options={})
    def_options = {:ignore_arr => [0],:limit => 2, :from_date => nil}
    options = def_options.merge(options)
    op = ""
    if options[:from_date]
      if options[:to_date]
        op += " AND publish_date >= '#{options[:from_date].beginning_of_day.to_s(:db)}' AND publish_date <= '#{options[:to_date].end_of_day.to_s(:db)}'"
      else
        op += " AND publish_date >= '#{options[:from_date].beginning_of_day.to_s(:db)}' AND publish_date <= '#{options[:from_date].end_of_day.to_s(:db)}'"
      end
    end
    if !options[:ignore_content_type].blank?
      op += " AND articles.content_type_id NOT IN (#{options[:ignore_content_type].join(",")})"
    end
    find(:all,
         :conditions=>["article_sections.section_id = ? AND articles.id NOT IN (?) AND publish_date <= ? AND priority_section > ?#{op} AND articles.approved = ? AND articles.visibility = ?",options[:section_id],options[:ignore_arr],Time.now,0,true,false],
         :order=>"priority_section DESC, order_date DESC",
         :joins=>[:article_sections],
         :include=>[:content_type],
         :limit=>options[:limit])
  end
  
  #Returns all yesterday articles belonging to the section as params 'section_id'
  #limited by param 'limit'
  def self.yesterday_from_section(section_id,limit = 4)
    find(:all,
         :conditions=>["article_sections.section_id = ? AND publish_date >= ? AND publish_date <= ? AND priority_section > ? AND articles.approved = ? AND articles.visibility = ?",section_id,Time.now.yesterday.beginning_of_day,Time.now.yesterday.end_of_day,0,true,false],
         :order=>"priority_section DESC, order_date DESC",
         :joins=>[:article_sections],
         :include=>[:content_type],
         :limit=>limit)
  end
  
  #Returns paginated articles from author given by 'author_id'
  def self.paginate_from_author(author_id, page = 1, per_page = 10)
    paginate(:all,
             :conditions=>["author_id = ? AND publish_date <= ? AND articles.approved = ? AND articles.visibility = ?",author_id,Time.now,true,false],
             :order=>"publish_date DESC",
             :page=>page,
             :per_page=>per_page)
  end
  
  #Returns paginated articles from tag given by 'tag_id'
  def self.paginate_from_tag(tag_id, page = 1, per_page = 10)
    paginate(:all,
             :conditions=>["taggings.tag_id = ? AND publish_date <= ? AND articles.approved = ? AND articles.visibility = ?",tag_id,Time.now,true,false],
             :order=>"publish_date DESC",
             :joins=>"INNER JOIN taggings ON taggings.taggable_id = articles.id",
             :page=>page,
             :per_page=>per_page)
  end
  
  def self.today_by_priority_home
    find(:all,
         :conditions=>["publish_date >= ? AND publish_date <= ? AND priority_home > ? AND articles.approved = ? AND articles.visibility = ?",Time.now.beginning_of_day,Time.now,0,true,false],
         :order=>"priority_home DESC, order_date DESC")
  end
  
  def self.h_box(section_id = Section::HOME_SECTION_ID, beg_date = Time.now.to_date)
    op = section_id.nil? ? "headliner_sections.section_id IS ? AND headliner_boxes.publish_date = ?" : "headliner_sections.section_id = ? AND headliner_boxes.publish_date = ?"
    HeadlinerBox.find(:first,
                      :conditions=>[op,section_id,beg_date],
                      :joins=>[:headliner_sections],
                      :include=>[:article,:picture])
  end
  
  #výstup z modulu Headlinový box, bude definován pro danný den a konkretní 
  #sekci, pokud není pro danný den vytvořen bere se starší datum
  def self.headliner_box(section_id = Section::HOME_SECTION_ID, beg_date = Time.now.to_date)
     return Article.headliner_box_rec(section_id, beg_date)
  end
  
  def self.headliner_box_rec(section_id = Section::HOME_SECTION_ID, beg_date = Time.now.to_date, limit = 10)
     box = Article.h_box(section_id, beg_date)
     return box if box
     #pokud neni definovan pro sekci a danny den, 
     #zkontroluj existenci pro danny den a HP az pak teprve zobraz starsi datum
     #NULL muze byt kdekoliv
     box = Article.h_box(Section::HOME_SECTION_ID,beg_date) if (section_id != Section::HOME_SECTION_ID)
     return box if box
     box = Article.h_box(nil,beg_date) unless box #section_id NULL muze byt kdekoliv
     return box if box
     
     return nil if limit == 0
     limit -= 1
     beg_date = beg_date - 1.days
     return Article.headliner_box_rec(section_id,beg_date,limit)
  end
  
  #Postranní boxy: výstup z modulu Grafické upoutávky (GP) / nezohledňuje se parametr Sekce
  #  - Logika zobrazení Grafické upoutávky: 
  #    - zobrazuje se vždy max. 8 nejnovějších
  #    - minimální počet je 5
  #    - maximální počet GP staršiho data je 3, tato podmínka platí pouze tehdy 
  #      je li naplněn minimální počet. Příklad mám 4 GP definované pro dnešek, 
  #      můžu doplnit 3x GP ze včerejška = celkem 7.
  #default section_id = 9999 ; pokud neni section_id, tak muze byt cokoliv , kde section_id je NULL
  #max pocet starsiho data je 3, pokud neni celkem 5, tak muzu jit o den(vic) zpet..
  def self.r_boxes(section_id = Section::HOME_SECTION_ID, beg_date = Time.now.to_date, limit_count = 8)
    op = section_id.nil? ? "articlebanner_sections.section_id IS ? AND article_banners.publish_date = ?" : "articlebanner_sections.section_id = ? AND article_banners.publish_date = ?"
    ArticleBanner.find(:all,
                       :conditions=>[op,section_id,beg_date],
                       :joins=>[:articlebanner_sections],
                       :include=>[:article,:picture],
                       :limit=>limit_count,
                       :order=>"publish_date DESC, updated_at DESC")
  end
  
  def self.right_boxes(section_id = Section::HOME_SECTION_ID, beg_date = Time.now.to_date, limit_count = 8)
     return Article.right_boxes_rec([], section_id, beg_date).uniq
  end
  
  def self.right_boxes_rec(boxes = [], section_id = Section::HOME_SECTION_ID, beg_date = Time.now.to_date, limit_back = 5, limit_count = 8)
     min_limit_count = 5
     # look at actual section_id
     boxes += Article.r_boxes(section_id,beg_date,limit_count)
     return boxes if boxes.length >= min_limit_count
     # look at section_id 9999
     boxes += Article.r_boxes(Section::HOME_SECTION_ID,beg_date,limit_count)
     return boxes if boxes.length >= min_limit_count 
     # look at section_id NULL
     boxes += Article.r_boxes(nil,beg_date,limit_count) 
     return boxes if boxes.length >= min_limit_count
 
     return boxes if limit_back == 0
     limit_back -= 1
     beg_date = (beg_date - 1.days).to_date
     return Article.right_boxes_rec(boxes,section_id,beg_date,limit_back,min_limit_count - boxes.length)
  end
  
  def self.down_boxes(section_id,ign_arr)
    down_boxes = []
    ign_cont = [ContentType::ZPRAVA,ContentType::SLOUPEK,ContentType::KOMENTAR,ContentType::GLOSA]
    [Section::DOMOV,Section::SVET,Section::UMENI].each do |sec|
      if section_id == sec
        ar = []
        ar += Article.from_section(:section_id=>Section::NAZORY,:limit=>1)
        ar += Article.from_section(:section_id=>Section::NAZORY,:limit=>1,:ignore_arr=>ign_arr, :ignore_content_type=>ign_cont)
        down_boxes << ["Názory",ar] unless ar.blank?
      else
        ar = Article.from_section(:section_id=>sec,:ignore_arr=>ign_arr, :ignore_content_type=>ign_cont)
        down_boxes << [Section.find(sec).name,ar] unless ar.blank?
      end
    end
    down_boxes
  end
  ########################## end added by Jan Uhlar
end