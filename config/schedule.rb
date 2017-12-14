set :environment, ENV["RACK_ENV"]
set :output, {:error => "log/cron_error_log.log", :standard => "log/cron_log.log"}

every [:thursday], at: ['7:00 pm'] do
  rake 'nfl:reminder'
end

every [:sunday], at: ['9:00 am'] do
  rake 'nfl:reminder'
end

every [:monday], at: ['5:00 pm'] do
  rake 'nfl:reminder'
end

every [:thursday], at: ['10:30 pm', '10:35 pm', '10:40 pm', '10:45 pm', '10:50 pm', '10:55 pm', '11:00 pm', '11:05 pm', '11:10 pm', '11:15 pm', '11:20 pm', '11:25 pm', '11:30 pm'] do
  rake 'nfl:send_notification'
end

every [:sunday], at: ['3:14 pm', '3:15 pm', '3:20 pm', '3:25 pm', '3:30 pm', '3:35 pm', '3:40 pm'] do
  rake 'nfl:send_notification'
end

every [:sunday], at: ['6:25 pm', '6:30 pm', '6:35 pm', '6:40 pm', '6:45 pm', '6:50 pm', '6:55 pm', '6:58 pm', '7:00 pm', '7:02 pm', '7:03 pm', '7:05 pm'] do
  rake 'nfl:send_notification'
end

every [:sunday], at: ['10:30 pm', '10:35 pm', '10:40 pm', '10:45 pm', '10:50 pm', '10:55 pm', '11:00 pm', '11:05 pm', '11:10 pm', '11:15 pm', '11:20 pm', '11:25 pm', '11:30 pm'] do
  rake 'nfl:send_notification'
end