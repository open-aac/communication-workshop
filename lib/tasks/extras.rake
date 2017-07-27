task "extras:assert_js" do
  `mkdir -p ./app/frontend/dist/assets`
  `cp -n ./app/frontend/frontend-placeholder.js ./app/frontend/dist/assets/frontend.js`
  `touch ./app/frontend/dist/assets/vendor.js`
  `cd app/assets/javascripts/ && ln -sf ../../frontend/dist/assets/frontend.js frontend.js`
  `cd app/assets/javascripts/ && ln -sf ../../frontend/dist/assets/vendor.js vendor.js`
end

task "extras:jobs_list" do
  require 'worker'
  puts "default queue"
  puts Worker.scheduled_actions('default')
  puts "priority queue"
  puts Worker.scheduled_actions('priority')
  puts "slow queue"
  puts Worker.scheduled_actions('slow')
end
