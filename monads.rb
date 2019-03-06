#!/usr/bin/env ruby

require 'bundler/setup'

Bundler.require(:default)

class Adverb
  attr_accessor :value

  def self.define(&block)
    Class.new(self) { define_method(:and_then, &block) }
  end

  def self.from_value(value)
    value.is_a?(Adverb) ? value.then { |x| from_value(x) } : new(value)
  end

  def initialize(value)
    @value = value
  end

  def and_then
    yield value
  end

  def then(&block)
    self.class.new(and_then(&block))
  end

  def tap(*args, &block)
    method_missing(:tap, *args, &block)
  end

  [:nil?, :===, :=~, :!~, :eql?, :hash, :<=>, :frozen?, :to_s, :tap, :display, :method,
   :itself, :taint, :tainted?, :untaint, :untrust, :untrusted?, :trust, :freeze,
   :to_enum, :enum_for, :==, :equal?, :!, :!=, :instance_eval, :instance_exec].each do |method|
    define_method(method) do |*args, &block|
      method_missing(method, *args, &block)
    end
  end

  def method_missing(m, *args, &block)
    self.and_then { |instance| instance.public_send(m, *args, &block) }
  end
end

Dangerously = Adverb.define do |&block|
  block.call(value).tap{|result| raise "nil!" if result.nil? }
end

Optional = Adverb.define do |&block|
  value.nil? ? nil : block.call(value)
end

Mapy = Adverb.define do |&block|
  value.map{ |v| block.call(v) }
end

Many = Adverb.define do |&block|
  value.flat_map{ |v| block.call(v) }
end

Safy = Adverb.define do |&block|
  block.call(value) rescue value
end

Object.class_eval do
  def safy
    Safy.from_value(self)
  end

  def optionaly
    Optional.from_value(self)
  end

  def mapy
    Mapy.from_value(self)
  end

  def many;
    Many.from_value(self)
  end

  def dangerously
    Dangerously.from_value(self)
  end

  def normally
    Adverb.from_value(self)
  end

  def then
    yield self
  end

  def and_then
    self
  end
end

class Hello
  def hello
    p "hello"
  end

  def s
    self
  end

    def null
      nil
  end
end

require 'colorize'

File.read(__FILE__).split("\nexit # __END__\n")[1].split("\n").each_with_index do |line, n|
  next puts line.light_black if line =~ /(^\s*$|^#)/
  puts "irb(main)".green +  ":" + "#{"%03d" % n}:0>".yellow +  " #{line}"
  puts "=>".red + " #{eval(line).inspect}"
end

exit # __END__
# Optionaly
Hello.new.optionaly.s.optionaly.hello
nil.optionaly.s.optionaly.hello
1.optionaly.tap { |x| puts x }
nil.optionaly.tap { |x| puts x }

# Safy
Hello.new.safy.j.hello
nil.safy.j.safy.hello
nil.safy.j.safy.hello
3.safy * 2
nil.safy * 2

Hello.new.safy.tap { |value| raise "s" }

# Mapy
[1, 2, 3].mapy + 1
[1, 2, 3].mapy * 2

[[1, 2, 3]].mapy * 2
[[1, 2, 3], [4, 5, 6]].mapy.mapy * 2

['Hello', 'world'].mapy.center(9).mapy.prepend('[').mapy.concat(']').join('-')

['many values', 'and others'].mapy.tap { |x| puts x }
['many values', 'and others'].mapy.tap(&method(:puts))

['many values', 'and others'].mapy.split(/\s+/)

# Many
['many values', 'and others'].many.split(/\s+/)

# Dangerously
3.dangerously + 2

nil.dangerously.itself rescue 'Raised error'

Hello.new.dangerously.null rescue 'Raised error'

r = 'hello'; r.dangerously.delete!('z') rescue 'Raised error'
r = 'hello'; r.dangerously.delete!('h')

# Chain!
[1, 2, 3, nil].mapy.safy * 3

[1, 2, 3, nil].mapy.and_then { |x| x.safy * 3 }

[[1,2,3],[4,5,6]].many.mapy * 2

[[1,2,3],[4,5,6]].mapy.many * 2

[[[1],[2],[3]],[[4],[5],[6]]].many.mapy * 2

[[[1],[2],[3]],[[4],[5],[6]]].mapy.many * 2
