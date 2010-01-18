Factory.define(:checkout) do |record|
  record.email { Faker::Internet.email }
  record.special_instructions { Faker::Lorem.paragraphs(rand(5)+1).join("\n") }

  # associations: 
  record.association(:order)
  record.association(:bill_address, :factory => :address)
  record.association(:creditcard)
end

###### ADD YOUR CODE BELOW THIS LINE #####

Factory.define :incomplete_checkout, :parent => :checkout do |f|
  
end