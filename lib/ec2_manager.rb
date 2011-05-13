#!/usr/bin/ruby
require 'rubygems'
require 'right_aws'
require 'date'

class Ec2Manager
  attr :instance_ids

  EXPIRATION_DATE = 3
  GENERATION = 3

  def initialize access_key, secret_key, instance_ids, params = nil
    @instance_ids = instance_ids
    @ec2 = RightAws::Ec2.new(access_key, secret_key, params)
  end

  def create_snapshots
    @instance_ids.each do |instance_id|
      volumes_by_instance_id(instance_id).each do |vol|
        p @ec2.create_snapshot(vol[:aws_id])
      end
    end
  end

  def delete_snapshots
    @instance_ids.each do |instance_id|
      volumes_by_instance_id(instance_id).each do |vol|
        deleting_snapshots = snapshots_by_volume_id(vol[:aws_id])[GENERATION, 100]
        return if deleting_snapshots.nil?

        deleting_snapshots.each do |snap|
          p @ec2.delete_snapshot(snap[:aws_id])
        end
      end
    end
  end

  private

  def volumes_by_instance_id instance_id
    @volumes ||= @ec2.describe_volumes
    @volumes.select { |vol|
      instance_id == vol[:aws_instance_id]
    }
  end

  def snapshots_by_volume_id volume_id
    @snapshots ||= @ec2.describe_snapshots
    snapshots = @snapshots.select { |snap|
        volume_id == snap[:aws_volume_id]
    }
    snapshots ? snapshots.sort{ |a, b| -(a[:aws_started_at] <=> b[:aws_started_at]) } : nil
  end

  def parse_date date_string
    matched, year, month, day = date_string.match(/^(\d{4})-(\d{2})-(\d{2})T/).to_a
    if year.nil? or month.nil? or day.nil?
      return false
    end

    Date.new(year.to_i, month.to_i, day.to_i)
  end
end

#@manager = Ec2Manager.new(access_key, secret_key, instance_ids)
#@manager.create_snapshots
#@manager.delete_snapshots
