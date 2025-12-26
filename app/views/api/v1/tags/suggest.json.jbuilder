json.suggestions @tags do |tag|
  json.id tag.id
  json.name tag.name
  json.yomi tag.yomi
  json.category tag.category
end
