# please run from root dir
RACK_ENV=production bundle exec sidekiq -r ./bootstrap.rb -C ./config/sidekiq.yml
