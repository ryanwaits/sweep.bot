set :environment, ENV["RACK_ENV"]
set :output, {:error => "log/cron_error_log.log", :standard => "log/cron_log.log"}

#test crons
every [:saturday], at: ['11:42 pm'] do
  rake 'nfl:send_notification'
end

every [:saturday], at: ['12:25'] do
  rake 'nfl:reminder'
end
# end test crons

every [:thursday], at: ['7:00 pm'] do
  rake 'nfl:reminder'
end

every [:sunday], at: ['11:30 am', '2:45 pm', '7:00 pm'] do
  rake 'nfl:reminder'
end

every [:monday], at: ['7:00 pm'] do
  rake 'nfl:reminder'
end

every [:thursday], at: ['10:30 pm', '10:35 pm', '10:40 pm', '10:45 pm', '10:50 pm', '10:55 pm', '11:00 pm', '11:05 pm', '11:10 pm', '11:15 pm', '11:20 pm', '11:25 pm', '11:30 pm'] do
  rake 'nfl:send_notification'
end

every [:sunday], at: ['2:30 pm', '2:35 pm', '2:40 pm', '2:45 pm', '2:50 pm', '2:55 pm', '3:00 pm', '3:05 pm', '3:10 pm', '3:15 pm', '3:20 pm', '3:25 pm', '3:30 pm', '3:35 pm', '3:40 pm'] do
  rake 'nfl:send_notification'
end

every [:sunday], at: ['6:00 pm', '6:05 pm', '6:10 pm', '6:15 pm', '6:20 pm', '6:25 pm', '6:30 pm', '6:35 pm', '6:40 pm', '6:45 pm', '6:50 pm', '6:55 pm', '7:00 pm'] do
  rake 'nfl:send_notification'
end

every [:sunday], at: ['10:30 pm', '10:35 pm', '10:40 pm', '10:44 pm', '10:45 pm', '10:46 pm', '10:47 pm', '10:50 pm', '10:55 pm', '11:00 pm', '11:05 pm', '11:10 pm', '11:15 pm', '11:20 pm', '11:25 pm', '11:30 pm'] do
  rake 'nfl:send_notification'
end