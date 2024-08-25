require(tidyverse)
require(xml2)
require(rvest)
require(RSelenium)

articles = lapply(list.files("1_data/article_info", pattern = "articles_", full.names = TRUE) |> sapply(function(x) x[!str_detect(x, "overview")]) |> unlist(),
       function(x) {
         articles = read_csv(x)[-1]
         names(articles) = c("name", "url")
         articles |> 
           mutate(source = str_extract(x, "_[:alpha:]+_") |> str_remove_all("_"),
                  keyword = str_extract(x, "_[^_]+$") |> str_remove_all("_") |> str_remove(".csv") |> str_remove_all("%22") |> str_replace_all("%20"," ")) |> 
           select(source, keyword, everything())
       }) |> do.call(what = bind_rows)


articles = articles |> 
  filter(name != "Experiment ended",
         !duplicated(url))

driver = RSelenium::rsDriver(browser = "firefox", 
                             port = as.integer(4579))

names = articles$url |> str_remove("https://osf.io/")
article_info = matrix(nrow = nrow(articles), ncol = 8,
                      dimnames = list(names, c("authors", "title", "abstract", "disciplines", "tags", "date", "view", "download")))

for(i in sel){
  
  print(i)
  
  url = articles$url[i] 
  name = url |> str_remove("https://osf.io/")

  # get page  
  Sys.sleep(runif(1, 2, 4))
  driver$client$navigate(url = url)
  Sys.sleep(runif(1, 4, 6))
  page = driver$client$getPageSource()[[1]]
  write_file(page, paste0("pages/", name, ".html"))
  page = gsub("\ufffe", " ", page)
  html = read_html(page)

  # check if not found
  not_found = rvest::html_nodes(html, xpath="//div[starts-with(@class, '_not-found')]") |> html_text()
  if(any(str_detect(not_found, "The requested resource could not be found"))) {
    article_info[name,] = rep("WITHDRAWN", 8)
    next
    }
  
  # check if withdrawn
  title = rvest::html_nodes(html, xpath= '//h1[@data-test-preprint-title=""]') |> html_text("href")
  if(str_detect(title, "Withdrawn\\: ")) {
    article_info[name,] = rep("WITHDRAWN", 8)
    next
    }

  # get details    
  authors = rvest::html_nodes(html, xpath= '//a[@data-analytics-name="Contributor name"]') |> html_text("href")
  abstract = rvest::html_nodes(html, xpath="//div[@data-test-preview-wrapper='']") |> html_text()
  disciplines = rvest::html_nodes(html, xpath='//span[@data-test-subjects=""]') |> html_text()
  tags = rvest::html_nodes(html, xpath='//span[@data-test-tags=""]') |> html_text()
  date = rvest::html_nodes(html, xpath="//div[starts-with(@class, '_file-description')]") |> html_text()
  view = rvest::html_nodes(html, xpath='//span[@data-test-view-count=""]') |> html_text()
  download = rvest::html_nodes(html, xpath='//span[@data-test-download-count=""]') |> html_text()
  if(length(tags) == 0) tags = NA
  article_info[name,] = c(paste0(authors, collapse=";"), title, abstract, disciplines, tags, date[1], view, download)
  
  # download
  download.file(url = paste0(articles$url[i], "/download/"),
                destfile = paste0("articles/",name,".pdf"),
                quiet = TRUE)
  }


article_tbl = articles |> 
  bind_cols(as_tibble(article_info) |> readr::type_convert())

article_tbl = article_tbl |> 
  mutate(abstract = abstract |> str_remove_all("\n") |> str_squish(),
         disciplines = disciplines |> str_split("\n") |> sapply(function(x) str_squish(x)) |> sapply(function(x) x[x!=""]),
         tags = tags |> str_split("\n") |> sapply(function(x) str_squish(x)) |> sapply(function(x) x[x!=""]),
         submitted = date |> str_extract("Submitted[^\n]+|Created[^\n]+") |> str_remove("Submitted: |Created: ") |> mdy(),
         edited = date |> str_extract("Last edited[^\n]+") |> str_remove("Last edited: ") |> mdy(),
         view = as.integer(view),
         download = as.integer(download),
         name = url |> str_remove("https://osf.io/")) |> 
  select(-date)

saveRDS(article_tbl, "1_data/articles_overview.RDS")
