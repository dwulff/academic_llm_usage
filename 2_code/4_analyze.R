require(tidyverse)

articles = readRDS("1_data/article_results.RDS")

articles |> 
  filter(models_text | models_embedding) |> 
  mutate(days = as.integer(lubridate::today() - submitted)) |> 
  group_by(models_embedding) |> 
  summarize(open = sum(models_open, na.rm=T),
            closed = sum(models_closed, na.rm=T),
            open_viewed = mean((view/days)[models_open], na.rm=T),
            closed_viewed = mean((view/days)[models_closed], na.rm=T),
            percent_open = open / (open + closed))

model_count = articles |> 
  mutate(quarter = paste0(year(submitted), "-Q", quarter(submitted))) |> 
  filter(quarter > "2019-Q4", quarter < "2024-Q3") |> 
  group_by(quarter) |> 
  summarize(`(Chat)GPT` = sapply(models_names, function(x) "(Chat)GPT" %in% x) |> sum(),
            Mistral = sapply(models_names, function(x) "Mistral" %in% x) |> sum(),
            Claude = sapply(models_names, function(x) "Claude" %in% x) |> sum(),
            BERT = sapply(models_names, function(x) "BERT" %in% x) |> sum(),
            Llama = sapply(models_names, function(x) "Llama" %in% x) |> sum(),
            Gemini = sapply(models_names, function(x) "Gemini" %in% x) |> sum()) |> 
  pivot_longer(-quarter, names_to = "model", values_to = "count") |> 
  mutate(count = ifelse(count == 0, NA, count),
         type = case_when(
           model %in% c("(Chat)GPT", "Gemini", "Claude") ~ "Closed",
           TRUE ~ "Open"))

frequencies = unlist(articles$models_names) |> table()
sum(frequencies[c("(Chat)GPT", "Mistral", "Claude", "BERT", "Llama", "Gemini")])/sum(frequencies)

cols = c(viridis::mako(3, begin=.3, end = .4),
         viridis::mako(3, begin=.7, end = .8))

p = model_count |> 
  mutate(model = factor(model, levels = c("(Chat)GPT","Gemini","Claude","BERTs","Llama","Mistral"))) |> 
  ggplot(aes(quarter, count, col = model, fill = model, group = model)) +
  geom_text(data = model_count |> filter(quarter == "2024-Q2") |> 
              mutate(count = count + c(0,-1,1,1.1,1.1,0)), 
            mapping = aes(label = model), 
            nudge_x = .5, hjust = 0, size=4) +
  geom_line(linewidth = 1) +
  geom_point(size=5, pch=22, col = "white", stroke = .5) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle=90), axis.title.x = element_blank()) + 
  scale_color_manual(values = cols) +
  scale_fill_manual(values = cols) +
  scale_y_continuous(limits=c(0, 100)) +
  labs(title = "Behavioral and social science research still favors <span style = 'color:#3E4D93FF'><b>closed</b></span> over <span style = 'color:#49C1ADFF'><b>open</b></span> LLMs",
       subtitle = "Analysis of 2,144 articles published on OSF, PsyArXiv, and SocArXiv matching the\nkeywords large language model(s), LLM(s), or artificial intelligence (AI). Processed\nusing Llama-3.1-405B.",
       y = "Number of articles using the LLM",
       caption = "Created by @dirkuwulff, 2024")+
  coord_cartesian(clip = "off") +
  guides(col = "none", fill = "none") +
  theme(plot.margin = unit(c(.5,2.5,.2,.2), "cm"), plot.caption.position = "panel",
        axis.title.y = element_text(size = 14),
        plot.title = ggtext::element_textbox_simple(size = 20,
                                                    lineheight = 1, padding = margin(0, -60, 10, 0)))

ggsave("models.png",device = "png", plot = p, width = 7, height=7, bg = "white") 


