web: bundle exec puma -C config/puma.rb
ember: sh -c 'cd ./app/frontend/ && ember server --port 4201'
resque: env QUEUES=priority,default INTERVAL=0.2 TERM_CHILD=1 bundle exec rake environment resque:work
resque_slow: env QUEUES=priority,slow,default INTERVAL=0.2 TERM_CHILD=1 bundle exec rake environment resque:work
