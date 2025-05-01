# ActiveJob Implementation Specification for Storage Cleanup

## Overview

This document outlines how to replace the current cron-based ActiveStorage blob cleanup with Rails 8's ActiveJob framework using Solid Queue.

## Current Implementation

Currently, unattached ActiveStorage blobs are cleaned up via:
- A rake task that runs `ActiveStorage::Blob.unattached.where("active_storage_blobs.created_at <= ?", 2.days.ago).find_each(&:purge_later)`
- A cron job configured in Docker that runs this task daily

## Proposed Implementation

### 1. Enable ActiveJob

Update `/config/application.rb` to enable ActiveJob:

```ruby
require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"  # Uncomment this line
require "active_record/railtie"
# ...rest of the file
```

### 2. Add Solid Queue

Add Solid Queue (Rails 8's default job backend) to the Gemfile:

```ruby
# Gemfile
# Background processing
gem "solid_queue"
```

Run installation:

```bash
bundle install
rails solid_queue:install:migrations
rails db:migrate
```

### 3. Create Storage Cleanup Job

Create a dedicated job for storage cleanup:

```ruby
# app/jobs/storage_cleanup_job.rb
class StorageCleanupJob < ApplicationJob
  queue_as :default
  
  def perform
    # Find unattached blobs older than 2 days and schedule them for deletion
    count = ActiveStorage::Blob.unattached
              .where("active_storage_blobs.created_at <= ?", 2.days.ago)
              .count
    
    # Only log if we found something to clean up
    if count > 0
      Rails.logger.info "StorageCleanupJob: Found #{count} unattached blobs to clean up"
    end
    
    # Process in batches to avoid memory issues
    ActiveStorage::Blob.unattached
      .where("active_storage_blobs.created_at <= ?", 2.days.ago)
      .find_each(&:purge_later)
  end
  
  # Re-schedule itself to run daily
  after_perform do
    if Rails.env.production? || Rails.env.development?
      self.class.set(wait: 1.day).perform_later
    end
  end
end
```

### 4. Schedule Initial Job

Create an initializer to schedule the first job when the app starts:

```ruby
# config/initializers/storage_cleanup_scheduler.rb
Rails.application.config.after_initialize do
  # Skip in test environment
  unless Rails.env.test?
    # Schedule the first run for 2:00 AM
    run_at = Time.now.midnight + 2.hours
    run_at += 1.day if run_at < Time.now
    
    StorageCleanupJob.set(wait_until: run_at).perform_later
    
    Rails.logger.info "Scheduled initial StorageCleanupJob for #{run_at}"
  end
end
```

### 5. Write Tests

Create a test for the job:

```ruby
# spec/jobs/storage_cleanup_job_spec.rb
require "rails_helper"

describe StorageCleanupJob do
  it "purges unattached blobs older than 2 days" do
    # Create test data using fixtures
    file_path = Rails.root.join("spec/fixtures/files/test_image.jpg")
    file_data = File.read(file_path)
    checksum = Digest::MD5.base64digest(file_data)
    
    # Create an unattached blob that's older than 2 days
    old_blob = ActiveStorage::Blob.create!(
      key: SecureRandom.uuid,
      filename: "old_test.jpg",
      content_type: "image/jpeg",
      metadata: {},
      service_name: "test",
      byte_size: file_data.bytesize,
      checksum: checksum
    )
    old_blob.update_column(:created_at, 3.days.ago)
    
    # Create a recent unattached blob (less than 2 days old)
    recent_blob = ActiveStorage::Blob.create!(
      key: SecureRandom.uuid,
      filename: "recent_test.jpg",
      content_type: "image/jpeg",
      metadata: {},
      service_name: "test",
      byte_size: file_data.bytesize,
      checksum: checksum
    )
    recent_blob.update_column(:created_at, 1.day.ago)
    
    # Create an attached blob (older than 2 days)
    user = User.create!(email: "test@example.com", password: "password123", admin: false)
    inspection = user.inspections.create!(
      inspector: "Test Inspector",
      serial: "SN12345",
      description: "Test Equipment",
      location: "Test Location",
      equipment_class: 1,
      earth_ohms: 0.1,
      insulation_mohms: 500,
      leakage: 0.2,
      fuse_rating: 13
    )
    
    # Use fixture file for the attachment
    inspection.image.attach(
      io: File.open(file_path),
      filename: "attached_test.jpg",
      content_type: "image/jpeg"
    )
    attached_blob = inspection.image.blob
    attached_blob.update_column(:created_at, 3.days.ago)
    
    # Verify the initial state
    old_blob_query = ActiveStorage::Blob.unattached.where("active_storage_blobs.created_at <= ?", 2.days.ago)
    expect(old_blob_query.count).to eq(1)
    expect(old_blob_query.first.id).to eq(old_blob.id)
    
    # Expect purge_later to be called on the old blob only
    expect_any_instance_of(ActiveStorage::Blob).to receive(:purge_later).once
    
    # Perform the job
    StorageCleanupJob.new.perform
  end
  
  it "schedules itself to run again" do
    # We only want to test that the job reschedules itself
    job = StorageCleanupJob.new
    
    # Stub the actual cleanup to avoid side effects
    allow(ActiveStorage::Blob).to receive_message_chain(:unattached, :where, :find_each)
    
    # Expect the job to schedule itself to run tomorrow
    expect(StorageCleanupJob).to receive(:set).with(wait: 1.day).and_return(StorageCleanupJob)
    expect(StorageCleanupJob).to receive(:perform_later)
    
    # Run the after_perform callback
    job.perform
  end
end
```

### 6. Update Dockerfile

Remove cron-related configurations:

1. Remove cron from installed packages
2. Remove the setup-cron script
3. Remove the cron setup from docker-entrypoint

## Advantages Over Cron Approach

1. **Self-contained**: Job scheduling happens entirely within the Rails application
2. **No external dependencies**: No need for cron in the container
3. **Better visibility**: Jobs can be monitored through Solid Queue's UI
4. **Reliability**: Solid Queue provides monitoring, retries and error handling
5. **Development parity**: Works the same in development and production
6. **Simplified deployment**: No need to configure cron in different environments

## Implementation Steps

1. Add ActiveJob and Solid Queue to the application
2. Create the StorageCleanupJob
3. Create the scheduler initializer
4. Remove cron-related Docker configuration
5. Write tests for the job
6. Deploy the changes

## Future Considerations

1. Add a web UI for monitoring jobs (e.g., Solid Queue UI)
2. Consider additional scheduled tasks that could use ActiveJob
3. Monitor job performance and adjust scheduling as needed