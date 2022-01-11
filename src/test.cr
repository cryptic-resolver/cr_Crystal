require "toml"

toml_string = %(
  title = "TOML Example"

  [owner]
  name = "Lance Uppercut"
  dob = 1979-05-27T07:32:00Z
)

toml = TOML.parse(toml_string)

puts typeof(toml)

puts toml["title"] #=> "TOML Example"

owner = toml["owner"].as(Hash)
puts owner["name"] #=> "Lance Uppercut"
puts owner["dob"]  #=> "1979-05-27 07:32:00 UTC"

puts File.expand_path("~/.cryptic-resolver", home: Path.home) # different with Ruby
