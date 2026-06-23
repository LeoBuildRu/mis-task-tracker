# Ensure the three mandatory system tags always exist.
Tag.ensure_system_tags!

puts "System tags: #{Tag.system.pluck(:name).join(', ')}"
