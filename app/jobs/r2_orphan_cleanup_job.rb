class R2OrphanCleanupJob < ApplicationJob
  queue_as :default

  # Removes R2 objects that have no database reference. Runs daily at 04:00
  # via config/recurring.yml. Safe to run ad-hoc too (Avo action).
  #
  # Safety rules:
  #   - Only considers objects older than MIN_AGE (24h). Anything fresh is
  #     skipped so we never race an in-flight "upload then save" flow.
  #   - Scans only the prefixes the app actually writes to (profiles/,
  #     credentials/). Anything else in the bucket is left alone.
  #   - Every delete is logged at INFO with bucket, key, last_modified,
  #     size so there's a permanent record of what got removed.

  MIN_AGE = 24.hours
  BATCH_SIZE = 100

  # Buckets to scan. Each target declares the credential key for its
  # R2 bucket name, the prefix to list under, and a proc that returns
  # the set of in-use keys at job time.
  TARGETS = [
    {
      bucket_key: :R2_HEADSHOTS_BUCKET_NAME,
      prefix: "profiles/",
      in_use: -> { Therapist.where.not(practice_image_key: nil).pluck(:practice_image_key).to_set }
    },
    {
      bucket_key: :R2_CREDENTIALS_BUCKET_NAME,
      prefix: "credentials/",
      in_use: -> { UserCredential.where.not(credential_document: nil).pluck(:credential_document).to_set }
    }
  ].freeze

  def perform
    cutoff = MIN_AGE.ago

    TARGETS.each do |target|
      bucket = fetch_credential!(target[:bucket_key])
      in_use_keys = target[:in_use].call
      prefix = target[:prefix]

      Rails.logger.info(event: "r2.cleanup.target.start",
        bucket: bucket, prefix: prefix,
        in_use_count: in_use_keys.size, cutoff: cutoff.iso8601)

      orphans = scan_orphans(bucket: bucket, prefix: prefix,
        in_use_keys: in_use_keys, cutoff: cutoff)

      delete_in_batches(bucket: bucket, orphans: orphans)

      Rails.logger.info(event: "r2.cleanup.target.done",
        bucket: bucket, prefix: prefix,
        orphan_count: orphans.size)
    end
  rescue KeyError => e
    Rails.logger.error(event: "r2.cleanup.config_error", message: e.message)
    raise
  end

  private

  def scan_orphans(bucket:, prefix:, in_use_keys:, cutoff:)
    orphans = []
    continuation_token = nil

    loop do
      response = r2_client.list_objects_v2(
        bucket: bucket,
        prefix: prefix,
        continuation_token: continuation_token
      )

      response.contents.each do |obj|
        next if in_use_keys.include?(obj.key)
        next if obj.last_modified > cutoff

        orphans << { key: obj.key, last_modified: obj.last_modified, size: obj.size }
      end

      break unless response.is_truncated

      continuation_token = response.next_continuation_token
    end

    orphans
  end

  def delete_in_batches(bucket:, orphans:)
    orphans.each_slice(BATCH_SIZE) do |batch|
      batch.each do |orphan|
        Rails.logger.info(
          event: "r2.cleanup.delete",
          bucket: bucket,
          key: orphan[:key],
          last_modified: orphan[:last_modified].iso8601,
          size: orphan[:size]
        )
        r2_client.delete_object(bucket: bucket, key: orphan[:key])
      end
    end
  end

  def r2_client
    @r2_client ||= Aws::S3::Client.new(
      region: "auto",
      endpoint: fetch_credential!(:R2_ENDPOINT),
      credentials: Aws::Credentials.new(
        fetch_credential!(:R2_ACCESS_KEY_ID),
        fetch_credential!(:R2_SECRET_ACCESS_KEY)
      ),
      token_provider: nil
    )
  end

  def fetch_credential!(key)
    value = Rails.application.credentials.fetch(key)
    raise KeyError, "#{key} is blank" if value.blank?

    value
  end
end
