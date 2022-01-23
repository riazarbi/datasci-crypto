Sys.setenv("SECRETS_FILE" = "/home/jovyan/secrets.json")
secrets <- jsonlite::fromJSON(Sys.getenv("SECRETS_FILE"))

library(blastula)
library(gt)
library(glue)

# Refresh
source("compute_plot_est_return.R")

sender <- secrets$arbidata$gmail$username
Sys.setenv(SMTP_PASSWORD = secrets$arbidata$gmail$password)
recipients <- sapply(secrets$crypto_users, function(x) x[["email"]][["address"]])

# Subject ---
subject <- "Daily BTCZAR Arbitrage Report"

# Date ---
date_time <- add_readable_time()

# Plots ----
luno_plot <- add_ggplot(luno_plot)
kraken_plot <- add_ggplot(kraken_plot)
yahoo_plot <- add_ggplot(yahoo_plot)
estimated_return_plot <- add_ggplot(estimated_return_plot)

result <- round(result,4)*100

mood <- ifelse(result[3] < 1, "You'll lose money",
                 ifelse(result[3] < 2, "Maybe if you're desperate",
                   ifelse(result[3] < 3, 
                      "Lookin pretty good",
                      "Holy shit do it now!!")))

# Body ---
message_body <-
glue(
"
### Dispatch: {date_time}

### TL;DR: {mood}

### Deets

Over the last 24 hours:

- A ZAR100k round trip could net a {result[2]}% return
- A ZAR200k round trip could net a {result[3]}% return
- A ZAR300k round trip could net a {result[4]}% return
- A ZAR500k round trip could net a {result[5]}% return
- A ZAR1m round trip could net a {result[6]}% return

Below are some charts to help you decide what to do next - 

#### Estimated Return Plot
{estimated_return_plot}

#### Kraken Plot
{kraken_plot}

#### Luno Plot
{luno_plot}

#### Yahoo Plot
{yahoo_plot}

Cheerio,

Riaz

"
  )

email <- blastula::compose_email(body = md(message_body))

  smtp_send(
    email = email,
    from = sender,
    to = recipients,
    subject = subject,
    credentials = creds_envvar(
      user = sender,
      pass_envvar = "SMTP_PASSWORD",
      host = "smtp.gmail.com",
      port = 465,
      use_ssl = TRUE
    )
  )


