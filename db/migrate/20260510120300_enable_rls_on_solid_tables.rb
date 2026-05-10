class EnableRlsOnSolidTables < ActiveRecord::Migration[8.1]
  SOLID_TABLES = %w[
    solid_cache_entries
    solid_cable_messages
    solid_queue_blocked_executions
    solid_queue_claimed_executions
    solid_queue_failed_executions
    solid_queue_jobs
    solid_queue_pauses
    solid_queue_processes
    solid_queue_ready_executions
    solid_queue_recurring_executions
    solid_queue_recurring_tasks
    solid_queue_scheduled_executions
    solid_queue_semaphores
  ].freeze

  def up
    SOLID_TABLES.each do |table|
      execute "ALTER TABLE #{quote_table_name(table)} ENABLE ROW LEVEL SECURITY"
    end
  end

  def down
    SOLID_TABLES.reverse_each do |table|
      execute "ALTER TABLE #{quote_table_name(table)} DISABLE ROW LEVEL SECURITY"
    end
  end
end
