json.dreams @dreams do |dream|
  json.partial! 'api/v1/dreams/dream_summary', dream: dream
end

json.partial! 'api/v1/shared/pagination', locals: { collection: @dreams }
