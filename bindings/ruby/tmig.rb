require 'fiddle'
here = File.dirname(__FILE__)
candidates = [File.join(here, 'libffi.dylib'), File.join(here, 'libffi.so')]
path = candidates.find { |p| File.exist?(p) } or raise "libffi not built"
lib = Fiddle.dlopen(path)
@id_of = Fiddle::Function.new(lib['tmig_id_of'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T], Fiddle::TYPE_VOIDP)
@free  = Fiddle::Function.new(lib['tmig_free'],  [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)

module Tmig
  def self.id_of(b)
    ptr = @id_of.call(b, b.bytesize)
    return "" if ptr.nil? || ptr.zero?
    s = Fiddle::Pointer.new(ptr).to_s
    @free.call(ptr)
    s
  end
end
