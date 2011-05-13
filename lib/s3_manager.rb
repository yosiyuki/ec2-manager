#!/usr/bin/ruby
require 'rubygems'
require 'date'
require 'right_aws'

class S3Manager
  attr :bucket_names

  GENERATION = 3

  def initialize access_key, secret_key, bucket_names
    @bucket_names = bucket_names
    @s3 = RightAws::S3.new(access_key, secret_key)
  end

  def delete
    @bucket_names.map do |bucket_name|
      bucket = @s3.bucket(bucket_name)
      delete_by_bucket(bucket) if bucket
    end
  end

  private

  def delete_by_bucket bucket
    subdirs = sub_dirs(bucket)
    return if subdirs.size <= GENERATION
    subdirs = subdirs[0, subdirs.size - 3]

    subdirs.map do |subdir|
      p "deleting " + [bucket.full_name, subdir].join('/')
      p bucket.delete_folder subdir
    end
  end

  def sub_dirs bucket
    subdirs = []
    bucket.keys.map do |key|
      keys = key.full_name.split('/')
      subdirs << keys [1] unless subdirs.include? keys[1]
    end
    subdirs.sort
  end
end
