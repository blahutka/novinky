namespace :per_hour do  
  task :clear_cache => :environment do
    cache = ActiveSupport::Cache.lookup_store(:file_store, "/tmp/cache")
    puts cache.delete('Author.all_right')
    [0,1,2,3,4,5,9999].each do |sec|
      [1,2,3].each do |typ|
        puts cache.delete("Article.all_readest.#{typ}.#{sec}")
      end
    end
    puts cache.delete('Article.newest')
    puts cache.delete('Article.discussed')
    puts 'cache cleared'
  end 
end