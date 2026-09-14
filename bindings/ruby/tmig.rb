require 'fiddle'
require 'fiddle/import'

module Tmig
  here = File.dirname(__FILE__)
  candidates = [File.join(here, 'libffi.dylib'), File.join(here, 'libffi.so')]
  path = candidates.find { |p| File.exist?(p) } or raise "libffi not built in #{here}"
  LIB = Fiddle.dlopen(path)
  ID_OF = Fiddle::Function.new(LIB['tmig_id_of'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T], Fiddle::TYPE_VOIDP)
  FREE  = Fiddle::Function.new(LIB['tmig_free'],  [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)

  def self.id_of(b)
    s = b.to_s
    ptr = ID_OF.call(s, s.bytesize)
    return "" if ptr.nil? || ptr.to_i.zero?
    out = Fiddle::Pointer.new(ptr).to_s
    FREE.call(ptr)
    out
  end
end
