json.id dream.id
json.title dream.title
json.emotion_color dream.emotion_color
json.lucid_dream_flag dream.lucid_dream_flag
json.dreamed_at dream.dreamed_at

json.tags dream.tags do |tag|
  json.id tag.id
  json.name tag.name
  json.yomi tag.yomi
  json.category tag.category
end
