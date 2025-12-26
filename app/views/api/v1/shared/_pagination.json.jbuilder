json.pagination do
  json.current_page collection.current_page
  json.total_pages collection.total_pages
  json.total_count collection.total_count
  json.per_page collection.limit_value
end
