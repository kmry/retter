# coding: utf-8

require 'active_support/cache'
require 'forwardable'
require 'fileutils'

module Retter
  class EnvError < RetterError; end

  class Config
    extend Forwardable

    def_delegators Entries,      :retters_dir, :wip_file, :markup, :cache
    def_delegators Markdown,     :renderer
    def_delegators Binder,       :allow_binding
    def_delegators Page,         :layouts_dir, :entries_dir
    def_delegators Retter::Site, :title, :description, :url, :author
    def_delegator  Retter::Site, :home, :retter_home

    def initialize(env)
      @env             = env
      @after_callbacks = {}
      @attributes      = {}

      detect_retter_home
      environments_required

      load_defaults
      load_retterfile
    rescue EnvError => e
      $stderr.puts e.message, Command.usage

      exit 1
    end

    def after_callback(name, sym = nil, &block)
      if callback = sym || block
        @after_callbacks[name] = callback
      else
        @after_callbacks[name]
      end
    end

    alias_method :after, :after_callback

    [ # base
      :editor, :shell,
      # extra
      :disqus_shortname
    ].each do |att|
      class_eval <<-EOM
        def #{att}(val = nil)
          val ? @attributes[:#{att}] = val : @attributes[:#{att}]
        end
      EOM
    end

    private

    def detect_retter_home
      @env['RETTER_HOME'] = Dir.pwd if File.exist? 'Retterfile'
    end

    def load_retterfile
      retterfile = retter_home.join('Retterfile')

      instance_eval retterfile.read, retterfile.to_path if retterfile.exist?
    end

    def environments_required
      unless @env.values_at('EDITOR', 'RETTER_HOME').all?
        raise EnvError, 'Set $RETTER_HOME and $EDITOR, first.'
      end
    end

    def load_defaults
      retter_home Pathname.new(@env['RETTER_HOME'])

      editor @env['EDITOR']
      shell  @env['SHELL']
      url    'http://example.com'

      renderer    Retter::Markdown::CodeRayRenderer
      retters_dir retter_home.join('retters/')
      wip_file    retters_dir.join('today.md')

      layouts_dir retter_home.join('layouts/')
      entries_dir retter_home.join('entries/')

      cache_dir = retter_home.join('tmp/cache')
      cache ActiveSupport::Cache::FileStore.new(cache_dir.to_path)

      FileUtils.mkdir_p cache_dir.to_path unless cache_dir.directory? # for old versions
    end
  end
end
