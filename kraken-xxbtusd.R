library(httr)

file <- "data/kraken/XXBTZUSD/data.csv"

dir.create(dirname(file), recursive = T, showWarnings = F)

timestamp <- round(as.numeric(as.POSIXct( Sys.time() ))*1000,0)

response <- GET('https://api.kraken.com/0/public/Ticker?pair=XXBTZUSD') 
response_content <- content(response)
result <- response_content$result
if (length(result) != 0) {
  # do some processing
  XXBTZUSD <- result$XXBTZUSD
  ask <- as.numeric(XXBTZUSD$a[[1]])
  bid <- as.numeric(XXBTZUSD$b[[1]])
  last <- as.numeric(XXBTZUSD$c[[1]])
  volume <- as.numeric(XXBTZUSD$v[[1]])
  vwap_today <- as.numeric(XXBTZUSD$p[[1]])
  num_trades_today <- as.numeric(XXBTZUSD$t[[1]])
  low_today <- as.numeric(XXBTZUSD$l[[1]])
  high_today <- as.numeric(XXBTZUSD$h[[1]])
  paste(timestamp,ask,bid,last,volume,vwap_today,num_trades_today,low_today,high_today,sep=",") %>%
  write(file, 
        append = T)
  
}  
  
