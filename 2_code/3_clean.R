require(tidyverse)

articles = readRDS("1_data/articles_overview.RDS")

models = read_csv("1_data/models_llama405.csv")
names(models) = c("name", "response")

models = models |> 
  mutate(models = str_extract(response, "LLMs[:blank:]*=[:blank:]*\\[[^\\]]+") |> 
           str_remove("LLMs=\\[") |> 
           str_remove_all("'") |> 
           str_squish())

articles = articles |> 
  filter(!is.na(submitted)) |> 
  left_join(models)  

handle_parentheses = function(x) {
  patterns = str_extract_all(x, "\\([^\\)]+")[[1]]
  if(length(patterns) == 0) return(x)
  for(i in 1:length(patterns)){
    pattern = patterns[i]
    pattern_new = pattern |> str_replace_all(",", ";")
    x = x |> stringi::stri_replace_all_fixed(pattern, pattern_new)
  }
  x
}

articles = articles |> 
  mutate(models = str_remove(models, "LLMs[:blank:]*\\=[:blank:]*\\[") |> 
           str_to_lower() |> 
           sapply(handle_parentheses) |> 
           str_remove_all("\"") |> 
           str_remove_all("\'") |> 
           str_remove_all("\`")) 

unique_models = articles |> 
  pull(models) |> 
  str_split(",") |> 
  unlist() |> 
  str_squish() |> 
  unique() |> 
  sort()

#write_lines(unique_models, "unique_models.txt")

models_clean = read_csv("1_data/models_clean.csv") |> 
  filter(Type %in% c("text", "embedding"))

match = function(models, variable){
  mod = models |> 
    str_split(",") |> 
    lapply(function(x) str_squish(x))
  var = models_clean[[variable]]
  names(var) = models_clean$Entry
  lapply(mod, function(x) unique(var[x]))
  }

articles = articles |> 
  mutate(models_names = match(models, "Name"),
         models_status = match(models, "Status"),
         models_type = match(models, "Type"),
         models_open = sapply(models_status, function(x) "open" %in% x),
         models_closed = sapply(models_status, function(x) "closed" %in% x),
         models_text = sapply(models_type, function(x) "text" %in% x),
         models_embedding = sapply(models_type, function(x) "embedding" %in% x))

saveRDS(articles, "1_data/article_results.RDS")

