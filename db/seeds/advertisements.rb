require "database_cleaner"

DatabaseCleaner.strategy = :truncation, {:only => %w[advertisements advertisement_contents]}
DatabaseCleaner.clean

adv = Advertisement.create!(:module_name => 'home_page')
content = AdvertisementContent.create(:advertiser_name => 'Pola s.r.o',
                                      :date_finish => 3.days.from_now,
                                      :date_start => 1.hour.ago,
      :photo => Rails.root.join('public/images/banner_468x60.gif').to_s,
                                      :link => 'http://www.seznam.cz', :note => 'Nezaplaceno')
adv.advertisement_contents << content