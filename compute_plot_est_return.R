library(dplyr)
library(xts)
library(data.table)
library(ggplot2)

# Refresh
source("yahoo-usdzar.R")
source("xe-rates.R")
source("luno-xbtzar.R")
source("kraken-xxbtusd.R")

# Math ----

# yahoo USDZAR
file_path <- "data/yahoo/USDZAR/data.csv"
yahoo_usdzar <- fread(file_path)
  
time_component <- as.POSIXct(as.numeric(yahoo_usdzar$client_timestamp)/1000, origin="1970-01-01")
data_component <- yahoo_usdzar %>% 
  select(bid, ask) %>% 
  rename(yahoo_bid = bid,
         yahoo_ask = ask) %>%
  mutate(across(everything(), as.numeric))
yahoo_usdzar <- xts(data_component, order.by=time_component)
yahoo_plot <- yahoo_usdzar %>% last("4 weeks") %>% 
  ggplot(aes(x = Index, y = yahoo_ask)) + 
  geom_line()  + 
  scale_y_continuous(name = "USDZAR") +
  ggtitle('Yahoo USDZAR Spot Prices, last month') 


# kraken XXBTZUSD
dir_path <- "data/kraken/XXBTZUSD/"
kraken_xbtusd <- do.call(rbind,lapply(list.files(dir_path, full.names = T),fread))

time_component <- as.POSIXct(as.numeric(kraken_xbtusd$client_timestamp)/1000, origin="1970-01-01")
data_component <- kraken_xbtusd %>% 
  select(bid, ask, last) %>% 
  rename(kraken_bid = bid,
         kraken_ask = ask,
         kraken_spot = last) %>%
  mutate(across(everything(), as.numeric))
kraken_xbtusd <- xts(data_component, order.by=time_component)
kraken_plot <- kraken_xbtusd %>% last("4 weeks") %>% 
  ggplot(aes(x = Index, y = kraken_spot)) + 
  geom_line()  + 
  scale_y_continuous(name = "Kraken Spot") +
  ggtitle('Kraken BTC-USD Spot Prices, last month') 

kraken_xbtusd <- transform(kraken_xbtusd, kraken_spread = (kraken_ask/ kraken_bid - 1)*10000) %>% as.xts

# luno XBTZAR
dir_path <- "data/luno/XBTZAR"
luno_xbtzar <- do.call(rbind,lapply(list.files(dir_path, full.names = T),fread))

time_component <- as.POSIXct(as.numeric(luno_xbtzar$client_timestamp)/1000, origin="1970-01-01")
data_component <- luno_xbtzar %>% select(bid, ask, last_trade) %>% 
  rename(luno_bid = bid,
         luno_ask = ask,
         luno_last = last_trade) %>%
  mutate(across(everything(), as.numeric))
luno_xbtzar <- xts(data_component, order.by=time_component)

luno_plot <- luno_xbtzar %>% last("4 weeks") %>% 
  ggplot(aes(x = Index, y = luno_last)) + 
  geom_line()  + 
  scale_y_continuous(name = "Luno Last") +
  ggtitle('Luno BTC-ZAR Last Trade Price, last month') 

luno_xbtzar <- transform(luno_xbtzar, luno_spread = (luno_ask/ luno_bid - 1)*10000) %>% as.xts

# Merge it all
#ts <- merge(luno_xbtzar, kraken_xbtusd, yahoo_usdzar) %>% na.locf(fromLast=TRUE) %>% last('1 week')
#plot(ts)

# Potential profit ----
timestamp <- round(as.numeric(as.POSIXct( Sys.time() ))*1000,0)
principals <- c(100000, 200000, 300000, 500000, 1000000)

result <- timestamp
for (principal in principals) {
  fee <- ifelse(principal > 100000, 450, 550)
  broker_spread <- 0.005
  
  interbank_usdzar_rate <- median(last(yahoo_usdzar$yahoo_ask, '1 day'), na.rm = T)
  broker_usdzar_rate <- interbank_usdzar_rate * (1+broker_spread)
  principal_usd <- (principal - fee) / broker_usdzar_rate 
  
  kraken_usd_deposit_fee <- 0
  kraken_usd_net <- principal_usd - kraken_usd_deposit_fee
  
  kraken_commission <- 0.0026
  kraken_usdbtc_rate <- median(last(kraken_xbtusd$kraken_ask, "1 day"), na.rm = T)
  kraken_btc <- principal_usd / kraken_usdbtc_rate / (1+kraken_commission)
  
  kraken_btc_withdrawal_fee <-	0.00015
  luno_btc <- kraken_btc - kraken_btc_withdrawal_fee
  
  luno_commission <- 0.001
  luno_btczar_rate <- median(last(luno_xbtzar$luno_bid, "1 day"), na.rm = T)
  luno_zar_net <- luno_btc * luno_btczar_rate /(1+luno_commission)
  luno_withdrawal_fee <- 0
  bank_zar_net <- luno_zar_net - luno_withdrawal_fee
  bank_zar_net
  
  overall_return <- bank_zar_net / principal - 1
  overall_return
  result <- c(result, overall_return)
}

# Write out to file
write(paste(result, collapse = ","), "data/arbitrage/zarbtc_estimated_return.csv", append = T)

# Plot potential profit
file_path <- "data/arbitrage/zarbtc_estimated_return.csv"
zarbtc_estimated_return <- fread(file_path)

time_component <- as.POSIXct(as.numeric(zarbtc_estimated_return$timestamp)/1000, origin="1970-01-01")
data_component <- zarbtc_estimated_return %>% select(starts_with("ZAR"))
zarbtc_estimated_return <- xts(data_component, order.by=time_component)

estimated_return_plot <- zarbtc_estimated_return %>%
  last("4 weeks") %>% 
    ggplot(aes(x = Index)) + 
   geom_line(aes(y = ZAR100k, color = "ZAR100k")) +
  geom_line(aes(y = ZAR200k, color = "ZAR200k")) +
  geom_line(aes(y = ZAR300k, color = "ZAR300k")) +
  geom_line(aes(y = ZAR500k, color = "ZAR500k")) +
  geom_line(aes(y = ZAR1m, color = "ZAR1m")) +
  scale_colour_manual("", 
                      values = c("ZAR100k"="green", "ZAR200k"="red", 
                                 "ZAR300k"="blue", "ZAR500k"="black", "ZAR1m"="yellow")) +
    scale_y_continuous(name = "Estimated % return",labels = scales::percent) +
    ggtitle('Estimated % return, last month') 
  
