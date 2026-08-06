#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

repo_root = File.expand_path("..", __dir__)
action = YAML.safe_load(File.read(File.join(repo_root, "action.yml")), aliases: false)
entrypoint = File.read(File.join(repo_root, "entrypoint.sh"))

errors = []
inputs = action.fetch("inputs", {})
consumed_inputs = entrypoint.scan(/\$INPUT_([A-Z0-9_]+)/).flatten.uniq.sort
declared_inputs = inputs.keys.sort

(consumed_inputs - declared_inputs).each do |input|
  errors << "entrypoint.sh consumes INPUT_#{input}, but action.yml does not declare #{input}"
end

inputs.each do |name, metadata|
  errors << "#{name} must have a non-empty description" if metadata["description"].to_s.strip.empty?
  errors << "#{name}.required must be a boolean" unless [true, false].include?(metadata["required"])
  errors << "#{name}.default must be a string" if metadata.key?("default") && !metadata["default"].is_a?(String)
end

status_checks = inputs["BRANCH_PROTECTION_REQUIRED_STATUS_CHECKS"]
if status_checks.nil?
  errors << "BRANCH_PROTECTION_REQUIRED_STATUS_CHECKS must be declared"
elsif status_checks["default"] != "false"
  errors << "BRANCH_PROTECTION_REQUIRED_STATUS_CHECKS.default must be the string false"
end

errors << "TOKEN must remain required" unless inputs.dig("TOKEN", "required") == true
errors << "runs.using must be docker" unless action.dig("runs", "using") == "docker"
errors << "runs.image must reference Dockerfile" unless action.dig("runs", "image") == "Dockerfile"

abort errors.join("\n") unless errors.empty?

puts "PASS: #{declared_inputs.length} action inputs declared"
puts "PASS: all #{consumed_inputs.length} consumed INPUT_* variables have metadata"
puts "PASS: Docker action metadata is valid"
