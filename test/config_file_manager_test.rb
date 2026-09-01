# frozen_string_literal: true

require 'test_helper'

class ConfigFileManagerTest < ::Minitest::Test
  CONFIG_DIR_PATH = ::File.expand_path('config', __dir__)

  context 'files' do
    context '.example' do
      should 'list all files' do
        loader = ConfigFileManager.new(CONFIG_DIR_PATH)
        want = to_absolute_paths(
          'config/dummy1.yml',
          'config/nest1/nest2/harambe.yml',
          'config/nest1/mars.yml',
          'config/nest1/dummy2.yml',
          'config/bar.yml',
          'config/foo.yml',
          'config/text_with_erb.txt',
        )
        got = loader.files.sort
        assert_equal want, got
      end

      should 'list all files up to depth 1' do
        loader = ConfigFileManager.new(CONFIG_DIR_PATH, max_dir_depth: 1)
        want = to_absolute_paths(
          'config/dummy1.yml',
          'config/nest1/mars.yml',
          'config/nest1/dummy2.yml',
          'config/bar.yml',
          'config/foo.yml',
          'config/text_with_erb.txt',
        )
        got = loader.files.sort
        assert_equal want, got
      end

      should 'list all files up to depth 0' do
        loader = ConfigFileManager.new(CONFIG_DIR_PATH, max_dir_depth: 0)
        want = to_absolute_paths(
          'config/dummy1.yml',
          'config/bar.yml',
          'config/foo.yml',
          'config/text_with_erb.txt',
        )
        got = loader.files.sort
        assert_equal want, got
      end
    end

    context '.alt' do
      should 'list all files' do
        loader = ConfigFileManager.new(CONFIG_DIR_PATH, example_extension: '.alt')
        want = to_absolute_paths(
          'config/nest1/venus.yml',
          'config/nest1/nest2/kvatch.yml',
          'config/nest1/dummy2-alt.yml',
          'config/morrowind.yml',
          'config/dummy1-alt.yml',
        )
        got = loader.files.sort
        assert_equal want, got
      end

      should 'list all files by overriding the default' do
        loader = ConfigFileManager.new(CONFIG_DIR_PATH, example_extension: '.example')
        want = to_absolute_paths(
          'config/nest1/venus.yml',
          'config/nest1/nest2/kvatch.yml',
          'config/nest1/dummy2-alt.yml',
          'config/morrowind.yml',
          'config/dummy1-alt.yml',
        )
        got = loader.files(example_extension: '.alt').sort
        assert_equal want, got
      end

      should 'list all files up to depth 1' do
        loader = ConfigFileManager.new(CONFIG_DIR_PATH, max_dir_depth: 1, example_extension: '.alt')
        want = to_absolute_paths(
          'config/nest1/venus.yml',
          'config/nest1/dummy2-alt.yml',
          'config/morrowind.yml',
          'config/dummy1-alt.yml',
        )
        got = loader.files.sort
        assert_equal want, got
      end

      should 'list all files up to depth 0' do
        loader = ConfigFileManager.new(CONFIG_DIR_PATH, max_dir_depth: 0, example_extension: '.alt')
        want = to_absolute_paths(
          'config/morrowind.yml',
          'config/dummy1-alt.yml',
        )
        got = loader.files.sort
        assert_equal want, got
      end
    end

  end

  context 'dirs' do
    should 'list all with .example' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      want = to_absolute_paths(
        'config/nest1/nest2/nest3',
        'config/test_folder',
      )
      got = loader.dirs.sort
      assert_equal want, got
    end

    should 'list all dirs up to depth 0' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH, max_dir_depth: 0)
      want = to_absolute_paths(
        'config/test_folder',
      )
      got = loader.dirs.sort
      assert_equal want, got
    end

    should 'list all with .alt' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH, example_extension: '.alt')
      want = to_absolute_paths(
        'config/alt_folder',
      )
      got = loader.dirs.sort
      assert_equal want, got
    end

    should 'list all with .alt by overriding the default' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH, example_extension: '.example')
      want = to_absolute_paths(
        'config/alt_folder',
      )
      got = loader.dirs(example_extension: '.alt').sort
      assert_equal want, got
    end
  end

  context 'load_yaml' do
    should 'load development and process ERB' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      value = loader.load_yaml('foo.yml', env: 'development')
      assert_equal 'development', value[:foo]
      assert_equal 7, value[:erb]
    end

    should 'load production' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      value = loader.load_yaml('bar.yml', env: 'production')
      assert_equal 'production', value[:bar]
    end

    should 'load and not symbolize' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      value = loader.load_yaml('bar.yml', env: 'production', symbolize: false)
      assert_equal 'production', value['bar']
    end

    should 'load from a nested directory' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      value = loader.load_yaml('nest1/nest2/harambe.yml', env: 'test')
      assert_equal 'RIP (test)', value[:harambe]
    end

  end

  context 'load_json' do
    should 'load with env as string and process ERB' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      value = loader.load_json('śledź.json', env: 'production')
      assert_equal 'production', value[:type]
    end
    should 'load and process ERB' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      value = loader.load_json('jaj_son.json', env: nil)
      assert_equal 'development', value[:foo]
      assert_equal 7, value[:erb]
    end

    should 'load and not symbolize' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      value = loader.load_json('jaj_son.json', env: nil, symbolize: false)
      assert_equal 'development', value['foo']
      assert_equal 7, value['erb']
    end

    should 'load from a nested directory' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      value = loader.load_json('nest1/nest2/2pac.json', env: nil)
      assert_equal 'Changes', value[:'2pac'].first[:name]
      assert_equal 'Juicy', value[:biggie].last[:name]
    end
  end

  context 'load_erb' do
    should 'load and process ERB' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      value = loader.load_erb('text_with_erb.txt')
      assert_equal <<~ERB, value
        ERB: 6
      ERB
    end

    should 'load YAML and process ERB' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      value = loader.load_erb('foo.yml')
      assert_equal <<~ERB, value
        development:
          foo: development
          erb: 7

        test:
          foo: test

        production:
          foo: production
      ERB
    end

  end

  context 'load_file' do
    should 'load and not process ERB' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      value = loader.load_file('text_with_erb.txt')
      assert_equal <<~ERB, value
        ERB: <%= 1 + 5 %>
      ERB
    end

    should 'load YAML and not process ERB' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      value = loader.load_file('foo.yml')
      assert_equal <<~ERB, value
        development:
          foo: development
          erb: <%= 2 + 5 %>

        test:
          foo: test

        production:
          foo: production
      ERB
    end
  end

  context 'file_exist?' do
    should 'return true for an existing file' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      assert loader.file_exist?('foo.yml')
    end

    should 'return true for an existing nested file' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      assert loader.file_exist?('nest1/nest2/harambe.yml')
    end

    should 'return false for nonexistent file' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      assert !loader.file_exist?('pupa.yml')
    end
  end

  context 'dir_exist?' do
    should 'return true for an existing dir' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      assert loader.dir_exist?('nest1')
    end

    should 'return true for an existing nested dir' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      assert loader.dir_exist?('nest1/nest2')
    end

    should 'return false for nonexistent dir' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      assert !loader.dir_exist?('siemano')
    end

    should 'return false for an existing file' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      assert !loader.dir_exist?('foo.yml')
    end
  end

  context 'to_relative_path' do
    should 'convert' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      assert_equal 'foo/bar.yml', loader.to_relative_path("#{CONFIG_DIR_PATH}/foo/bar.yml")
    end
  end

  context 'absolute_path' do
    should 'convert' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      assert_equal "#{CONFIG_DIR_PATH}/foo/bar.yml", loader.to_absolute_path('foo/bar.yml')
    end
  end

  context 'create_missing_files' do
    should 'create all missing files for .example' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      assert !loader.file_exist?('dummy1.yml')
      assert !loader.file_exist?('dummy1-alt.yml')
      assert !loader.file_exist?('nest1/dummy2.yml')
      assert !loader.file_exist?('nest1/dummy2-alt.yml')

      loader.create_missing_files

      assert loader.file_exist?('dummy1.yml')
      assert_equal loader.load_file('dummy1.yml'), loader.load_file('dummy1.yml.example')

      assert !loader.file_exist?('dummy1-alt.yml')

      assert loader.file_exist?('nest1/dummy2.yml')
      assert_equal loader.load_file('nest1/dummy2.yml'), loader.load_file('nest1/dummy2.yml.example')

      assert !loader.file_exist?('nest1/dummy2-alt.yml')

      loader.delete_file('dummy1.yml')
      loader.delete_file('nest1/dummy2.yml')

      assert !loader.file_exist?('dummy1.yml')
      assert !loader.file_exist?('dummy1-alt.yml')
      assert !loader.file_exist?('nest1/dummy2.yml')
      assert !loader.file_exist?('nest1/dummy2-alt.yml')
    end

    should 'create all missing files for .alt' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH, example_extension: '.alt')
      assert !loader.file_exist?('dummy1.yml')
      assert !loader.file_exist?('dummy1-alt.yml')
      assert !loader.file_exist?('nest1/dummy2.yml')
      assert !loader.file_exist?('nest1/dummy2-alt.yml')

      loader.create_missing_files

      assert !loader.file_exist?('dummy1.yml')

      assert loader.file_exist?('dummy1-alt.yml')
      assert_equal loader.load_file('dummy1-alt.yml'), loader.load_file('dummy1-alt.yml.alt')

      assert !loader.file_exist?('nest1/dummy2.yml')

      assert loader.file_exist?('nest1/dummy2-alt.yml')
      assert_equal loader.load_file('nest1/dummy2-alt.yml'), loader.load_file('nest1/dummy2-alt.yml.alt')

      loader.delete_file('dummy1-alt.yml')
      loader.delete_file('nest1/dummy2-alt.yml')

      assert !loader.file_exist?('dummy1.yml')
      assert !loader.file_exist?('dummy1-alt.yml')
      assert !loader.file_exist?('nest1/dummy2.yml')
      assert !loader.file_exist?('nest1/dummy2-alt.yml')
    end

    should 'create all missing files for .alt by overriding the default' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH, example_extension: '.example')
      assert !loader.file_exist?('dummy1.yml')
      assert !loader.file_exist?('dummy1-alt.yml')
      assert !loader.file_exist?('nest1/dummy2.yml')
      assert !loader.file_exist?('nest1/dummy2-alt.yml')

      loader.create_missing_files(example_extension: '.alt')

      assert !loader.file_exist?('dummy1.yml')
      assert loader.file_exist?('dummy1-alt.yml')
      assert !loader.file_exist?('nest1/dummy2.yml')
      assert loader.file_exist?('nest1/dummy2-alt.yml')

      loader.delete_file('dummy1-alt.yml')
      loader.delete_file('nest1/dummy2-alt.yml')

      assert !loader.file_exist?('dummy1.yml')
      assert !loader.file_exist?('dummy1-alt.yml')
      assert !loader.file_exist?('nest1/dummy2.yml')
      assert !loader.file_exist?('nest1/dummy2-alt.yml')
    end
  end

  context 'create_missing_dirs' do
    should 'create all missing dirs for .example' do
      loader = ConfigFileManager.new(CONFIG_DIR_PATH)
      assert !loader.dir_exist?('test_folder')
      assert !loader.file_exist?('test_folder/some_awesome_file')
      assert !loader.dir_exist?('test_folder/test_subfolder')
      assert !loader.file_exist?('test_folder/test_subfolder/another_file')

      loader.create_missing_dirs

      assert loader.dir_exist?('test_folder')

      assert loader.file_exist?('test_folder/some_awesome_file')
      assert_equal loader.load_file('test_folder/some_awesome_file'),
                   loader.load_file('test_folder.example/some_awesome_file')

      assert loader.dir_exist?('test_folder/test_subfolder')

      assert loader.file_exist?('test_folder/test_subfolder/another_file')
      assert_equal loader.load_file('test_folder/test_subfolder/another_file'),
                   loader.load_file('test_folder.example/test_subfolder/another_file')

      loader.delete_dir('test_folder')

      assert !loader.dir_exist?('test_folder')
      assert !loader.file_exist?('test_folder/some_awesome_file')
      assert !loader.dir_exist?('test_folder/test_subfolder')
      assert !loader.file_exist?('test_folder/test_subfolder/another_file')
    end
  end

  private

  # @param paths [Array<String>]
  # @return [Array<String>]
  def to_absolute_paths(*paths)
    paths.map { |p| ::File.expand_path(p, __dir__) }
         .sort
  end

end
