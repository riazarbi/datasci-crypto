options(scipen = 999)
library(rvest)
library(dplyr)
library(magrittr)
library(tidyr)
library(readr)

# USDZAR
html <- read_html("https://finance.yahoo.com/quote/USDZAR=X")
dirname <-  "data/yahoo/USDZAR"
timestamp <- round(as.numeric(as.POSIXct( Sys.time() ))*1000,0)
dir.create(dirname, recursive = TRUE, showWarnings = F)

html %>% 
  html_element("#quote-summary") %>% 
  html_table() %>% 
  as_tibble() %>%
  mutate(X2 = as.numeric(X2)) %>%
  select(X2) %>% 
  t() %>% as_tibble(.name_repair = "minimal") %>%
  set_colnames(c("prev_close", "open", "bid", "day_range", "52wk_range", "ask")) %>%
  select(-day_range, -`52wk_range`) %>%
  mutate(client_timestamp = timestamp) %>% 
  write.table("data/yahoo/USDZAR/data.csv", 
              append = TRUE, 
              sep = ",", 
              dec = ".",
              row.names = FALSE, 
              col.names = FALSE)

