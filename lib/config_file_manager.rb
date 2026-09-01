# typed: true
# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'yaml'
require 'erb'
require 'pastel'

require_relative 'config_file_manager/version'

# Class that let's you manage your configuration files.
class ConfigFileManager
  COLORS = ::Pastel.new

  # Absolute path to the main directory that contains all config files (and subdirectories).
  #
  #: String
  attr_reader :config_dir

  # Maximum depth of nested directories containing config files.
  #
  #: Integer
  attr_reader :max_dir_depth

  # Current environment name. Used to load the correct section of YAML files.
  #
  #: String
  attr_reader :env

  # Extension of the example/dummy version of a config file.
  # eg. `.example`, `.dummy`
  #
  #: String
  attr_reader :example_extension

  # @param config_dir Absolute path to the root config directory
  # @param max_dir_depth Maximum depth of nested directories containing config files.
  # @param env Current environment name
  #
  #: (String config_dir, ?example_extension: String, ?max_dir_depth: Integer, ?env: String) -> void
  def initialize(config_dir, example_extension: '.example', max_dir_depth: 5, env: 'development')
    @config_dir = config_dir
    @example_extension = example_extension
    @max_dir_depth = max_dir_depth
    @env = env
  end

  # Recursively search for files under the `config_dir` directory
  # with the specified extension (eg. `.example`).
  # Returns an array of absolute paths to the found files
  # with the specified extension stripped away.
  #
  # @param example_extension File extension of example files
  #
  #: (?example_extension: String, ?result: Array[String], ?depth: Integer, ?dir_path: String) -> Array[String]
  def files(example_extension: @example_extension, result: [], depth: 0, dir_path: @config_dir)
    return result if depth > @max_dir_depth

    ::Dir.each_child(dir_path) do |path|
      abs_path = ::File.join(dir_path, path)

      if ::File.directory?(abs_path)
        # if the entry is a directory, scan it recursively
        # this essentially performs a depth limited search (DFS with a depth limit)
        next files(
          example_extension: example_extension,
          result:            result,
          depth:             depth + 1,
          dir_path:          abs_path,
        )
      end

      next unless ::File.file?(abs_path) && path.end_with?(example_extension)

      result << abs_path.delete_suffix(example_extension)
    end

    result
  end

  # Absolute paths to missing config files.
  #
  #: (?example_extension: String) -> Array[String]
  def missing_files(example_extension: @example_extension)
    files(example_extension: example_extension).reject do |file|
      ::File.exist?(file)
    end
  end

  # Create the missing config files based on their dummy/example versions.
  #
  #: (?example_extension: String, ?print: bool) -> void
  def create_missing_files(example_extension: @example_extension, print: false)
    puts COLORS.blue('== Copying missing config files ==') if print
    files(example_extension: example_extension).each do |file|
      create_missing_file("#{file}#{example_extension}", file, print: print)
    end
  end

  # Recursively search for directories under the `config_dir` directory
  # with the specified extension (eg. `.example`).
  # Returns an array of absolute paths to the found directories
  # with the specified extension stripped away.
  #
  # @param example_extension ending of example directories
  #
  #: (?example_extension: String, ?result: Array[String], ?depth: Integer, ?dir_path: String) -> Array[String]
  def dirs(example_extension: @example_extension, result: [], depth: 0, root_dir_path: @config_dir)
    return result if depth > @max_dir_depth

    ::Dir.each_child(root_dir_path) do |path|
      abs_path = ::File.join(root_dir_path, path)

      next unless ::File.directory?(abs_path)

      # if the entry is a directory with the example extension, add it to the result array
      if path.end_with?(example_extension)
        result << abs_path.delete_suffix(example_extension)
        next
      end

      # if the entry is a directory without the example extension, scan it recursively
      # this essentially performs a depth limited search (DFS with a depth limit)
      next dirs(
        example_extension: example_extension,
        result:            result,
        depth:             depth + 1,
        root_dir_path:     abs_path,
      )
    end

    result
  end

  # Absolute paths to missing config directories.
  #
  #: (?example_extension: String) -> Array[String]
  def missing_dirs(example_extension: @example_extension)
    dirs(example_extension: example_extension).reject do |file|
      ::Dir.exist?(file)
    end
  end

  # Create the missing config directories based on their dummy/example versions.
  #
  #: (?example_extension: String, ?print: bool) -> void
  def create_missing_dirs(example_extension: @example_extension, print: false)
    puts COLORS.blue('== Copying missing config directories ==') if print
    dirs(example_extension: example_extension).each do |dir|
      create_missing_dir("#{dir}#{example_extension}", dir, print: print)
    end
  end

  # Converts a collection of absolute paths to an array of
  # relative paths.
  #
  #: (Array[String] absolute_paths) -> Array[String]
  def to_relative_paths(absolute_paths)
    absolute_paths.map do |path|
      to_relative_path(path)
    end
  end

  # Converts an absolute path to a relative path
  #
  #: (String absolute_path) -> String
  def to_relative_path(absolute_path)
    absolute_path.delete_prefix("#{@config_dir}/")
  end

  # Converts a collection of relative paths to an array of
  # absolute paths.
  #
  #: (Array[String] relative_paths) -> Array[String]
  def to_absolute_paths(relative_paths)
    relative_paths.map do |path|
      to_absolute_path(path)
    end
  end

  # Converts a relative path to an absolute path.
  #
  #: (String relative_path) -> String
  def to_absolute_path(relative_path)
    "#{@config_dir}/#{relative_path}"
  end

  # @param symbolize Whether the keys should be converted to Ruby symbols
  #
  #: (*String file_name, ?env: String?, ?symbolize: bool) -> untyped
  def load_yaml(*file_name, env: @env, symbolize: true)
    env = env.to_sym if env && symbolize
    parsed = ruby_load_yaml(load_erb(*file_name), symbolize_names: symbolize)
    return parsed unless env

    parsed[env]
  end

  # @param symbolize Whether the keys should be converted to Ruby symbols
  #
  #: (*String file_name, ?env: String?, ?symbolize: bool) -> untyped
  def load_json(*file_name, env: @env, symbolize: true)
    env = env.to_sym if env && symbolize
    parsed = ::JSON.parse(load_erb(*file_name), symbolize_names: symbolize)
    return parsed unless env

    parsed[env]
  end

  #: (*String file_name) -> void
  def delete_file(*file_name)
    ::File.delete(file_path(*file_name))
  end

  #: (*String dir_name) -> void
  def delete_dir(*dir_name)
    ::FileUtils.rm_r(file_path(*dir_name))
  end

  #: (*String file_name) -> String
  def load_erb(*file_name)
    ::ERB.new(load_file(*file_name)).result
  end

  # @raise [SystemCallError]
  #
  #: (*String file_name) -> String
  def load_file(*file_name)
    ::File.read file_path(*file_name)
  end

  #: (*String file_name) -> bool
  def file_exist?(*file_name)
    ::File.exist? file_path(*file_name)
  end

  #: (*String dir_name) -> bool
  def dir_exist?(*dir_name)
    ::Dir.exist? file_path(*dir_name)
  end

  #: (*String file_name) -> String
  def file_path(*file_name)
    *path, name = file_name
    ::File.join(@config_dir, *path, name)
  end

  private

  if ::Psych::VERSION >= '4'
    # Load YAML content using the Psych 4+ API.
    #
    #: (String content, **untyped options) -> untyped
    def ruby_load_yaml(content, **options)
      ::YAML.load(content, aliases: true, **options)
    end
  else
    # Load YAML content using the pre Psych 4 API.
    #
    #: (String content, **untyped options) -> untyped
    def ruby_load_yaml(content, **options)
      ::YAML.load(content, **options)
    end
  end

  #: (String original_name, String new_name, ?print: bool) -> bool
  def create_missing_file(original_name, new_name, print: false)
    return false if ::File.exist?(new_name)

    ::FileUtils.cp original_name, new_name
    if print
      copy = COLORS.green.bold 'copy'.rjust(12, ' ')
      puts "#{copy}  #{original_name}"
    end

    true
  end

  #: (String original_name, String new_name, ?print: bool) -> bool
  def create_missing_dir(original_name, new_name, print: false)
    return false if ::Dir.exist?(new_name)

    ::FileUtils.cp_r original_name, new_name
    if print
      copy = COLORS.green.bold 'copy'.rjust(12, ' ')
      puts "#{copy}  #{original_name}"
    end

    true
  end
end
