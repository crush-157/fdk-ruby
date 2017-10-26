# assumes function deployed at least once
puts `fn routes update myapp /fdk-ruby --format default`
puts "Cold"
10.times do |i|
    start = Time.now
    puts `echo '{"name":"dawg #{i}"}' | fn call myapp /fdk-ruby`
    puts "time: #{Time.now - start}"
end
puts `fn routes update myapp /fdk-ruby --format json`
puts "Hot"
10.times do |i|
    start = Time.now
    puts `echo '{"name":"dawg #{i}"}' | fn call myapp /fdk-ruby`
    puts "time: #{Time.now - start}"
end
