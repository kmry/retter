# coding: utf-8

class Retter::Pages::Entry
  include Retter::Page

  attr_reader :entry

  def initialize(entry)
    super()
    @path_prefix = '../'
    @entry       = entry
    @title       = "#{entry.date.strftime('%Y/%m/%d')} - #{config.title}"
  end

  def pathname
    config.entry_file(entry.date)
  end

  def part_layout_pathname
    config.entry_layout_file
  end

  def print
    part = Haml::Engine.new(part_layout_pathname.read, ugly: true).render(view_scope, entry: entry)

    print_with_layout part
  end
end