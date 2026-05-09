require "net/http"
require "pg"

Rails.application.config.after_initialize do
  Pay::Webhooks::ProcessJob.retry_on ActiveRecord::Deadlocked,
    ActiveRecord::LockWaitTimeout,
    ActiveRecord::ConnectionNotEstablished,
    ActiveRecord::ConnectionTimeoutError,
    PG::ConnectionBad,
    PG::UnableToSend,
    Stripe::APIConnectionError,
    Stripe::RateLimitError,
    Net::OpenTimeout,
    Net::ReadTimeout,
    SocketError,
    EOFError,
    wait: :polynomially_longer,
    attempts: 5,
    report: true
end
