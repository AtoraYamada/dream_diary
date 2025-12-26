json.id dream.id
json.title dream.title
json.content dream.content
json.emotion_color dream.emotion_color
json.lucid_dream_flag dream.lucid_dream_flag
json.dreamed_at dream.dreamed_at

json.tags dream.tags do |tag|
  json.id tag.id
  json.name tag.name
  json.yomi tag.yomi
  json.category tag.category
end

json.created_at dream.created_at
json.updated_at dream.updated_at
